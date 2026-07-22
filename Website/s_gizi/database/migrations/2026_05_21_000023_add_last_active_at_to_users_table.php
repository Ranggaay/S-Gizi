<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('users', 'last_active_at')) {
            Schema::table('users', function (Blueprint $table) {
                $table->timestamp('last_active_at')->nullable()->after('account_status');
            });
        }

        DB::table('users')
            ->whereNull('last_active_at')
            ->whereNotNull('updated_at')
            ->update(['last_active_at' => DB::raw('updated_at')]);
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'last_active_at')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('last_active_at');
            });
        }
    }
};
