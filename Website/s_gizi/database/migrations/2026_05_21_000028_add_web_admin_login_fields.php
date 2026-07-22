<?php

use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'last_login_at')) {
                $table->timestamp('last_login_at')->nullable()->after('last_active_at');
            }
            if (! Schema::hasColumn('users', 'last_login_ip')) {
                $table->string('last_login_ip', 45)->nullable()->after('last_login_at');
            }
            if (! Schema::hasColumn('users', 'last_login_user_agent')) {
                $table->text('last_login_user_agent')->nullable()->after('last_login_ip');
            }
        });

        if (! User::query()->whereIn('role', ['super_admin', 'admin_operasional'])->exists()) {
            User::query()->create([
                'name' => 'Admin S-Gizi',
                'email' => 'admin@sgizi.local',
                'phone' => '+620000000001',
                'password' => Hash::make(env('ADMIN_DEFAULT_PASSWORD', 'AdminSgizi123')),
                'role' => 'super_admin',
                'account_status' => 'Aktif',
                'status' => 'aktif',
            ]);
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'last_login_at',
                'last_login_ip',
                'last_login_user_agent',
            ]);
        });
    }
};
