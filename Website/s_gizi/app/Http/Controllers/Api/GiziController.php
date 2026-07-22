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

    // Kode ini digunakan untuk memasukkan GiziService ke dalam controller API.
    public function __construct(private readonly GiziService $giziService)
    {
    }

    // Kode ini digunakan untuk menerima pengukuran, menghitung status gizi, dan menyimpan hasilnya.
    public function hitung(Request $request): JsonResponse
    {
        // PRESENTASI TA: Endpoint hitung menghubungkan aplikasi, GiziService, dan penyimpanan riwayat pengukuran.
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $validated = $request->validate([
            'child_id' => ['required', 'integer', 'exists:children,id'],
            'tanggal_ukur' => ['required', 'date'],
            'berat_badan' => ['required', 'numeric', 'gt:0', 'max:80'],
            'tinggi_badan' => ['required', 'numeric', 'gt:0', 'min:30', 'max:130'],
            'cara_ukur' => ['required', 'in:standing,lying'],
            'is_anomaly' => ['nullable', 'boolean'],
            'validation_status' => ['nullable', 'in:valid,perlu_ukur_ulang'],
            'validation_note' => ['nullable', 'string', 'max:1000'],
            'monitoring_status' => ['nullable', 'in:normal,perlu_dipantau'],
            'is_confirmed_by_parent' => ['nullable', 'boolean'],
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

        $hasExtremeZScore = collect($result['zscore'] ?? [])
            ->filter(fn ($value) => is_numeric($value))
            ->contains(fn ($value) => (float) $value < -6 || (float) $value > 6);
        $validationStatus = (string) ($validated['validation_status'] ?? 'valid');
        if ($hasExtremeZScore) {
            $validationStatus = 'perlu_ukur_ulang';
        }
        $monitoringStatus = (string) ($validated['monitoring_status'] ?? 'normal');
        $isAnomaly = (bool) ($validated['is_anomaly'] ?? false) || $hasExtremeZScore || $validationStatus === 'perlu_ukur_ulang';
        $dataStatus = $validationStatus === 'perlu_ukur_ulang' ? 'perlu_ukur_ulang' : 'normal';
        $validationNote = trim((string) ($validated['validation_note'] ?? ''));
        if ($validationNote === '' && $hasExtremeZScore) {
            $validationNote = 'Hasil Z-score berada di luar batas normal WHO dan perlu dicek ulang.';
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
            'is_anomaly' => $isAnomaly,
            'data_status' => $dataStatus,
            'validation_status' => $validationStatus,
            'validation_note' => $validationNote,
            'monitoring_status' => $monitoringStatus,
            'is_confirmed_by_parent' => (bool) ($validated['is_confirmed_by_parent'] ?? false),
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
                'is_anomaly' => $measurement->is_anomaly,
                'data_status' => $measurement->data_status,
                'validation_status' => $measurement->validation_status ?? 'valid',
                'validation_note' => $measurement->validation_note ?? '',
                'monitoring_status' => $measurement->monitoring_status ?? 'normal',
                'is_confirmed_by_parent' => (bool) $measurement->is_confirmed_by_parent,
            ],
        ]);
    }

    // Kode ini digunakan untuk menampilkan riwayat pengukuran milik anak pengguna.
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
                ->orderBy('tanggal_ukur')
                ->orderBy('id')
                ->get()
                ->map(fn (Measurement $item) => [
                    'id' => $item->id,
                    'berat' => $item->berat,
                    'tinggi' => $item->tinggi,
                    'tanggal_ukur' => $item->tanggal_ukur->toDateString(),
                    'cara_ukur' => $item->cara_ukur,
                    'umur_bulan' => $item->umur_bulan,
                    'status_gabungan' => $item->status_gabungan,
                    'is_anomaly' => (bool) $item->is_anomaly,
                    'data_status' => $item->data_status ?? 'normal',
                    'validation_status' => $item->validation_status ?? 'valid',
                    'validation_note' => $item->validation_note ?? '',
                    'monitoring_status' => $item->monitoring_status ?? 'normal',
                    'is_confirmed_by_parent' => (bool) $item->is_confirmed_by_parent,
                    'kategori' => $item->kategori,
                    'z_score' => [
                        'bbu' => $item->z_bbu,
                        'tbu' => $item->z_tbu,
                        'bbtb' => $item->z_bbtb,
                    ],
                ]),
        ]);
    }

    // Kode ini digunakan untuk mengonfirmasi validitas hasil pengukuran oleh orang tua.
    public function confirm(Request $request, int $measurementId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $validated = $request->validate([
            'validation_status' => ['nullable', 'in:valid,perlu_ukur_ulang'],
            'monitoring_status' => ['nullable', 'in:normal,perlu_dipantau'],
            'validation_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $measurement = Measurement::query()
            ->whereHas('child', fn ($query) => $query->where('user_id', $user->id))
            ->findOrFail($measurementId);

        $measurement->update([
            'validation_status' => $validated['validation_status'] ?? $measurement->validation_status ?? 'valid',
            'monitoring_status' => $validated['monitoring_status'] ?? $measurement->monitoring_status ?? 'normal',
            'validation_note' => $validated['validation_note'] ?? $measurement->validation_note,
            'is_confirmed_by_parent' => true,
        ]);

        return response()->json([
            'message' => 'Data pengukuran berhasil dikonfirmasi.',
            'data' => $this->measurementResultPayload($measurement->fresh('child')),
        ]);
    }

    // Kode ini digunakan untuk menampilkan detail hasil suatu pengukuran.
    public function result(Request $request, int $measurementId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) return $this->unauthenticated();

        $measurement = Measurement::query()
            ->with('child')
            ->whereHas('child', fn ($query) => $query->where('user_id', $user->id))
            ->findOrFail($measurementId);

        return response()->json($this->measurementResultPayload($measurement));
    }

    // Kode ini digunakan untuk memilih Z-Score utama yang mewakili status gabungan.
    private function primaryZScore(string $status, array $scores): float
    {
        $status = strtolower($status);

        if (str_contains($status, 'pendek')) {
            return (float) $scores['tbu'];
        }
        if (str_contains($status, 'gizi buruk') || str_contains($status, 'gizi kurang') || str_contains($status, 'obesitas') || str_contains($status, 'gizi lebih') || str_contains($status, 'risiko berat badan lebih')) {
            return (float) $scores['bbtb'];
        }

        return (float) $scores['bbu'];
    }

    // Kode ini digunakan untuk membentuk struktur data hasil pengukuran bagi respons API.
    private function measurementResultPayload(Measurement $measurement): array
    {
        return [
            'identitas' => [
                'umur_bulan' => $measurement->umur_bulan,
                'umur_hari' => null,
                'jenis_kelamin' => $measurement->child?->jenis_kelamin ?? '-',
                'cara_ukur' => $measurement->cara_ukur ?? '-',
                'standar_bbtb' => 'BB/TB',
            ],
            'zscore' => [
                'bbu' => $measurement->z_bbu,
                'tbu' => $measurement->z_tbu,
                'bbtb' => $measurement->z_bbtb,
            ],
            'kategori' => is_array($measurement->kategori) ? $measurement->kategori : [],
            'status_gabungan' => $measurement->status_gabungan,
            'rekomendasi' => [],
            'measurement' => [
                'id' => $measurement->id,
                'child_id' => $measurement->child_id,
                'child_name' => $measurement->child?->nama_anak ?? $measurement->child?->nama,
                'tanggal_ukur' => $measurement->tanggal_ukur?->toDateString(),
                'cara_ukur' => $measurement->cara_ukur,
                'is_anomaly' => (bool) $measurement->is_anomaly,
                'data_status' => $measurement->data_status ?? 'normal',
                'validation_status' => $measurement->validation_status ?? 'valid',
                'validation_note' => $measurement->validation_note ?? '',
                'monitoring_status' => $measurement->monitoring_status ?? 'normal',
                'is_confirmed_by_parent' => (bool) $measurement->is_confirmed_by_parent,
            ],
        ];
    }
}
