<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ImportWhoLmsFromFlutterJson extends Command
{
    protected $signature = 'lms:import
        {--path= : Path file lms_who_final.json (default: Android/flutter_app/assets/data/lms_who_final.json)}
        {--truncate : Kosongkan tabel WHO LMS sebelum import}';

    protected $description = 'Import data WHO LMS dari JSON milik Flutter ke database (who_lms_age, who_lms_wfl, who_lms_wfh).';

    public function handle(): int
    {
        $defaultPath = base_path('../../Android/flutter_app/assets/data/lms_who_final.json');
        $path = (string) ($this->option('path') ?: $defaultPath);

        if (!is_file($path)) {
            $this->error("File tidak ditemukan: {$path}");
            return self::FAILURE;
        }

        $json = file_get_contents($path);
        if ($json === false) {
            $this->error('Gagal membaca file JSON.');
            return self::FAILURE;
        }

        $decoded = json_decode($json, true);
        if (!is_array($decoded)) {
            $this->error('JSON tidak valid.');
            return self::FAILURE;
        }

        $mapSex = [
            'male' => 'L',
            'female' => 'P',
        ];

        $ageRows = [];
        $wflRows = [];
        $wfhRows = [];

        foreach ($mapSex as $sexKey => $jk) {
            if (!isset($decoded[$sexKey]) || !is_array($decoded[$sexKey])) {
                continue;
            }

            $sexData = $decoded[$sexKey];

            // wfa -> bbu
            $this->collectAgeRows($ageRows, $sexData['wfa'] ?? null, $jk, 'bbu');
            // hfa -> tbu
            $this->collectAgeRows($ageRows, $sexData['hfa'] ?? null, $jk, 'tbu');

            // wfl & wfh
            $this->collectLengthRows($wflRows, $sexData['wfl'] ?? null, $jk);
            $this->collectHeightRows($wfhRows, $sexData['wfh'] ?? null, $jk);
        }

        // TRUNCATE melakukan implicit commit, jadi jangan dibungkus transaction.
        if ((bool) $this->option('truncate')) {
            DB::table('who_lms_age')->truncate();
            DB::table('who_lms_wfl')->truncate();
            DB::table('who_lms_wfh')->truncate();
        }

        DB::transaction(function () use ($ageRows, $wflRows, $wfhRows): void {
            $now = now();
            $chunkInsert = function (string $table, array $rows) use ($now): void {
                $rows = array_map(function (array $r) use ($now) {
                    return $r + ['created_at' => $now, 'updated_at' => $now];
                }, $rows);

                foreach (array_chunk($rows, 1000) as $chunk) {
                    DB::table($table)->upsert(
                        $chunk,
                        $this->uniqueKeys($table),
                        ['l', 'm', 's', 'updated_at']
                    );
                }
            };

            $chunkInsert('who_lms_age', $ageRows);
            $chunkInsert('who_lms_wfl', $wflRows);
            $chunkInsert('who_lms_wfh', $wfhRows);
        });

        $this->info('Import selesai.');
        $this->line('Ringkasan:');
        $this->line('- who_lms_age: '.count($ageRows));
        $this->line('- who_lms_wfl: '.count($wflRows));
        $this->line('- who_lms_wfh: '.count($wfhRows));

        return self::SUCCESS;
    }

    private function collectAgeRows(array &$out, mixed $data, string $jk, string $indikator): void
    {
        if (!is_array($data)) {
            return;
        }

        foreach ($data as $umurStr => $lms) {
            if (!is_array($lms)) {
                continue;
            }

            $out[] = [
                'indikator' => $indikator,
                'jenis_kelamin' => $jk,
                'umur_bulan' => (float) $umurStr,
                'l' => (float) ($lms['L'] ?? 0),
                'm' => (float) ($lms['M'] ?? 0),
                's' => (float) ($lms['S'] ?? 0),
            ];
        }
    }

    private function collectLengthRows(array &$out, mixed $data, string $jk): void
    {
        if (!is_array($data)) {
            return;
        }

        foreach ($data as $panjangStr => $lms) {
            if (!is_array($lms)) {
                continue;
            }

            $out[] = [
                'jenis_kelamin' => $jk,
                'panjang' => (float) $panjangStr,
                'l' => (float) ($lms['L'] ?? 0),
                'm' => (float) ($lms['M'] ?? 0),
                's' => (float) ($lms['S'] ?? 0),
            ];
        }
    }

    private function collectHeightRows(array &$out, mixed $data, string $jk): void
    {
        if (!is_array($data)) {
            return;
        }

        foreach ($data as $tinggiStr => $lms) {
            if (!is_array($lms)) {
                continue;
            }

            $out[] = [
                'jenis_kelamin' => $jk,
                'tinggi' => (float) $tinggiStr,
                'l' => (float) ($lms['L'] ?? 0),
                'm' => (float) ($lms['M'] ?? 0),
                's' => (float) ($lms['S'] ?? 0),
            ];
        }
    }

    /**
     * @return array<int, string>
     */
    private function uniqueKeys(string $table): array
    {
        return match ($table) {
            'who_lms_age' => ['indikator', 'jenis_kelamin', 'umur_bulan'],
            'who_lms_wfl' => ['jenis_kelamin', 'panjang'],
            'who_lms_wfh' => ['jenis_kelamin', 'tinggi'],
            default => [],
        };
    }
}

