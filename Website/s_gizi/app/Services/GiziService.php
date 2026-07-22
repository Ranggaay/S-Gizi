<?php

namespace App\Services;

use App\Models\HasilGizi;
use App\Models\Makanan;
use App\Models\WhoLmsAge;
use App\Models\WhoLmsWfh;
use App\Models\WhoLmsWfl;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class GiziService
{
    // Kode ini digunakan untuk memasukkan layanan perhitungan Z-Score dan umur ke GiziService.
    public function __construct(
        private readonly ZScoreService $zScoreService,
        private readonly AgeService $ageService,
    ) {
    }

    /**
     * @param array{
     *   jenis_kelamin:string,
     *   tanggal_lahir:string,
     *   tanggal_ukur:string,
     *   berat_badan:float|int|string,
     *   tinggi_badan:float|int|string,
     *   cara_ukur:string
     * } $payload
     */
    // Kode ini digunakan untuk menjalankan seluruh proses perhitungan dan analisis status gizi anak.
    public function hitung(array $payload): array
    {
        // PRESENTASI TA: Alur utama validasi input, pemilihan LMS, perhitungan tiga indikator, kategori, dan rekomendasi.
        try {
            $validated = $this->validatePayload($payload);
            if (isset($validated['error'])) {
                return $validated;
            }

            $jk = $validated['jenis_kelamin'];
            $tanggalLahir = $validated['tanggal_lahir'];
            $tanggalUkur = $validated['tanggal_ukur'];
            $bb = $validated['berat_badan'];
            $tb = $validated['tinggi_badan'];
            $caraUkur = $validated['cara_ukur'];

            $umurHari = $this->ageService->ageInDays($tanggalLahir, $tanggalUkur);
            $umurBulan = $this->ageService->ageInMonthsDecimal($tanggalLahir, $tanggalUkur);
            if (!$this->isValidNumber($umurBulan) || $umurBulan < 0.0 || $umurBulan > 60.0) {
                return $this->errorResponse('Umur hasil perhitungan harus pada rentang 0-60 bulan.', compact('jk', 'bb', 'tb', 'umurHari', 'umurBulan'));
            }

            $lmsBbu = $this->lmsAgeInterpolated($jk, 'bbu', $umurBulan);
            if ($lmsBbu === null) {
                return $this->errorResponse('Data LMS BB/U tidak ditemukan atau tidak valid.', compact('jk', 'bb', 'tb', 'umurBulan'));
            }

            $lmsTbu = $this->lmsAgeInterpolated($jk, 'tbu', $umurBulan);
            if ($lmsTbu === null) {
                return $this->errorResponse('Data LMS TB/U tidak ditemukan atau tidak valid.', compact('jk', 'bb', 'tb', 'umurBulan'));
            }

            $useWfl = $umurBulan < 24.0;
            if ($umurBulan >= 24.0 && $caraUkur === 'lying') {
                Log::info('Input PB pada umur >=24 bulan diproses dengan standar BB/TB.', [
                    'umur_bulan' => $umurBulan,
                    'jk' => $jk,
                    'tinggi_input' => $tb,
                ]);
            }
            $lmsBbtb = $useWfl
                ? $this->lmsLengthInterpolated($jk, $tb)
                : $this->lmsHeightInterpolated($jk, $tb);

            if ($lmsBbtb === null) {
                $jenis = $useWfl ? 'panjang badan (WFL)' : 'tinggi badan (WFH)';
                return $this->errorResponse("Data LMS BB/TB untuk {$jenis} tidak ditemukan atau tidak valid.", compact('jk', 'bb', 'tb', 'umurBulan'));
            }

            $zBbu = $this->zScoreService->zScore($bb, $lmsBbu['L'], $lmsBbu['M'], $lmsBbu['S']);
            $zTbu = $this->zScoreService->zScore($tb, $lmsTbu['L'], $lmsTbu['M'], $lmsTbu['S']);
            $zBbtb = $this->zScoreService->zScore($bb, $lmsBbtb['L'], $lmsBbtb['M'], $lmsBbtb['S']);

            if (!$this->validZScores($zBbu, $zTbu, $zBbtb)) {
                return $this->errorResponse('Perhitungan gagal: z-score tidak valid. Periksa BB/TB, umur, jenis kelamin, dan kelengkapan data LMS.', [
                    'jk' => $jk,
                    'bb' => $bb,
                    'tb' => $tb,
                    'umur_bulan' => $umurBulan,
                    'z_bbu' => $zBbu,
                    'z_tbu' => $zTbu,
                    'z_bbtb' => $zBbtb,
                ]);
            }

            $kategoriBbu = $this->kategoriBbu($zBbu);
            $kategoriTbu = $this->kategoriTbu($zTbu);
            $kategoriBbtb = $this->kategoriBbtb($zBbtb);
            $statusGabungan = $this->statusGabungan($zTbu, $zBbtb, $zBbu);
            $kondisi = $this->kondisiKhusus($zTbu, $zBbtb, $zBbu);
            $rekomendasi = $this->rekomendasiMakananAdvanced($umurBulan, $kondisi);

            Log::debug('Validasi WHO selesai.', [
                'umur_hari' => $umurHari,
                'umur_bulan' => $umurBulan,
                'jenis_kelamin' => $jk,
                'standar_bbtb' => $useWfl ? 'BB/PB' : 'BB/TB',
                'z_bbu' => $zBbu,
                'z_tbu' => $zTbu,
                'z_bbtb' => $zBbtb,
                'kategori_bbu' => $kategoriBbu,
                'kategori_tbu' => $kategoriTbu,
                'kategori_bbtb' => $kategoriBbtb,
                'status_final' => $statusGabungan,
            ]);

            $this->saveHasilGizi($bb, $tb, $umurBulan, $zBbu, $zTbu, $zBbtb, $statusGabungan);

            return [
                'identitas' => [
                    'umur_hari' => $umurHari,
                    'umur_bulan' => round($umurBulan, 2),
                    'jenis_kelamin' => $jk,
                    'cara_ukur' => $caraUkur,
                    'standar_bbtb' => $useWfl ? 'BB/PB' : 'BB/TB',
                ],
                'zscore' => [
                    'bbu' => round($zBbu, 2),
                    'tbu' => round($zTbu, 2),
                    'bbtb' => round($zBbtb, 2),
                ],
                'kategori' => [
                    'bbu' => $kategoriBbu,
                    'tbu' => $kategoriTbu,
                    'bbtb' => $kategoriBbtb,
                ],
                'status_gabungan' => $statusGabungan,
                'rekomendasi' => $rekomendasi,
            ];
        } catch (\Throwable $e) {
            Log::error('GiziService gagal menghitung status gizi.', [
                'message' => $e->getMessage(),
                'payload' => $payload,
                'trace' => $e->getTraceAsString(),
            ]);

            return $this->errorResponse('Perhitungan status gizi gagal diproses. Silakan periksa data input dan data LMS.');
        }
    }

    /**
     * @return array<string, mixed>
     */
    // Kode ini digunakan untuk memvalidasi kelengkapan dan kewajaran data pengukuran anak.
    private function validatePayload(array $payload): array
    {
        foreach (['jenis_kelamin', 'tanggal_lahir', 'tanggal_ukur', 'berat_badan', 'tinggi_badan', 'cara_ukur'] as $field) {
            if (!array_key_exists($field, $payload)) {
                return $this->errorResponse("Field {$field} wajib diisi.");
            }
        }

        $jk = (string) $payload['jenis_kelamin'];
        if (!in_array($jk, ['L', 'P'], true)) {
            return $this->errorResponse('Jenis kelamin harus L atau P.');
        }

        $caraUkur = (string) $payload['cara_ukur'];
        if (!in_array($caraUkur, ['standing', 'lying'], true)) {
            return $this->errorResponse('Cara ukur harus standing atau lying.');
        }

        if (!is_numeric($payload['berat_badan']) || !is_numeric($payload['tinggi_badan'])) {
            return $this->errorResponse('BB dan TB harus berupa angka.');
        }

        $bb = (float) $payload['berat_badan'];
        $tb = (float) $payload['tinggi_badan'];
        if (!$this->isValidNumber($bb) || $bb <= 0.0) {
            return $this->errorResponse('Berat badan harus lebih dari 0 kg.');
        }

        if (!$this->isValidNumber($tb) || $tb <= 0.0) {
            return $this->errorResponse('Tinggi/panjang badan harus lebih dari 0 cm.');
        }

        if ($bb > 80.0 || $tb < 30.0 || $tb > 130.0) {
            return $this->errorResponse('Data BB/TB berada di luar rentang balita yang wajar untuk standar WHO.');
        }

        try {
            $tanggalLahir = Carbon::parse($payload['tanggal_lahir'])->startOfDay();
            $tanggalUkur = Carbon::parse($payload['tanggal_ukur'])->startOfDay();
        } catch (\Throwable $e) {
            Log::warning('Format tanggal input gizi tidak valid.', ['payload' => $payload, 'message' => $e->getMessage()]);
            return $this->errorResponse('Tanggal lahir atau tanggal ukur tidak valid.');
        }

        if ($tanggalUkur->lt($tanggalLahir)) {
            return $this->errorResponse('Tanggal ukur tidak boleh sebelum tanggal lahir.');
        }

        return [
            'jenis_kelamin' => $jk,
            'tanggal_lahir' => $tanggalLahir,
            'tanggal_ukur' => $tanggalUkur,
            'berat_badan' => $bb,
            'tinggi_badan' => $tb,
            'cara_ukur' => $caraUkur,
        ];
    }

    /**
     * @return array{L:float,M:float,S:float}|null
     */
    // Kode ini digunakan untuk mengambil dan menginterpolasi nilai LMS berdasarkan umur anak.
    private function lmsAgeInterpolated(string $jk, string $indikator, float $umurBulan): ?array
    {
        // PRESENTASI TA: Data LMS BB/U dan TB/U dipilih menurut jenis kelamin, indikator, dan umur lalu diinterpolasi.
        if (!$this->isValidNumber($umurBulan) || $umurBulan < 0.0 || $umurBulan > 60.0) {
            Log::warning('Umur di luar rentang LMS umur.', compact('jk', 'indikator', 'umurBulan'));
            return null;
        }

        $umurBawah = max(0, (int) floor($umurBulan));
        $umurAtas = min(60, (int) ceil($umurBulan));

        $row1 = Cache::remember("lms_age:{$jk}:{$indikator}:{$umurBawah}", now()->addDay(), fn () => WhoLmsAge::query()
            ->where('indikator', $indikator)
            ->where('jk', $jk)
            ->where('umur', $umurBawah)
            ->first());

        $row2 = Cache::remember("lms_age:{$jk}:{$indikator}:{$umurAtas}", now()->addDay(), fn () => WhoLmsAge::query()
            ->where('indikator', $indikator)
            ->where('jk', $jk)
            ->where('umur', $umurAtas)
            ->first());

        if (!$row1 || !$row2) {
            Log::warning('Data LMS umur tidak ditemukan.', compact('jk', 'indikator', 'umurBulan', 'umurBawah', 'umurAtas'));
            return null;
        }

        if ($umurBawah === $umurAtas) {
            return $this->normalizeLmsRow($row1, 'umur');
        }

        $lower = $this->normalizeLmsRow($row1, 'umur');
        $upper = $this->normalizeLmsRow($row2, 'umur');
        if ($lower === null || $upper === null) {
            Log::warning('Nilai LMS umur tidak valid.', compact('jk', 'indikator', 'umurBulan'));
            return null;
        }

        return $this->interpolateLms($lower, $upper, $umurBulan, (float) $umurBawah, (float) $umurAtas);
    }

    /**
     * Tinggi (WFH) interpolasi jika tidak ada exact match.
     * @return array{L:float,M:float,S:float}|null
     */
    // Kode ini digunakan untuk mengambil nilai LMS BB/TB berdasarkan tinggi badan berdiri.
    private function lmsHeightInterpolated(string $jk, float $tinggiCm): ?array
    {
        return $this->lmsByAnthropometry(WhoLmsWfh::class, 'tinggi', $jk, $tinggiCm, 'WFH');
    }

    /**
     * Panjang (WFL) interpolasi jika tidak ada exact match.
     * @return array{L:float,M:float,S:float}|null
     */
    // Kode ini digunakan untuk mengambil nilai LMS BB/PB berdasarkan panjang badan telentang.
    private function lmsLengthInterpolated(string $jk, float $panjangCm): ?array
    {
        return $this->lmsByAnthropometry(WhoLmsWfl::class, 'panjang', $jk, $panjangCm, 'WFL');
    }

    /**
     * @param class-string $model
     * @return array{L:float,M:float,S:float}|null
     */
    // Kode ini digunakan untuk mencari batas bawah dan atas LMS berdasarkan ukuran antropometri.
    private function lmsByAnthropometry(string $model, string $column, string $jk, float $value, string $label): ?array
    {
        if (!$this->isValidNumber($value) || $value <= 0.0) {
            Log::warning("Nilai {$label} tidak valid.", compact('jk', 'value'));
            return null;
        }

        $cacheValue = number_format($value, 2, '.', '');
        $lower = Cache::remember("lms_{$label}:{$jk}:{$cacheValue}:lower", now()->addDay(), fn () => $model::query()
            ->where('jk', $jk)
            ->where($column, '<=', $value)
            ->orderByDesc($column)
            ->first());

        $upper = Cache::remember("lms_{$label}:{$jk}:{$cacheValue}:upper", now()->addDay(), fn () => $model::query()
            ->where('jk', $jk)
            ->where($column, '>=', $value)
            ->orderBy($column)
            ->first());

        if (!$lower || !$upper) {
            Log::warning("Data LMS {$label} tidak ditemukan.", ['jk' => $jk, $column => $value]);
            return null;
        }

        $lowerValue = (float) $lower->{$column};
        $upperValue = (float) $upper->{$column};
        if (!$this->isValidNumber($lowerValue) || !$this->isValidNumber($upperValue)) {
            Log::warning("Batas LMS {$label} tidak valid.", ['jk' => $jk, $column => $value]);
            return null;
        }

        if (abs($lowerValue - $upperValue) < 0.0000001) {
            return $this->normalizeLmsRow($lower, $column);
        }

        $lowerLms = $this->normalizeLmsRow($lower, $column);
        $upperLms = $this->normalizeLmsRow($upper, $column);
        if ($lowerLms === null || $upperLms === null) {
            Log::warning("Nilai LMS {$label} tidak valid.", ['jk' => $jk, $column => $value]);
            return null;
        }

        return $this->interpolateLms($lowerLms, $upperLms, $value, $lowerValue, $upperValue);
    }

    /**
     * @return array{L:float,M:float,S:float}|null
     */
    // Kode ini digunakan untuk mengubah data LMS dari database menjadi nilai L, M, dan S yang valid.
    private function normalizeLmsRow(object $row, string $context): ?array
    {
        $l = (float) ($row->L ?? NAN);
        $m = (float) ($row->M ?? NAN);
        $s = (float) ($row->S ?? NAN);

        if (!$this->isValidNumber($l) || !$this->isValidNumber($m) || !$this->isValidNumber($s) || $m <= 0.0 || $s <= 0.0) {
            Log::warning('Nilai LMS tidak valid.', ['context' => $context, 'L' => $row->L ?? null, 'M' => $row->M ?? null, 'S' => $row->S ?? null]);
            return null;
        }

        return ['L' => $l, 'M' => $m, 'S' => $s];
    }

    /**
     * @param array{L:float,M:float,S:float} $lower
     * @param array{L:float,M:float,S:float} $upper
     * @return array{L:float,M:float,S:float}|null
     */
    // Kode ini digunakan untuk menghitung interpolasi LMS di antara dua data referensi WHO.
    private function interpolateLms(array $lower, array $upper, float $value, float $lowerValue, float $upperValue): ?array
    {
        $range = $upperValue - $lowerValue;
        if (abs($range) < 0.0000001) {
            return $lower;
        }

        $t = ($value - $lowerValue) / $range;
        if (!$this->isValidNumber($t)) {
            return null;
        }

        $result = [
            'L' => $lower['L'] + ($upper['L'] - $lower['L']) * $t,
            'M' => $lower['M'] + ($upper['M'] - $lower['M']) * $t,
            'S' => $lower['S'] + ($upper['S'] - $lower['S']) * $t,
        ];

        return $this->validLms($result) ? $result : null;
    }

    /**
     * @param array{L:float,M:float,S:float} $lms
     */
    // Kode ini digunakan untuk memeriksa kelengkapan dan validitas nilai LMS.
    private function validLms(array $lms): bool
    {
        return $this->isValidNumber($lms['L'] ?? null)
            && $this->isValidNumber($lms['M'] ?? null)
            && $this->isValidNumber($lms['S'] ?? null)
            && $lms['M'] > 0.0
            && $lms['S'] > 0.0;
    }

    // Kode ini digunakan untuk menentukan kategori berat badan menurut umur dari nilai Z-Score.
    private function kategoriBbu(float $z): string
    {
        // PRESENTASI TA: Ambang kategori status gizi untuk indikator BB/U.
        if ($z < -3.0) return 'Berat Badan Sangat Kurang';
        if ($z < -2.0) return 'Berat Badan Kurang';
        if ($z <= 1.0) return 'Berat Badan Normal';
        return 'Risiko Berat Badan Lebih';
    }

    // Kode ini digunakan untuk menentukan kategori tinggi badan menurut umur dari nilai Z-Score.
    private function kategoriTbu(float $z): string
    {
        // PRESENTASI TA: Ambang kategori status gizi untuk indikator TB/U.
        if ($z < -3.0) return 'Sangat Pendek';
        if ($z < -2.0) return 'Pendek';
        if ($z <= 3.0) return 'Normal';
        return 'Tinggi';
    }

    // Kode ini digunakan untuk menentukan kategori berat badan menurut tinggi badan dari nilai Z-Score.
    private function kategoriBbtb(float $z): string
    {
        // PRESENTASI TA: Ambang kategori status gizi untuk indikator BB/TB.
        if ($z < -3.0) return 'Gizi Buruk';
        if ($z < -2.0) return 'Gizi Kurang';
        if ($z <= 1.0) return 'Gizi Baik';
        if ($z <= 2.0) return 'Risiko Berat Badan Lebih';
        if ($z <= 3.0) return 'Gizi Lebih';
        return 'Obesitas';
    }

    // Kode ini digunakan untuk menggabungkan tiga indikator menjadi status gizi utama anak.
    private function statusGabungan(?float $zTbu, ?float $zBbtb, ?float $zBbu): string
    {
        if (!$this->validZScores($zBbu, $zTbu, $zBbtb)) {
            return 'Belum Diukur';
        }

        if ($zTbu < -3.0) {
            if ($zBbtb > 3.0) return 'Sangat Pendek + Obesitas';
            if ($zBbtb > 2.0) return 'Sangat Pendek + Gizi Lebih';
            if ($zBbtb > 1.0) return 'Sangat Pendek + Risiko Berat Badan Lebih';
            if ($zBbtb < -3.0) return 'Sangat Pendek + Gizi Buruk';
            if ($zBbtb < -2.0) return 'Sangat Pendek + Gizi Kurang';
            if ($zBbu < -3.0) return 'Sangat Pendek + Berat Badan Sangat Kurang';
            if ($zBbu < -2.0) return 'Sangat Pendek + Berat Badan Kurang';
            return 'Sangat Pendek';
        }

        if ($zTbu < -2.0) {
            if ($zBbtb > 3.0) return 'Pendek + Obesitas';
            if ($zBbtb > 2.0) return 'Pendek + Gizi Lebih';
            if ($zBbtb > 1.0) return 'Pendek + Risiko Berat Badan Lebih';
            if ($zBbtb < -3.0) return 'Pendek + Gizi Buruk';
            if ($zBbtb < -2.0) return 'Pendek + Gizi Kurang';
            if ($zBbu < -3.0) return 'Pendek + Berat Badan Sangat Kurang';
            if ($zBbu < -2.0) return 'Pendek + Berat Badan Kurang';
            return 'Pendek';
        }

        if ($zBbtb < -3.0) {
            if ($zBbu < -3.0) return 'Gizi Buruk + Berat Badan Sangat Kurang';
            if ($zBbu < -2.0) return 'Gizi Buruk + Berat Badan Kurang';
            return 'Gizi Buruk';
        }

        if ($zBbtb < -2.0) {
            if ($zBbu < -3.0) return 'Gizi Kurang + Berat Badan Sangat Kurang';
            if ($zBbu < -2.0) return 'Gizi Kurang + Berat Badan Kurang';
            return 'Gizi Kurang';
        }

        if ($zBbu < -3.0) return 'Berat Badan Sangat Kurang';
        if ($zBbu < -2.0) return 'Berat Badan Kurang';

        if ($zBbtb > 3.0) return 'Obesitas';
        if ($zBbtb > 2.0) return 'Gizi Lebih';
        if ($zBbtb > 1.0) return 'Risiko Berat Badan Lebih';

        return 'Gizi Baik';
    }

    // Kode ini digunakan untuk menentukan kondisi khusus sebagai dasar pemilihan rekomendasi makanan.
    private function kondisiKhusus(float $zTbu, float $zBbtb, float $zBbu): string
    {
        if ($zTbu < -2.0 && $zBbtb > 2.0) return 'Pendek_Obesitas';
        if ($zTbu < -2.0) return 'Pendek';
        if ($zBbtb < -2.0) return 'Gizi Kurang';
        if ($zBbu < -2.0) return 'Berat Badan Kurang';
        if ($zBbtb > 2.0) return 'Obesitas';
        return 'Gizi Baik';
    }

    /**
     * @return array<int, array{menu:string,kalori:int,protein:int,lemak:int,karbohidrat:int,alasan:string}>
     */
    // Kode ini digunakan untuk mengambil rekomendasi makanan berdasarkan umur dan kondisi gizi anak.
    private function rekomendasiMakananAdvanced(float $umurBulan, string $kondisi): array
    {
        // PRESENTASI TA: Rekomendasi rule-based berdasarkan umur dan kondisi hasil perhitungan.
        $umur = max(0, (int) floor($umurBulan));

        $items = Makanan::query()
            ->where('usia_min', '<=', $umur)
            ->where('usia_max', '>=', $umur)
            ->where(function ($q) use ($kondisi) {
                $kategoriStatus = $this->kategoriMakananLegacy($kondisi);
                if ($kondisi === 'Pendek_Obesitas') {
                    $q->whereIn('kategori_status', ['Stunting', 'Normal']);
                } else {
                    $q->where('kategori_status', $kategoriStatus);
                }
            })
            ->get();

        if ($kondisi === 'Pendek_Obesitas') {
            $items = $items->filter(fn ($m) => (float) $m->protein >= 10.0 && (float) $m->lemak <= 10.0);
        }

        if ($items->isEmpty()) {
            $items = Makanan::query()
                ->where('usia_min', '<=', $umur)
                ->where('usia_max', '>=', $umur)
                ->where('kategori_status', 'Normal')
                ->get();
        }

        return $items->take(5)->map(fn ($m) => [
            'menu' => (string) $m->nama,
            'kalori' => (int) $m->kalori,
            'protein' => (int) $m->protein,
            'lemak' => (int) $m->lemak,
            'karbohidrat' => (int) $m->karbohidrat,
            'alasan' => $this->generateAlasan($kondisi),
        ])->values()->all();
    }

    // Kode ini digunakan untuk membuat alasan pemilihan rekomendasi sesuai kondisi gizi.
    private function generateAlasan(string $kondisi): string
    {
        return match ($kondisi) {
            'Pendek_Obesitas' => 'Mendukung pertumbuhan tinggi badan dengan asupan protein tinggi, serta mengontrol kelebihan berat badan melalui pembatasan lemak dan kalori.',
            'Pendek' => 'Membantu mengejar pertumbuhan tinggi badan dengan meningkatkan asupan protein dan nutrisi penting.',
            'Gizi Kurang' => 'Meningkatkan berat badan dengan asupan energi dan kalori yang lebih tinggi.',
            'Berat Badan Kurang' => 'Meningkatkan berat badan melalui asupan energi dan protein yang cukup.',
            'Obesitas' => 'Mengontrol berat badan dengan mengurangi asupan kalori dan lemak berlebih.',
            default => 'Menjaga keseimbangan asupan nutrisi untuk mendukung pertumbuhan dan kesehatan.',
        };
    }

    // Kode ini digunakan untuk menyesuaikan nama kondisi dengan kategori makanan pada database.
    private function kategoriMakananLegacy(string $kondisi): string
    {
        return match ($kondisi) {
            'Pendek', 'Pendek_Obesitas' => 'Stunting',
            'Gizi Kurang' => 'Wasting',
            'Berat Badan Kurang' => 'Underweight',
            'Gizi Baik' => 'Normal',
            default => $kondisi,
        };
    }

    // Kode ini digunakan untuk menyimpan hasil perhitungan status gizi ke database.
    private function saveHasilGizi(float $bb, float $tb, float $umurBulan, float $zBbu, float $zTbu, float $zBbtb, string $statusGabungan): void
    {
        try {
            HasilGizi::query()->create([
                'berat' => $bb,
                'tinggi' => $tb,
                'umur' => $umurBulan,
                'z_bbu' => $zBbu,
                'z_tbu' => $zTbu,
                'z_bbtb' => $zBbtb,
                'status_gabungan' => $statusGabungan,
                'created_at' => now(),
            ]);
        } catch (\Throwable $e) {
            Log::warning('Hasil gizi berhasil dihitung tetapi gagal disimpan.', [
                'message' => $e->getMessage(),
                'status_gabungan' => $statusGabungan,
                'bb' => $bb,
                'tb' => $tb,
                'umur_bulan' => $umurBulan,
            ]);
        }
    }

    // Kode ini digunakan untuk memastikan seluruh hasil Z-Score valid.
    private function validZScores(?float ...$scores): bool
    {
        foreach ($scores as $score) {
            if (!$this->isValidNumber($score)) {
                return false;
            }
        }

        return true;
    }

    // Kode ini digunakan untuk memastikan sebuah nilai berupa angka yang valid dan terbatas.
    private function isValidNumber(?float $value): bool
    {
        return $value !== null && is_finite($value);
    }

    /**
     * @param array<string, mixed> $context
     * @return array{error:string}
     */
    // Kode ini digunakan untuk mencatat dan membentuk respons ketika proses perhitungan gagal.
    private function errorResponse(string $message, array $context = []): array
    {
        Log::warning('Perhitungan gizi ditolak.', ['error' => $message, 'context' => $context]);

        return ['error' => $message];
    }
}
