<?php

namespace Database\Seeders;

use App\Models\Child;
use App\Models\Measurement;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class ParentDemoSeeder extends Seeder
{
    public function run(): void
    {
        $parents = [
            ['Affan Ardiansyah', 'affan.ardiansyah@sgizi.test', '+6281294583761', 'Amar Rosyidin', 'L', 36, 18.0, 95.0, -0.7, -0.4, -0.3, 'Gizi Baik'],
            ['Dwi Nur Yanti', 'dwi.nuryanti@sgizi.test', '+6281294583762', 'M. Rosid', 'L', 39, 16.2, 96.0, -1.1, -0.8, -0.5, 'Gizi Baik'],
            ['Eko Adi Nugroho', 'eko.adi@sgizi.test', '+6281294583763', 'Vira', 'P', 35, 20.0, 95.0, 1.6, -0.2, 2.4, 'Gizi Lebih'],
            ['Risa Umami', 'risa.umami@sgizi.test', '+6281294583764', 'M. Elzio Abrori', 'L', 42, 13.5, 91.0, -2.2, -2.4, -1.0, 'Pendek'],
            ['Siti Maulida', 'siti.maulida@sgizi.test', '+6281294583765', 'Kesya', 'P', 39, 10.3, 85.0, -2.8, -3.2, -1.6, 'Sangat Pendek'],
            ['Nur Aisyah', 'nur.aisyah@sgizi.test', '+6281294583766', 'Nabila', 'P', 30, 14.8, 89.0, 0.3, 0.2, 0.5, 'Gizi Baik'],
            ['Bambang Prasetyo', 'bambang.prasetyo@sgizi.test', '+6281294583767', 'Raka', 'L', 48, 23.0, 101.0, 2.1, -0.1, 3.1, 'Obesitas'],
            ['Lina Marlina', 'lina.marlina@sgizi.test', '+6281294583768', 'Aqila', 'P', 27, 11.7, 86.0, -1.4, -1.0, -0.6, 'Gizi Baik'],
            ['Agus Salim', 'agus.salim@sgizi.test', '+6281294583769', 'Fathan', 'L', 33, 12.0, 88.0, -2.4, -1.7, -1.8, 'Gizi Kurang'],
            ['Maya Safitri', 'maya.safitri@sgizi.test', '+6281294583770', 'Zahra', 'P', 45, 18.4, 99.0, 0.8, -0.3, 1.0, 'Gizi Baik'],
            ['Hendra Wijaya', 'hendra.wijaya@sgizi.test', '+6281294583771', 'Daffa', 'L', 51, 17.1, 99.0, -0.8, -2.1, -0.2, 'Pendek'],
            ['Putri Ramadhani', 'putri.ramadhani@sgizi.test', '+6281294583772', 'Kirana', 'P', 24, 14.4, 82.0, 1.5, 0.1, 1.9, 'Risiko Berat Badan Lebih'],
        ];

        foreach ($parents as $index => [$name, $email, $phone, $childName, $gender, $ageMonths, $weight, $height, $zBbu, $zTbu, $zBbtb, $status]) {
            $parent = User::query()->updateOrCreate(
                ['phone' => $phone],
                [
                    'name' => $name,
                    'email' => $email,
                    'role' => 'orang_tua',
                    'account_status' => 'Aktif',
                    'parent_gender' => $index % 2 === 0 ? 'ayah' : 'bunda',
                    'password' => Hash::make('password123'),
                    'last_active_at' => now()->subHours($index + 1),
                ],
            );

            $child = Child::query()->updateOrCreate(
                ['user_id' => $parent->id, 'nama' => $childName],
                [
                    'nama_anak' => $childName,
                    'tanggal_lahir' => now()->subMonths($ageMonths)->toDateString(),
                    'jenis_kelamin' => $gender,
                ],
            );

            Measurement::query()->updateOrCreate(
                ['child_id' => $child->id, 'tanggal_ukur' => now()->subDays($index % 7)->toDateString()],
                [
                    'berat' => $weight,
                    'tinggi' => $height,
                    'cara_ukur' => 'standing',
                    'umur_bulan' => $ageMonths,
                    'z_bbu' => $zBbu,
                    'z_tbu' => $zTbu,
                    'z_bbtb' => $zBbtb,
                    'kategori' => [
                        'BB/U' => $zBbu,
                        'TB/U' => $zTbu,
                        'BB/TB' => $zBbtb,
                    ],
                    'status_gabungan' => $status,
                    'created_at' => now()->subHours($index + 1),
                ],
            );
        }
    }
}
