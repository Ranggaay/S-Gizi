<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HasilGizi extends Model
{
    protected $table = 'hasil_gizi';
    public $timestamps = false;

    protected $fillable = [
        'berat',
        'tinggi',
        'umur',
        'z_bbu',
        'z_tbu',
        'z_bbtb',
        'status_gabungan',
        'created_at',
    ];
}
