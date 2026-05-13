<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('food_conditions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('food_id')->constrained('foods')->cascadeOnDelete();
            $table->string('status_gizi'); // contoh: "Stunting tanpa Wasting"
            $table->timestamps();

            $table->unique(['food_id', 'status_gizi']);
            $table->index('status_gizi');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('food_conditions');
    }
};

