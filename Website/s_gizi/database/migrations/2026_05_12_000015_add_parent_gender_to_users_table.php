<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'parent_gender')) {
            Schema::table('users', function (Blueprint $table) {
                $table->string('parent_gender', 16)->nullable()->after('role');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('users', 'parent_gender')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('parent_gender');
            });
        }
    }
};
