<?php

namespace App\Helpers;

use App\Models\Measurement;

class NutritionStatusHelper
{
    public const BELUM_DIUKUR = 'Belum Diukur';
    public const GIZI_BAIK = 'Gizi Baik';
    public const GIZI_KURANG = 'Gizi Kurang';
    public const GIZI_BURUK = 'Gizi Buruk';
    public const GIZI_LEBIH = 'Gizi Lebih';
    public const OBESITAS = 'Obesitas';
    public const PENDEK = 'Pendek';
    public const SANGAT_PENDEK = 'Sangat Pendek';
    public const RISIKO_BB_LEBIH = 'Risiko Berat Badan Lebih';

    public static function getStatus(?Measurement $measurement = null, ?string $status = null): string
    {
        if ($measurement) {
            $bbtb = self::floatOrNull($measurement->z_bbtb);
            $tbu = self::floatOrNull($measurement->z_tbu);
            $bbu = self::floatOrNull($measurement->z_bbu);

            if ($bbtb !== null) {
                if ($bbtb < -3) {
                    return self::GIZI_BURUK;
                }
                if ($bbtb < -2) {
                    return self::GIZI_KURANG;
                }
            }

            if ($tbu !== null) {
                if ($tbu < -3) {
                    return self::SANGAT_PENDEK;
                }
                if ($tbu < -2) {
                    return self::PENDEK;
                }
            }

            if ($bbtb !== null) {
                if ($bbtb > 3) {
                    return self::OBESITAS;
                }
                if ($bbtb > 2) {
                    return self::GIZI_LEBIH;
                }
                if ($bbtb > 1) {
                    return self::RISIKO_BB_LEBIH;
                }
            }

            if ($bbu !== null && $bbu < -2) {
                return self::GIZI_KURANG;
            }

            if ($bbtb !== null || $tbu !== null || $bbu !== null) {
                return self::GIZI_BAIK;
            }
        }

        return self::localize($status);
    }

    public static function localize(?string $status): string
    {
        $value = trim((string) $status);
        if ($value === '' || $value === '-') {
            return self::BELUM_DIUKUR;
        }

        $map = [
            'severely stunted' => self::SANGAT_PENDEK,
            'stunting berat' => self::SANGAT_PENDEK,
            'sangat pendek' => self::SANGAT_PENDEK,
            'stunted' => self::PENDEK,
            'stunting' => self::PENDEK,
            'pendek' => self::PENDEK,
            'severe wasting' => self::GIZI_BURUK,
            'severely wasted' => self::GIZI_BURUK,
            'gizi buruk' => self::GIZI_BURUK,
            'wasting' => self::GIZI_KURANG,
            'underweight' => self::GIZI_KURANG,
            'severe underweight' => self::GIZI_KURANG,
            'berat badan kurang' => self::GIZI_KURANG,
            'gizi kurang' => self::GIZI_KURANG,
            'risk of overweight' => self::RISIKO_BB_LEBIH,
            'risiko gizi lebih' => self::RISIKO_BB_LEBIH,
            'risiko berat badan lebih' => self::RISIKO_BB_LEBIH,
            'overweight' => self::GIZI_LEBIH,
            'gizi lebih' => self::GIZI_LEBIH,
            'obese' => self::OBESITAS,
            'obesity' => self::OBESITAS,
            'obesitas' => self::OBESITAS,
            'normal' => self::GIZI_BAIK,
            'gizi baik' => self::GIZI_BAIK,
        ];

        $lower = strtolower($value);
        foreach ($map as $needle => $label) {
            if (str_contains($lower, $needle)) {
                return $label;
            }
        }

        return $value;
    }

    public static function badgeClass(?string $status): string
    {
        return match (self::localize($status)) {
            self::SANGAT_PENDEK, self::OBESITAS, self::GIZI_BURUK => 'sg-status-red',
            self::PENDEK, self::GIZI_KURANG, self::GIZI_LEBIH => 'sg-status-orange',
            self::RISIKO_BB_LEBIH => 'sg-status-yellow',
            self::GIZI_BAIK => 'sg-status-green',
            default => 'sg-status-gray',
        };
    }

    public static function primaryZScore(Measurement $measurement): array
    {
        $status = self::getStatus($measurement);

        if (in_array($status, [self::SANGAT_PENDEK, self::PENDEK], true)) {
            return ['label' => 'TB/U', 'value' => self::floatOrNull($measurement->z_tbu)];
        }

        if (in_array($status, [self::GIZI_BURUK, self::GIZI_KURANG, self::GIZI_LEBIH, self::OBESITAS, self::RISIKO_BB_LEBIH], true)) {
            return ['label' => 'BB/TB', 'value' => self::floatOrNull($measurement->z_bbtb)];
        }

        return ['label' => 'BB/U', 'value' => self::floatOrNull($measurement->z_bbu)];
    }

    public static function bbuStatus(?Measurement $measurement): string
    {
        $z = $measurement ? self::floatOrNull($measurement->z_bbu) : null;
        if ($z === null) {
            return self::BELUM_DIUKUR;
        }
        if ($z < -3) {
            return 'Sangat Kurang';
        }
        if ($z < -2) {
            return 'Kurang';
        }
        if ($z > 1) {
            return self::RISIKO_BB_LEBIH;
        }

        return 'Normal';
    }

    public static function tbuStatus(?Measurement $measurement): string
    {
        $z = $measurement ? self::floatOrNull($measurement->z_tbu) : null;
        if ($z === null) {
            return self::BELUM_DIUKUR;
        }
        if ($z < -3) {
            return self::SANGAT_PENDEK;
        }
        if ($z < -2) {
            return self::PENDEK;
        }

        return 'Normal';
    }

    public static function bbtbStatus(?Measurement $measurement): string
    {
        $z = $measurement ? self::floatOrNull($measurement->z_bbtb) : null;
        if ($z === null) {
            return self::BELUM_DIUKUR;
        }
        if ($z < -3) {
            return self::GIZI_BURUK;
        }
        if ($z < -2) {
            return self::GIZI_KURANG;
        }
        if ($z > 3) {
            return self::OBESITAS;
        }
        if ($z > 2) {
            return self::GIZI_LEBIH;
        }
        if ($z > 1) {
            return self::RISIKO_BB_LEBIH;
        }

        return self::GIZI_BAIK;
    }

    public static function riskLabel(?string $status): string
    {
        return match (self::localize($status)) {
            self::SANGAT_PENDEK, self::OBESITAS, self::GIZI_BURUK => 'Risiko Tinggi',
            self::PENDEK, self::GIZI_KURANG, self::GIZI_LEBIH, self::RISIKO_BB_LEBIH => 'Perlu Pantau',
            self::GIZI_BAIK => 'Stabil',
            default => self::BELUM_DIUKUR,
        };
    }

    public static function riskScore(?string $status): int
    {
        return match (self::riskLabel($status)) {
            'Risiko Tinggi' => 3,
            'Perlu Pantau' => 2,
            'Stabil' => 1,
            default => 0,
        };
    }

    private static function floatOrNull(mixed $value): ?float
    {
        if ($value === null || $value === '') {
            return null;
        }

        $float = (float) $value;

        return is_finite($float) ? $float : null;
    }
}
