<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('makanan', function (Blueprint $table) {
            $table->id();
            $table->string('nama');
            $table->integer('usia_min');
            $table->integer('usia_max');
            $table->enum('kategori_status', ['Stunting', 'Wasting', 'Underweight', 'Obesitas', 'Normal']);
            $table->integer('kalori');
            $table->integer('protein');
            $table->integer('lemak');
            $table->integer('karbohidrat');
            $table->text('alasan');
            $table->timestamps();

            $table->index(['kategori_status', 'usia_min', 'usia_max'], 'makanan_kat_usia_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('makanan');
    }
};

