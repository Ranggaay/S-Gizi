<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'role')) {
                $table->string('role')->default('orang_tua')->after('phone');
            }
        });

        Schema::table('children', function (Blueprint $table) {
            if (!Schema::hasColumn('children', 'nama_anak')) {
                $table->string('nama_anak')->nullable()->after('user_id');
            }
        });

        DB::table('children')
            ->whereNull('nama_anak')
            ->update(['nama_anak' => DB::raw('nama')]);

        Schema::create('growth_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('child_id')->constrained('children')->cascadeOnDelete();
            $table->double('tinggi_badan');
            $table->double('berat_badan');
            $table->double('umur_dalam_bulan');
            $table->double('z_score');
            $table->string('status_gizi');
            $table->timestamp('created_at')->useCurrent();

            $table->index(['child_id', 'created_at']);
            $table->index('status_gizi');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('growth_records');

        Schema::table('children', function (Blueprint $table) {
            if (Schema::hasColumn('children', 'nama_anak')) {
                $table->dropColumn('nama_anak');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'role')) {
                $table->dropColumn('role');
            }
        });
    }
};
