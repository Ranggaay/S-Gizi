<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('measurements', function (Blueprint $table) {
            if (! Schema::hasColumn('measurements', 'is_anomaly')) {
                $table->boolean('is_anomaly')->default(false)->after('status_gabungan');
            }
            if (! Schema::hasColumn('measurements', 'data_status')) {
                $table->string('data_status')->default('normal')->after('is_anomaly');
            }
            if (! Schema::hasColumn('measurements', 'validation_status')) {
                $table->string('validation_status')->default('valid')->after('data_status');
            }
            if (! Schema::hasColumn('measurements', 'validation_note')) {
                $table->text('validation_note')->nullable()->after('validation_status');
            }
            if (! Schema::hasColumn('measurements', 'monitoring_status')) {
                $table->string('monitoring_status')->default('normal')->after('validation_note');
            }
            if (! Schema::hasColumn('measurements', 'is_confirmed_by_parent')) {
                $table->boolean('is_confirmed_by_parent')->default(false)->after('monitoring_status');
            }
        });
    }

    public function down(): void
    {
        Schema::table('measurements', function (Blueprint $table) {
            if (Schema::hasColumn('measurements', 'is_confirmed_by_parent')) {
                $table->dropColumn('is_confirmed_by_parent');
            }
            if (Schema::hasColumn('measurements', 'monitoring_status')) {
                $table->dropColumn('monitoring_status');
            }
            if (Schema::hasColumn('measurements', 'validation_note')) {
                $table->dropColumn('validation_note');
            }
            if (Schema::hasColumn('measurements', 'validation_status')) {
                $table->dropColumn('validation_status');
            }
            if (Schema::hasColumn('measurements', 'data_status')) {
                $table->dropColumn('data_status');
            }
            if (Schema::hasColumn('measurements', 'is_anomaly')) {
                $table->dropColumn('is_anomaly');
            }
        });
    }
};
