<?php

namespace App\Services;

class ZScoreService
{
    // PRESENTASI TA: Rumus inti Z-Score WHO menggunakan parameter LMS.
    /**
     * Rumus WHO LMS:
     * - jika L != 0: Z = ((X/M)^L - 1) / (L*S)
     * - jika L == 0: Z = ln(X/M) / S
     */
    // Kode ini digunakan untuk menghitung nilai Z-Score berdasarkan rumus WHO LMS.
    public function zScore(float $x, ?float $l, ?float $m, ?float $s): ?float
    {
        if (!$this->isValidNumber($x) || !$this->isValidNumber($l) || !$this->isValidNumber($m) || !$this->isValidNumber($s)) {
            return null;
        }

        if ($x <= 0.0 || $m <= 0.0 || $s <= 0.0) {
            return null;
        }

        $ratio = $x / $m;
        if ($ratio <= 0.0 || !is_finite($ratio)) {
            return null;
        }

        if (abs($l) < 0.0000001) {
            $z = log($ratio) / $s;
        } else {
            $denominator = $l * $s;
            if ($denominator == 0.0) {
                return null;
            }

            $powered = pow($ratio, $l);
            if (!is_finite($powered)) {
                return null;
            }

            $z = ($powered - 1.0) / $denominator;
        }

        return is_finite($z) ? $z : null;
    }

    // Kode ini digunakan untuk memastikan nilai berupa angka yang valid dan terbatas.
    private function isValidNumber(?float $value): bool
    {
        return $value !== null && is_finite($value);
    }
}
