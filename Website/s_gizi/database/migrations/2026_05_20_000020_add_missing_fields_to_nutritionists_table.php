<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('nutritionists')) {
            return;
        }

        Schema::table('nutritionists', function (Blueprint $table) {
            if (!Schema::hasColumn('nutritionists', 'expert_id')) {
                $table->string('expert_id', 80)->nullable()->unique()->after('user_id');
            }
            if (!Schema::hasColumn('nutritionists', 'specialization')) {
                $table->string('specialization')->default('Spesialis Gizi Anak')->after('expert_id');
            }
            if (!Schema::hasColumn('nutritionists', 'experience')) {
                $table->string('experience')->nullable()->after('specialization');
            }
            if (!Schema::hasColumn('nutritionists', 'str_sip')) {
                $table->string('str_sip')->nullable()->after('experience');
            }
            if (!Schema::hasColumn('nutritionists', 'is_online')) {
                $table->boolean('is_online')->default(false)->after('str_sip');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('nutritionists')) {
            return;
        }

        Schema::table('nutritionists', function (Blueprint $table) {
            foreach (['is_online', 'str_sip', 'experience', 'specialization', 'expert_id'] as $column) {
                if (Schema::hasColumn('nutritionists', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
