<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement('ALTER TABLE hasil_gizi MODIFY status_gabungan VARCHAR(255) NOT NULL');
        }
    }

    public function down(): void
    {
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE hasil_gizi MODIFY status_gabungan ENUM('Stunting', 'Wasting', 'Underweight', 'Obesitas', 'Normal') NOT NULL");
        }
    }
};
