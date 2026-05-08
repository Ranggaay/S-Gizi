<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('who_lms_wfl', function (Blueprint $table) {
            $table->id();
            $table->double('panjang');
            $table->enum('jk', ['L', 'P']);
            $table->double('L');
            $table->double('M');
            $table->double('S');

            $table->unique(['panjang', 'jk'], 'who_lms_wfl_panjang_jk_unique');
            $table->index('jk', 'who_lms_wfl_jk_index');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('who_lms_wfl');
    }
};

