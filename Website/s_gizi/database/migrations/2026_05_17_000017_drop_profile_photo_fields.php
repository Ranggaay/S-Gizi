<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('users', 'photo_url')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('photo_url');
            });
        }

        if (Schema::hasColumn('children', 'photo_url')) {
            Schema::table('children', function (Blueprint $table) {
                $table->dropColumn('photo_url');
            });
        }
    }

    public function down(): void
    {
        if (!Schema::hasColumn('users', 'photo_url')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('photo_url', 2048)->nullable()->after('tanggal_lahir');
            });
        }

        if (!Schema::hasColumn('children', 'photo_url')) {
            Schema::table('children', function (Blueprint $table) {
                $table->string('photo_url', 2048)->nullable()->after('jenis_kelamin');
            });
        }
    }
};
