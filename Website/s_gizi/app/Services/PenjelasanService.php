<?php

namespace App\Services;

class PenjelasanService
{
    public function penjelasan(string $statusGabungan): string
    {
        return match ($statusGabungan) {
            'Gizi Buruk' => 'BB/TB sangat rendah. Perlu peningkatan asupan energi-protein, pemantauan ketat, dan evaluasi kemungkinan infeksi/penyakit penyerta.',
            'Gizi Kurang' => 'Berat badan relatif kurang. Fokus pada menu padat energi dan protein, frekuensi makan cukup, dan pemantauan rutin.',
            'Sangat Pendek' => 'TB/U sangat rendah. Perlu perbaikan kualitas asupan jangka panjang (protein hewani, mikronutrien) dan pantau tumbuh kembang.',
            'Pendek' => 'TB/U rendah. Tingkatkan kualitas asupan (protein hewani, zat besi, zinc) dan pastikan pola makan serta kebersihan baik.',
            'Pendek + Risiko Berat Badan Lebih' => 'Tinggi badan rendah tetapi BB/TB mulai tinggi. Perbaiki kualitas makanan tanpa berlebihan kalori kosong, fokus protein dan mikronutrien.',
            'Obesitas' => 'BB/TB sangat tinggi. Perlu pengaturan porsi, batasi gula/lemak berlebih, dan dorong aktivitas fisik sesuai usia.',
            'Gizi Lebih' => 'BB/TB tinggi. Perhatikan porsi dan kualitas makanan, kurangi minuman manis dan snack tinggi kalori.',
            'Risiko Berat Badan Lebih' => 'BB/TB mulai meningkat. Jaga pola makan seimbang dan porsi sesuai kebutuhan agar tidak berkembang menjadi gizi lebih.',
            default => 'Status gizi dalam batas normal. Pertahankan pola makan seimbang (karbo, protein, sayur-buah) dan lakukan pemantauan berkala.',
        };
    }
}
