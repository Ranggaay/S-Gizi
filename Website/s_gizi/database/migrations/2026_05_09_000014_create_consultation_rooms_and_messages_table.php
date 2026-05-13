<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('consultation_rooms')) {
            Schema::create('consultation_rooms', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
                $table->string('expert_id', 80);
                $table->string('expert_name', 150);
                $table->string('specialization', 150)->nullable();
                $table->string('asset_image')->nullable();
                $table->boolean('online')->default(false);
                $table->string('status', 32)->default('aktif');
                $table->text('last_message')->nullable();
                $table->timestamp('last_message_at')->nullable();
                $table->unsignedInteger('unread_count')->default(0);
                $table->timestamps();
                $table->unique(['user_id', 'child_id', 'expert_id']);
            });
        }

        if (!Schema::hasTable('consultation_messages')) {
            Schema::create('consultation_messages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('room_id')->constrained('consultation_rooms')->cascadeOnDelete();
                $table->string('sender_type', 32)->default('parent');
                $table->text('message');
                $table->boolean('is_read')->default(false);
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('consultation_messages');
        Schema::dropIfExists('consultation_rooms');
    }
};

