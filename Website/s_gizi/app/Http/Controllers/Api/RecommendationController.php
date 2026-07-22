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

    // Kode ini digunakan untuk menampilkan rekomendasi makanan berdasarkan status dan umur anak.
    public function show(Request $request, string $status): JsonResponse
    {
        // PRESENTASI TA: Rekomendasi memakai status pengukuran anak, kategori menu, dan rentang umur.
        $user = $this->userFromToken($request);
        $measurement = $this->resolveMeasurement(
            $request,
            $user?->id,
        );
        $resolvedStatus = $measurement?->status_gabungan ?: $status;
        $normalized = $this->normalizeStatus($resolvedStatus);
        $conditions = $normalized['internal_categories'];
        $ageMonths = $measurement?->umur_bulan;

        $menus = Makanan::query()
            ->when(
                $ageMonths !== null,
                fn ($query) => $query
                    ->where('usia_min', '<=', (int) floor((float) $ageMonths))
                    ->where('usia_max', '>=', (int) ceil((float) $ageMonths))
            )
            ->where('status_menu', 'Published')
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
                'serat' => $makanan->serat,
                'gula' => $makanan->gula,
                'alasan' => $makanan->alasan,
                'thumbnail' => $makanan->thumbnail ? asset($makanan->thumbnail) : null,
                'usia_kategori' => $makanan->usia_kategori,
                'prioritas_menu' => $makanan->prioritas_menu,
                'badges' => $makanan->badges ?? [],
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

    // Kode ini digunakan untuk menampilkan rekomendasi berdasarkan satu hasil pengukuran tertentu.
    public function forMeasurement(Request $request, int $measurementId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }
        $measurement = Measurement::query()
            ->with('child')
            ->whereHas(
                'child',
                fn ($childQuery) => $childQuery->where('user_id', $user->id)
            )
            ->findOrFail($measurementId);

        $request->query->set('riwayat_id', $measurement->id);
        $request->query->set('child_id', $measurement->child_id);

        return $this->show($request, (string) ($measurement->status_gabungan ?? 'latest'));
    }

    // Kode ini digunakan untuk mencari pengukuran yang sesuai dengan anak dan pengguna.
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

    // Kode ini digunakan untuk memetakan status gabungan ke kategori rekomendasi makanan.
    private function normalizeStatus(string $status): array
    {
        $value = strtolower($status);
        $matched = [];

        if (str_contains($value, 'stunting') || str_contains($value, 'stunted')) {
            $matched[] = 'Stunting';
            $matched[] = 'Gizi Kurang';
        }
        if (str_contains($value, 'sangat pendek') || str_contains($value, 'pendek')) {
            $matched[] = 'Stunting';
            $matched[] = 'Gizi Kurang';
        }
        if (str_contains($value, 'wasting')) {
            $matched[] = 'Wasting';
            $matched[] = 'Gizi Kurang';
        }
        if (str_contains($value, 'gizi buruk') || str_contains($value, 'gizi kurang')) {
            $matched[] = 'Wasting';
            $matched[] = str_contains($value, 'buruk') ? 'Gizi Buruk' : 'Gizi Kurang';
        }
        if (str_contains($value, 'underweight') || str_contains($value, 'berat badan kurang') || str_contains($value, 'berat badan sangat kurang')) {
            $matched[] = 'Underweight';
            $matched[] = 'Gizi Kurang';
        }
        if (
            str_contains($value, 'obesitas') ||
            str_contains($value, 'overweight') ||
            str_contains($value, 'gizi lebih') ||
            str_contains($value, 'risiko berat badan lebih')
        ) {
            $matched[] = 'Obesitas';
            $matched[] = str_contains($value, 'gizi lebih') ? 'Gizi Lebih' : 'Risiko Berat Badan Lebih';
        }

        $matched = array_values(array_unique($matched));

        if ($matched === []) {
            $matched = ['Normal'];
            $matched[] = 'Gizi Baik';
        }

        return [
            'original_status' => $this->displayStatus($status),
            'primary_category' => $this->displayCategory($matched[0]),
            'matched_categories' => array_map(fn (string $item): string => $this->displayCategory($item), $matched),
            'internal_categories' => $matched,
        ];
    }

    // Kode ini digunakan untuk mengubah istilah status menjadi istilah yang ditampilkan kepada pengguna.
    private function displayStatus(string $status): string
    {
        $value = strtolower($status);
        $status = str_ireplace(['Severely Stunted', 'Stunting Berat'], 'Sangat Pendek', $status);
        $status = str_ireplace(['Stunting', 'Stunted'], 'Pendek', $status);
        $status = str_ireplace(['Severe Wasting', 'Wasting'], 'Gizi Kurang', $status);
        $status = str_ireplace(['Severe Underweight', 'Underweight'], 'Berat Badan Kurang', $status);
        $status = str_ireplace(['Overweight', 'Risiko Gizi Lebih'], 'Risiko Berat Badan Lebih', $status);
        if ($value === 'normal') return 'Gizi Baik';
        return $status;
    }

    // Kode ini digunakan untuk mengubah kategori internal menjadi kategori berbahasa Indonesia.
    private function displayCategory(string $category): string
    {
        return match ($category) {
            'Stunting' => 'Pendek',
            'Wasting' => 'Gizi Kurang',
            'Underweight' => 'Berat Badan Kurang',
            'Normal' => 'Gizi Baik',
            default => $category,
        };
    }
}
