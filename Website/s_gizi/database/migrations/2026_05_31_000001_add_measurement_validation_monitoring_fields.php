<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('measurements', function (Blueprint $table) {
            if (! Schema::hasColumn('measurements', 'validation_status')) {
                $table->string('validation_status')->default('valid');
            }

            if (! Schema::hasColumn('measurements', 'validation_note')) {
                $table->text('validation_note')->nullable();
            }

            if (! Schema::hasColumn('measurements', 'monitoring_status')) {
                $table->string('monitoring_status')->default('normal');
            }

            if (! Schema::hasColumn('measurements', 'is_confirmed_by_parent')) {
                $table->boolean('is_confirmed_by_parent')->default(false);
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
        });
    }
};
