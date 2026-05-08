<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'phone')) {
                $table->string('phone')->nullable()->unique()->after('email');
            }
            if (!Schema::hasColumn('users', 'otp_code')) {
                $table->string('otp_code')->nullable()->after('phone');
            }
            if (!Schema::hasColumn('users', 'otp_expires_at')) {
                $table->timestamp('otp_expires_at')->nullable()->after('otp_code');
            }
            if (!Schema::hasColumn('users', 'api_token')) {
                $table->string('api_token', 100)->nullable()->unique()->after('remember_token');
            }
        });

        Schema::table('children', function (Blueprint $table) {
            if (!Schema::hasColumn('children', 'user_id')) {
                $table->foreignId('user_id')->nullable()->after('id')->constrained('users')->nullOnDelete();
            }
        });

        Schema::table('measurements', function (Blueprint $table) {
            if (!Schema::hasColumn('measurements', 'cara_ukur')) {
                $table->string('cara_ukur')->default('standing')->after('tanggal_ukur');
            }
            if (!Schema::hasColumn('measurements', 'kategori')) {
                $table->json('kategori')->nullable()->after('z_bbtb');
            }
        });
    }

    public function down(): void
    {
        Schema::table('measurements', function (Blueprint $table) {
            if (Schema::hasColumn('measurements', 'kategori')) {
                $table->dropColumn('kategori');
            }
            if (Schema::hasColumn('measurements', 'cara_ukur')) {
                $table->dropColumn('cara_ukur');
            }
        });

        Schema::table('children', function (Blueprint $table) {
            if (Schema::hasColumn('children', 'user_id')) {
                $table->dropConstrainedForeignId('user_id');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            foreach (['api_token', 'otp_expires_at', 'otp_code', 'phone'] as $column) {
                if (Schema::hasColumn('users', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
