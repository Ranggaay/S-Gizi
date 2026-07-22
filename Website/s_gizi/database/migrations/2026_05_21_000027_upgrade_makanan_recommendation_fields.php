<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('makanan', function (Blueprint $table) {
            $table->string('kategori_status', 100)->change();
            $table->string('thumbnail')->nullable()->after('nama');
            $table->integer('serat')->default(0)->after('karbohidrat');
            $table->integer('gula')->default(0)->after('serat');
            $table->string('usia_kategori', 40)->nullable()->after('usia_max');
            $table->json('badges')->nullable()->after('kategori_status');
            $table->string('status_menu', 30)->default('Published')->after('badges');
            $table->string('prioritas_menu', 40)->default('Menu Utama')->after('status_menu');
            $table->text('bahan')->nullable()->after('alasan');
            $table->text('cara_memasak')->nullable()->after('bahan');
        });
    }

    public function down(): void
    {
        Schema::table('makanan', function (Blueprint $table) {
            $table->dropColumn([
                'thumbnail',
                'serat',
                'gula',
                'usia_kategori',
                'badges',
                'status_menu',
                'prioritas_menu',
                'bahan',
                'cara_memasak',
            ]);
        });
    }
};
