<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('nutritionists')) {
            Schema::create('nutritionists', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
                $table->string('expert_id', 80)->unique();
                $table->string('specialization')->default('Spesialis Gizi Anak');
                $table->string('experience')->nullable();
                $table->string('str_sip')->nullable();
                $table->boolean('is_online')->default(false);
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('nutritionists');
    }
};
