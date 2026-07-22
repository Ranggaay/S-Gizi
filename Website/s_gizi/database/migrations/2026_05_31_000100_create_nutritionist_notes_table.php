<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('nutritionist_notes')) {
            Schema::create('nutritionist_notes', function (Blueprint $table) {
                $table->id();
                $table->foreignId('consultation_room_id')->constrained('consultation_rooms')->cascadeOnDelete();
                $table->foreignId('nutritionist_id')->constrained('nutritionists')->cascadeOnDelete();
                $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
                $table->string('category', 80);
                $table->text('note');
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('nutritionist_notes');
    }
};
