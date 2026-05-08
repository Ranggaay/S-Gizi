<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hasil_gizi', function (Blueprint $table) {
            $table->id();
            $table->double('berat');
            $table->double('tinggi');
            $table->double('umur');
            $table->double('z_bbu');
            $table->double('z_tbu');
            $table->double('z_bbtb');
            $table->enum('status_gabungan', ['Stunting', 'Wasting', 'Underweight', 'Obesitas', 'Normal']);
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hasil_gizi');
    }
};
