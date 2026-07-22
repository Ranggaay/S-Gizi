<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('consultation_rooms', 'last_shared_measurement_id')) {
            Schema::table('consultation_rooms', function (Blueprint $table) {
                $table->unsignedBigInteger('last_shared_measurement_id')->nullable()->after('unread_count');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('consultation_rooms', 'last_shared_measurement_id')) {
            Schema::table('consultation_rooms', function (Blueprint $table) {
                $table->dropColumn('last_shared_measurement_id');
            });
        }
    }
};
