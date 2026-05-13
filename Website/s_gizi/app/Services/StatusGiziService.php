<?php

namespace App\Services;

class StatusGiziService
{
    /**
     * Prioritas penentuan status sesuai permintaan:
     * 1) BB/TB (wasting/overweight)
     * 2) TB/U (stunting)
     * 3) BB/U (underweight)
     */
    public function statusGabungan(float $zBbtb, float $zTbu, float $zBbu): string
    {
        // Aturan BB/TB (prioritas wasting & gizi lebih)
        if ($zBbtb < -3.0) {
            return 'Gizi Buruk';
        }
        if ($zBbtb < -2.0) {
            return 'Gizi Kurang';
        }

        // Aturan TB/U (stunting)
        if ($zTbu < -3.0) {
            return 'Stunting Berat';
        }
        if ($zTbu < -2.0 && $zBbtb > 1.0) {
            return 'Stunting + Risiko Gizi Lebih';
        }
        if ($zTbu < -2.0) {
            return 'Stunting';
        }

        // Aturan BB/TB (gizi lebih)
        if ($zBbtb > 3.0) {
            return 'Obesitas';
        }
        if ($zBbtb > 2.0) {
            return 'Gizi Lebih';
        }
        if ($zBbtb > 1.0) {
            return 'Risiko Gizi Lebih';
        }

        // Aturan BB/U (underweight)
        if ($zBbu < -2.0) {
            return 'Gizi Kurang';
        }

        return 'Normal';
    }
}

