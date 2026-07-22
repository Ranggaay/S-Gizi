<?php

namespace App\Services;

class StatusGiziService
{
    /**
     * Prioritas penentuan status sesuai permintaan:
     * Status Indonesia sesuai Permenkes No. 2 Tahun 2020.
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
            return 'Sangat Pendek';
        }
        if ($zTbu < -2.0 && $zBbtb > 1.0) {
            return 'Pendek + Risiko Berat Badan Lebih';
        }
        if ($zTbu < -2.0) {
            return 'Pendek';
        }

        // Aturan BB/TB (gizi lebih)
        if ($zBbtb > 3.0) {
            return 'Obesitas';
        }
        if ($zBbtb > 2.0) {
            return 'Gizi Lebih';
        }
        if ($zBbtb > 1.0) {
            return 'Risiko Berat Badan Lebih';
        }

        // Aturan BB/U
        if ($zBbu < -3.0) {
            return 'Berat Badan Sangat Kurang';
        }
        if ($zBbu < -2.0) {
            return 'Berat Badan Kurang';
        }

        return 'Gizi Baik';
    }
}
