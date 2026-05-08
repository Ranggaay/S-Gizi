<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class LMSSeeder extends Seeder
{
    public function run(): void
    {
        $path = base_path('../../Android/flutter_app/assets/data/lms_who_final.json');
        if (!is_file($path)) {
            throw new \RuntimeException("File LMS Flutter tidak ditemukan: {$path}");
        }

        $decoded = json_decode((string) file_get_contents($path), true);
        if (!is_array($decoded)) {
            throw new \RuntimeException('JSON LMS tidak valid.');
        }

        $mapSex = ['male' => 'L', 'female' => 'P'];

        $ageRows = [];
        $wflRows = [];
        $wfhRows = [];

        foreach ($mapSex as $sexKey => $jk) {
            $sexData = $decoded[$sexKey] ?? null;
            if (!is_array($sexData)) continue;

            // wfa -> bbu, hfa -> tbu
            foreach (($sexData['wfa'] ?? []) as $umur => $lms) {
                if (!is_array($lms)) continue;
                $ageRows[] = [
                    'umur' => (int) $umur,
                    'jk' => $jk,
                    'indikator' => 'bbu',
                    'L' => (float) ($lms['L'] ?? 0),
                    'M' => (float) ($lms['M'] ?? 0),
                    'S' => (float) ($lms['S'] ?? 0),
                ];
            }
            foreach (($sexData['hfa'] ?? []) as $umur => $lms) {
                if (!is_array($lms)) continue;
                $ageRows[] = [
                    'umur' => (int) $umur,
                    'jk' => $jk,
                    'indikator' => 'tbu',
                    'L' => (float) ($lms['L'] ?? 0),
                    'M' => (float) ($lms['M'] ?? 0),
                    'S' => (float) ($lms['S'] ?? 0),
                ];
            }

            foreach (($sexData['wfl'] ?? []) as $panjang => $lms) {
                if (!is_array($lms)) continue;
                $wflRows[] = [
                    'panjang' => (float) $panjang,
                    'jk' => $jk,
                    'L' => (float) ($lms['L'] ?? 0),
                    'M' => (float) ($lms['M'] ?? 0),
                    'S' => (float) ($lms['S'] ?? 0),
                ];
            }

            foreach (($sexData['wfh'] ?? []) as $tinggi => $lms) {
                if (!is_array($lms)) continue;
                $wfhRows[] = [
                    'tinggi' => (float) $tinggi,
                    'jk' => $jk,
                    'L' => (float) ($lms['L'] ?? 0),
                    'M' => (float) ($lms['M'] ?? 0),
                    'S' => (float) ($lms['S'] ?? 0),
                ];
            }
        }

        DB::table('who_lms_age')->truncate();
        DB::table('who_lms_wfl')->truncate();
        DB::table('who_lms_wfh')->truncate();

        foreach (array_chunk($ageRows, 1000) as $chunk) {
            DB::table('who_lms_age')->insert($chunk);
        }
        foreach (array_chunk($wflRows, 1000) as $chunk) {
            DB::table('who_lms_wfl')->insert($chunk);
        }
        foreach (array_chunk($wfhRows, 1000) as $chunk) {
            DB::table('who_lms_wfh')->insert($chunk);
        }
    }
}

