<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('nutritionist_notifications')) {
            Schema::create('nutritionist_notifications', function (Blueprint $table) {
                $table->id();
                $table->foreignId('nutritionist_id')->constrained('nutritionists')->cascadeOnDelete();
                $table->foreignId('consultation_room_id')->nullable()->constrained('consultation_rooms')->nullOnDelete();
                $table->foreignId('child_id')->nullable()->constrained('children')->nullOnDelete();
                $table->string('type', 60);
                $table->string('title');
                $table->text('description')->nullable();
                $table->string('priority', 40)->default('Normal');
                $table->boolean('is_read')->default(false);
                $table->timestamps();
                $table->index(['nutritionist_id', 'is_read', 'priority'], 'nutri_notifications_filter_index');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('nutritionist_notifications');
    }
};
