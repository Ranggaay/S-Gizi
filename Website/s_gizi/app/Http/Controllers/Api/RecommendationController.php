<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\Makanan;
use App\Models\Measurement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    use ResolvesApiUser;

    public function show(Request $request, string $status): JsonResponse
    {
        $user = $this->userFromToken($request);
        $measurement = $this->resolveMeasurement(
            $request,
            $user?->id,
        );
        $resolvedStatus = $measurement?->status_gabungan ?: $status;
        $normalized = $this->normalizeStatus($resolvedStatus);
        $conditions = $normalized['matched_categories'];
        $ageMonths = $measurement?->umur_bulan;

        $menus = Makanan::query()
            ->when(
                $ageMonths !== null,
                fn ($query) => $query
                    ->where('usia_min', '<=', (int) floor((float) $ageMonths))
                    ->where('usia_max', '>=', (int) ceil((float) $ageMonths))
            )
            ->whereIn('kategori_status', $conditions)
            ->orderBy('protein', 'desc')
            ->get()
            ->groupBy('kategori_status');

        $items = collect($conditions)
            ->flatMap(
                fn (string $condition) => $menus
                    ->get($condition, collect())
                    ->take($condition === 'Normal' ? 4 : 6)
            )
            ->unique('id')
            ->take(12)
            ->map(fn (Makanan $makanan) => [
                'menu' => $makanan->nama,
                'kalori' => $makanan->kalori,
                'protein' => $makanan->protein,
                'lemak' => $makanan->lemak,
                'karbohidrat' => $makanan->karbohidrat,
                'alasan' => $makanan->alasan,
            ]);

        return response()->json([
            'requested_status' => $status,
            'resolved_status' => $resolvedStatus,
            'normalized_status' => $normalized,
            'measurement' => $measurement ? [
                'id' => $measurement->id,
                'child_id' => $measurement->child_id,
                'child_name' => $measurement->child?->nama_anak ?? $measurement->child?->nama,
                'tanggal_ukur' => $measurement->tanggal_ukur?->toDateString(),
                'umur_bulan' => $measurement->umur_bulan,
            ] : null,
            'data' => $items->values(),
        ]);
    }

    private function resolveMeasurement(Request $request, ?int $userId): ?Measurement
    {
        $riwayatId = $request->integer('riwayat_id');
        $childId = $request->integer('child_id');

        if ($riwayatId > 0) {
            return Measurement::query()
                ->with('child')
                ->when(
                    $userId !== null,
                    fn ($query) => $query->whereHas(
                        'child',
                        fn ($childQuery) => $childQuery->where('user_id', $userId)
                    )
                )
                ->when(
                    $childId > 0,
                    fn ($query) => $query->where('child_id', $childId)
                )
                ->find($riwayatId);
        }

        if ($childId > 0 && $userId !== null) {
            $child = Child::query()
                ->where('user_id', $userId)
                ->find($childId);
            if (!$child) {
                return null;
            }

            return $child->measurements()
                ->with('child')
                ->orderByDesc('tanggal_ukur')
                ->orderByDesc('id')
                ->first();
        }

        return null;
    }

    private function normalizeStatus(string $status): array
    {
        $value = strtolower($status);
        $matched = [];

        if (str_contains($value, 'stunting') || str_contains($value, 'stunted')) {
            $matched[] = 'Stunting';
        }
        if (str_contains($value, 'wasting')) {
            $matched[] = 'Wasting';
        }
        if (str_contains($value, 'underweight') || str_contains($value, 'gizi kurang')) {
            $matched[] = 'Underweight';
        }
        if (
            str_contains($value, 'obesitas') ||
            str_contains($value, 'overweight') ||
            str_contains($value, 'gizi lebih')
        ) {
            $matched[] = 'Obesitas';
        }

        $matched = array_values(array_unique($matched));

        if ($matched === []) {
            $matched = ['Normal'];
        }

        return [
            'original_status' => $status,
            'primary_category' => $matched[0],
            'matched_categories' => $matched,
        ];
    }
}
