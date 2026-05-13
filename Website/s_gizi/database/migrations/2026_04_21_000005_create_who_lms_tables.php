<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('who_lms_age', function (Blueprint $table) {
            $table->id();
            $table->integer('umur');
            $table->enum('jk', ['L', 'P']);
            $table->enum('indikator', ['bbu', 'tbu']);
            $table->double('L');
            $table->double('M');
            $table->double('S');

            $table->unique(['umur', 'jk', 'indikator'], 'who_lms_age_umur_jk_indikator_unique');
            $table->index(['jk', 'indikator'], 'who_lms_age_jk_indikator_index');
        });

        Schema::create('who_lms_wfh', function (Blueprint $table) {
            $table->id();
            $table->double('tinggi');
            $table->enum('jk', ['L', 'P']);
            $table->double('L');
            $table->double('M');
            $table->double('S');

            $table->unique(['tinggi', 'jk'], 'who_lms_wfh_tinggi_jk_unique');
            $table->index('jk', 'who_lms_wfh_jk_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('who_lms_wfh');
        Schema::dropIfExists('who_lms_age');
    }
};

