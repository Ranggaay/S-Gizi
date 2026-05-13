<?php

namespace Database\Seeders;

use App\Models\Makanan;
use Illuminate\Database\Seeder;

class MakananSeeder extends Seeder
{
    public function run(): void
    {
        $rows = [
            [
                'nama' => 'Nasi + Ayam + Sayur',
                'usia_min' => 6,
                'usia_max' => 60,
                'kategori_status' => 'Stunting',
                'kalori' => 250,
                'protein' => 15,
                'lemak' => 8,
                'karbohidrat' => 30,
                'alasan' => 'Tinggi protein untuk mendukung pertumbuhan',
            ],
            [
                'nama' => 'Bubur kacang hijau + telur',
                'usia_min' => 6,
                'usia_max' => 60,
                'kategori_status' => 'Wasting',
                'kalori' => 300,
                'protein' => 14,
                'lemak' => 10,
                'karbohidrat' => 38,
                'alasan' => 'Padat energi dan protein untuk mengejar berat badan',
            ],
            [
                'nama' => 'Nasi + ikan + tempe + sayur',
                'usia_min' => 12,
                'usia_max' => 60,
                'kategori_status' => 'Underweight',
                'kalori' => 280,
                'protein' => 16,
                'lemak' => 9,
                'karbohidrat' => 34,
                'alasan' => 'Meningkatkan asupan energi dan protein harian',
            ],
            [
                'nama' => 'Nasi merah + ayam kukus + sayur',
                'usia_min' => 12,
                'usia_max' => 60,
                'kategori_status' => 'Obesitas',
                'kalori' => 220,
                'protein' => 18,
                'lemak' => 6,
                'karbohidrat' => 24,
                'alasan' => 'Menu seimbang dengan kontrol kalori dan lemak',
            ],
            [
                'nama' => 'Menu seimbang (karbo + protein + sayur)',
                'usia_min' => 6,
                'usia_max' => 60,
                'kategori_status' => 'Normal',
                'kalori' => 240,
                'protein' => 12,
                'lemak' => 7,
                'karbohidrat' => 32,
                'alasan' => 'Menjaga status gizi tetap baik sesuai kebutuhan usia',
            ],
        ];

        foreach ($rows as $r) {
            Makanan::query()->updateOrCreate(
                [
                    'nama' => $r['nama'],
                    'kategori_status' => $r['kategori_status'],
                ],
                $r
            );
        }
    }
}

