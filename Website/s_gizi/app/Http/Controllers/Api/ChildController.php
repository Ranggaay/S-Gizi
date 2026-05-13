<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use App\Models\Child;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ChildController extends Controller
{
    use ResolvesApiUser;

    public function index(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $children = $user->children()
            ->with([
                'measurements' => fn ($q) => $q
                    ->orderByDesc('tanggal_ukur')
                    ->orderByDesc('id')
                    ->limit(1),
            ])
            ->orderBy('nama')
            ->get()
            ->map(fn (Child $child) => $this->resource($child));

        return response()->json(['data' => $children]);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $validated = $request->validate([
            'nama_anak' => ['required_without:nama', 'string', 'max:120'],
            'nama' => ['required_without:nama_anak', 'string', 'max:120'],
            'tanggal_lahir' => ['required', 'date', 'before_or_equal:today'],
            'jenis_kelamin' => ['required', 'in:L,P'],
        ]);

        $validated['nama_anak'] = $validated['nama_anak'] ?? $validated['nama'];
        $validated['nama'] = $validated['nama'] ?? $validated['nama_anak'];
        $child = $user->children()->create($validated);

        return response()->json(['data' => $this->resource($child)], 201);
    }

    public function update(Request $request, Child $child): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user || $child->user_id !== $user->id) return $this->unauthenticated();

        $validated = $request->validate([
            'nama_anak' => ['sometimes', 'required', 'string', 'max:120'],
            'nama' => ['sometimes', 'required', 'string', 'max:120'],
            'tanggal_lahir' => ['sometimes', 'required', 'date', 'before_or_equal:today'],
            'jenis_kelamin' => ['sometimes', 'required', 'in:L,P'],
        ]);

        if (isset($validated['nama_anak']) && !isset($validated['nama'])) {
            $validated['nama'] = $validated['nama_anak'];
        }
        if (isset($validated['nama']) && !isset($validated['nama_anak'])) {
            $validated['nama_anak'] = $validated['nama'];
        }
        $child->update($validated);

        return response()->json(['data' => $this->resource($child)]);
    }

    public function destroy(Request $request, Child $child): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user || $child->user_id !== $user->id) return $this->unauthenticated();

        $child->delete();

        return response()->json(['message' => 'Data anak berhasil dihapus.']);
    }

    private function resource(Child $child): array
    {
        $latest = $child->measurements->first();

        return [
            'id' => $child->id,
            'nama' => $child->nama_anak ?? $child->nama,
            'nama_anak' => $child->nama_anak ?? $child->nama,
            'tanggal_lahir' => optional($child->tanggal_lahir)->toDateString(),
            'jenis_kelamin' => $child->jenis_kelamin,
            'latest_status' => $latest?->status_gabungan,
            'latest_measurement_at' => $latest?->tanggal_ukur?->toDateString(),
        ];
    }
}
