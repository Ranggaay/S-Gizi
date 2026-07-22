<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'status')) {
                $table->string('status', 24)->default('aktif')->after('account_status');
            }
            if (! Schema::hasColumn('users', 'avatar')) {
                $table->string('avatar')->nullable()->after('status');
            }
        });

        Schema::table('nutritionists', function (Blueprint $table) {
            if (! Schema::hasColumn('nutritionists', 'title')) {
                $table->string('title', 80)->nullable()->after('expert_id');
            }
            if (! Schema::hasColumn('nutritionists', 'experience_years')) {
                $table->unsignedTinyInteger('experience_years')->default(0)->after('experience');
            }
            if (! Schema::hasColumn('nutritionists', 'bio')) {
                $table->text('bio')->nullable()->after('experience_years');
            }
            if (! Schema::hasColumn('nutritionists', 'is_available')) {
                $table->boolean('is_available')->default(true)->after('is_online');
            }
            if (! Schema::hasColumn('nutritionists', 'max_consultation')) {
                $table->unsignedSmallInteger('max_consultation')->default(25)->after('is_available');
            }
            if (! Schema::hasColumn('nutritionists', 'last_active_at')) {
                $table->timestamp('last_active_at')->nullable()->after('max_consultation');
            }
        });

        DB::table('users')
            ->whereIn('role', ['nutritionist', 'ahli gizi'])
            ->update(['role' => 'ahli_gizi']);

        DB::table('users')
            ->whereNull('status')
            ->update(['status' => DB::raw("CASE WHEN account_status = 'Nonaktif' THEN 'nonaktif' ELSE 'aktif' END")]);
    }

    public function down(): void
    {
        Schema::table('nutritionists', function (Blueprint $table) {
            foreach (['last_active_at', 'max_consultation', 'is_available', 'bio', 'experience_years', 'title'] as $column) {
                if (Schema::hasColumn('nutritionists', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('users', function (Blueprint $table) {
            foreach (['avatar', 'status'] as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
