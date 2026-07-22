<?php

namespace App\Services;

use Carbon\Carbon;

class AgeService
{
    private const AVERAGE_DAYS_PER_MONTH = 30.4375;

    public function ageInDays(Carbon $tanggalLahir, Carbon $tanggalUkur): int
    {
        return (int) $tanggalLahir
            ->copy()
            ->startOfDay()
            ->diffInDays($tanggalUkur->copy()->startOfDay(), false);
    }

    public function ageInMonthsDecimal(Carbon $tanggalLahir, Carbon $tanggalUkur): float
    {
        return $this->ageInDays($tanggalLahir, $tanggalUkur) / self::AVERAGE_DAYS_PER_MONTH;
    }
}
