<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'tanggal_lahir')) {
            Schema::table('users', function (Blueprint $table) {
                $table->date('tanggal_lahir')->nullable()->after('parent_gender');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'tanggal_lahir')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('tanggal_lahir');
            });
        }
    }
};
