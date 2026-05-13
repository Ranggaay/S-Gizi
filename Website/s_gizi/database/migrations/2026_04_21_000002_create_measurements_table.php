<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('measurements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();

            $table->double('berat'); // kg
            $table->double('tinggi'); // cm
            $table->date('tanggal_ukur');

            $table->double('umur_bulan'); // desimal

            $table->double('z_bbu')->nullable();
            $table->double('z_tbu')->nullable();
            $table->double('z_bbtb')->nullable();

            $table->string('status_gabungan');
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('measurements');
    }
};

