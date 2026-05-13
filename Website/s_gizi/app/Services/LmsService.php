<?php

namespace App\Services;

use App\Models\WhoLmsAge;
use App\Models\WhoLmsWfl;
use App\Models\WhoLmsWfh;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class LmsService
{
    /**
     * Ambil LMS indikator berbasis umur (BB/U, TB/U).
     * Jika umur desimal, dilakukan interpolasi linear di antara 2 titik terdekat.
     *
     * @return array{l: float, m: float, s: float}
     */
    public function lmsByAge(string $indikator, string $jenisKelamin, float $umurBulan): array
    {
        $lower = WhoLmsAge::query()
            ->where('indikator', $indikator)
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('umur_bulan', '<=', $umurBulan)
            ->orderByDesc('umur_bulan')
            ->first();

        $upper = WhoLmsAge::query()
            ->where('indikator', $indikator)
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('umur_bulan', '>=', $umurBulan)
            ->orderBy('umur_bulan')
            ->first();

        if (!$lower && !$upper) {
            throw new ModelNotFoundException("LMS WHO tidak ditemukan untuk indikator={$indikator}, jk={$jenisKelamin}");
        }

        if (!$lower) {
            return ['l' => (float) $upper->l, 'm' => (float) $upper->m, 's' => (float) $upper->s];
        }

        if (!$upper) {
            return ['l' => (float) $lower->l, 'm' => (float) $lower->m, 's' => (float) $lower->s];
        }

        if ((float) $lower->umur_bulan === (float) $upper->umur_bulan) {
            return ['l' => (float) $lower->l, 'm' => (float) $lower->m, 's' => (float) $lower->s];
        }

        $t = ($umurBulan - (float) $lower->umur_bulan) / ((float) $upper->umur_bulan - (float) $lower->umur_bulan);

        return [
            'l' => (float) $lower->l + $t * ((float) $upper->l - (float) $lower->l),
            'm' => (float) $lower->m + $t * ((float) $upper->m - (float) $lower->m),
            's' => (float) $lower->s + $t * ((float) $upper->s - (float) $lower->s),
        ];
    }

    /**
     * Ambil LMS indikator BB/TB berdasarkan tinggi (cm).
     * Tinggi biasanya step 0.1; jika tidak tepat, interpolasi linear.
     *
     * @return array{l: float, m: float, s: float}
     */
    public function lmsByHeight(string $jenisKelamin, float $tinggiCm): array
    {
        $lower = WhoLmsWfh::query()
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('tinggi', '<=', $tinggiCm)
            ->orderByDesc('tinggi')
            ->first();

        $upper = WhoLmsWfh::query()
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('tinggi', '>=', $tinggiCm)
            ->orderBy('tinggi')
            ->first();

        if (!$lower && !$upper) {
            throw new ModelNotFoundException("LMS WHO BB/TB tidak ditemukan untuk jk={$jenisKelamin}");
        }

        if (!$lower) {
            return ['l' => (float) $upper->l, 'm' => (float) $upper->m, 's' => (float) $upper->s];
        }

        if (!$upper) {
            return ['l' => (float) $lower->l, 'm' => (float) $lower->m, 's' => (float) $lower->s];
        }

        if ((float) $lower->tinggi === (float) $upper->tinggi) {
            return ['l' => (float) $lower->l, 'm' => (float) $lower->m, 's' => (float) $lower->s];
        }

        $t = ($tinggiCm - (float) $lower->tinggi) / ((float) $upper->tinggi - (float) $lower->tinggi);

        return [
            'l' => (float) $lower->l + $t * ((float) $upper->l - (float) $lower->l),
            'm' => (float) $lower->m + $t * ((float) $upper->m - (float) $lower->m),
            's' => (float) $lower->s + $t * ((float) $upper->s - (float) $lower->s),
        ];
    }

    /**
     * Ambil LMS indikator BB/PB (wfl) berdasarkan panjang (cm).
     *
     * @return array{l: float, m: float, s: float}
     */
    public function lmsByLength(string $jenisKelamin, float $panjangCm): array
    {
        $lower = WhoLmsWfl::query()
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('panjang', '<=', $panjangCm)
            ->orderByDesc('panjang')
            ->first();

        $upper = WhoLmsWfl::query()
            ->where('jenis_kelamin', $jenisKelamin)
            ->where('panjang', '>=', $panjangCm)
            ->orderBy('panjang')
            ->first();

        if (!$lower && !$upper) {
            throw new ModelNotFoundException("LMS WHO BB/PB tidak ditemukan untuk jk={$jenisKelamin}");
        }

        if (!$lower) {
            return ['l' => (float) $upper->l, 'm' => (float) $upper->m, 's' => (float) $upper->s];
        }

        if (!$upper) {
            return ['l' => (float) $lower->l, 'm' => (float) $lower->m, 's' => (float) $lower->s];
        }

        if ((float) $lower->panjang === (float) $upper->panjang) {
            return ['l' => (float) $lower->l, 'm' => (float) $lower->m, 's' => (float) $lower->s];
        }

        $t = ($panjangCm - (float) $lower->panjang) / ((float) $upper->panjang - (float) $lower->panjang);

        return [
            'l' => (float) $lower->l + $t * ((float) $upper->l - (float) $lower->l),
            'm' => (float) $lower->m + $t * ((float) $upper->m - (float) $lower->m),
            's' => (float) $lower->s + $t * ((float) $upper->s - (float) $lower->s),
        ];
    }
}

