<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class NutritionistSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::query()->updateOrCreate(
            ['phone' => '+6281234567000'],
            [
                'name' => 'Rina Kurnia',
                'email' => 'rina.gizi@sgizi.id',
                'role' => 'ahli_gizi',
                'account_status' => 'Aktif',
                'status' => 'aktif',
                'password' => 'password123',
                'parent_gender' => 'perempuan',
            ],
        );

        $user->nutritionist()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'expert_id' => 'exp-2',
                'title' => 'S.Gz, M.Gz',
                'specialization' => 'Stunting',
                'experience' => '6 tahun pengalaman',
                'experience_years' => 6,
                'bio' => 'Berpengalaman mendampingi keluarga dalam pencegahan stunting dan pemantauan pertumbuhan balita.',
                'str_sip' => 'STR-GZ-2026-0182',
                'is_online' => true,
                'is_available' => true,
                'max_consultation' => 25,
            ],
        );
    }
}
