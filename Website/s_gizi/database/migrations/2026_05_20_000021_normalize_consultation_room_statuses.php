<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('consultation_rooms')->whereIn('status', ['aktif', 'menunggu'])->update(['status' => 'active']);
        DB::table('consultation_rooms')->where('status', 'selesai')->update(['status' => 'closed']);
    }

    public function down(): void
    {
        DB::table('consultation_rooms')->where('status', 'active')->update(['status' => 'aktif']);
        DB::table('consultation_rooms')->where('status', 'closed')->update(['status' => 'selesai']);
    }
};
