<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\GrowthRecord;
use App\Models\Measurement;
use App\Services\GiziService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GiziController extends Controller
{
    use ResolvesApiUser;

    public function __construct(private readonly GiziService $giziService)
    {
    }

    public function hitung(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $validated = $request->validate([
            'child_id' => ['required', 'integer', 'exists:children,id'],
            'tanggal_ukur' => ['required', 'date'],
            'berat_badan' => ['required', 'numeric', 'gt:0', 'max:80'],
            'tinggi_badan' => ['required', 'numeric', 'gt:0', 'min:30', 'max:130'],
            'cara_ukur' => ['required', 'in:standing,lying'],
        ]);

        $child = Child::query()
            ->where('user_id', $user->id)
            ->findOrFail($validated['child_id']);

        $result = $this->giziService->hitung([
            'jenis_kelamin' => $child->jenis_kelamin,
            'tanggal_lahir' => $child->tanggal_lahir->toDateString(),
            'tanggal_ukur' => $validated['tanggal_ukur'],
            'berat_badan' => $validated['berat_badan'],
            'tinggi_badan' => $validated['tinggi_badan'],
            'cara_ukur' => $validated['cara_ukur'],
        ]);

        if (isset($result['error'])) {
            return response()->json($result, 422);
        }

        $measurement = Measurement::query()->create([
            'child_id' => $child->id,
            'berat' => $validated['berat_badan'],
            'tinggi' => $validated['tinggi_badan'],
            'tanggal_ukur' => $validated['tanggal_ukur'],
            'cara_ukur' => $validated['cara_ukur'],
            'umur_bulan' => $result['identitas']['umur_bulan'],
            'z_bbu' => $result['zscore']['bbu'],
            'z_tbu' => $result['zscore']['tbu'],
            'z_bbtb' => $result['zscore']['bbtb'],
            'kategori' => $result['kategori'],
            'status_gabungan' => $result['status_gabungan'],
            'created_at' => now(),
        ]);

        GrowthRecord::query()->create([
            'child_id' => $child->id,
            'tinggi_badan' => $validated['tinggi_badan'],
            'berat_badan' => $validated['berat_badan'],
            'umur_dalam_bulan' => $result['identitas']['umur_bulan'],
            'z_score' => $this->primaryZScore($result['status_gabungan'], $result['zscore']),
            'status_gizi' => $result['status_gabungan'],
            'created_at' => now(),
        ]);

        return response()->json([
            ...$result,
            'measurement' => [
                'id' => $measurement->id,
                'child_id' => $child->id,
                'child_name' => $child->nama_anak ?? $child->nama,
                'tanggal_ukur' => $measurement->tanggal_ukur->toDateString(),
                'cara_ukur' => $measurement->cara_ukur,
            ],
        ]);
    }

    public function riwayat(Request $request, int $childId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $child = Child::query()->where('user_id', $user->id)->findOrFail($childId);

        return response()->json([
            'child' => [
                'id' => $child->id,
                'nama' => $child->nama_anak ?? $child->nama,
                'nama_anak' => $child->nama_anak ?? $child->nama,
                'tanggal_lahir' => $child->tanggal_lahir->toDateString(),
                'jenis_kelamin' => $child->jenis_kelamin,
            ],
            'riwayat' => $child->measurements()
                ->orderByDesc('tanggal_ukur')
                ->orderByDesc('id')
                ->get()
                ->map(fn (Measurement $item) => [
                    'id' => $item->id,
                    'berat' => $item->berat,
                    'tinggi' => $item->tinggi,
                    'tanggal_ukur' => $item->tanggal_ukur->toDateString(),
                    'cara_ukur' => $item->cara_ukur,
                    'umur_bulan' => $item->umur_bulan,
                    'status_gabungan' => $item->status_gabungan,
                    'kategori' => $item->kategori,
                    'z_score' => [
                        'bbu' => $item->z_bbu,
                        'tbu' => $item->z_tbu,
                        'bbtb' => $item->z_bbtb,
                    ],
                ]),
        ]);
    }

    private function primaryZScore(string $status, array $scores): float
    {
        $status = strtolower($status);

        if (str_contains($status, 'stunting') || str_contains($status, 'stunted')) {
            return (float) $scores['tbu'];
        }
        if (str_contains($status, 'wasting') || str_contains($status, 'obesitas') || str_contains($status, 'overweight')) {
            return (float) $scores['bbtb'];
        }

        return (float) $scores['bbu'];
    }
}
