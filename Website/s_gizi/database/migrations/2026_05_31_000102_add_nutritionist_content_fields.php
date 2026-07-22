<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('makanan', function (Blueprint $table) {
            if (! Schema::hasColumn('makanan', 'created_by')) {
                $table->foreignId('created_by')->nullable()->after('id')->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('makanan', 'verified_by')) {
                $table->foreignId('verified_by')->nullable()->after('status_menu')->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('makanan', 'verified_at')) {
                $table->timestamp('verified_at')->nullable()->after('verified_by');
            }
            if (! Schema::hasColumn('makanan', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('verified_at');
            }
        });

        Schema::table('articles', function (Blueprint $table) {
            if (! Schema::hasColumn('articles', 'created_by')) {
                $table->foreignId('created_by')->nullable()->after('id')->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('articles', 'verified_by')) {
                $table->foreignId('verified_by')->nullable()->after('status')->constrained('users')->nullOnDelete();
            }
            if (! Schema::hasColumn('articles', 'verified_at')) {
                $table->timestamp('verified_at')->nullable()->after('verified_by');
            }
            if (! Schema::hasColumn('articles', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('verified_at');
            }
        });
    }

    public function down(): void
    {
        Schema::table('makanan', function (Blueprint $table) {
            foreach (['rejection_reason', 'verified_at', 'verified_by', 'created_by'] as $column) {
                if (Schema::hasColumn('makanan', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('articles', function (Blueprint $table) {
            foreach (['rejection_reason', 'verified_at', 'verified_by', 'created_by'] as $column) {
                if (Schema::hasColumn('articles', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
