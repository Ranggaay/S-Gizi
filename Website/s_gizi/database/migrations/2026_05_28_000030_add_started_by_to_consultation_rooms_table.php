<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('consultation_rooms', 'started_by')) {
            Schema::table('consultation_rooms', function (Blueprint $table) {
                $table->string('started_by', 32)->default('parent')->after('status');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('consultation_rooms', 'started_by')) {
            Schema::table('consultation_rooms', function (Blueprint $table) {
                $table->dropColumn('started_by');
            });
        }
    }
};
