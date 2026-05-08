<?php

namespace App\Services;

use Carbon\Carbon;

class AgeService
{
    /**
     * Umur dalam bulan (desimal) berbasis selisih hari.
     * Tidak membulatkan di tengah proses.
     */
    public function ageInMonthsDecimal(Carbon $tanggalLahir, Carbon $tanggalUkur): float
    {
        $days = $tanggalLahir->diffInDays($tanggalUkur);

        // WHO umumnya memakai bulan sebagai 30.4375 hari (365.25/12) untuk pendekatan.
        return $days / 30.4375;
    }
}

