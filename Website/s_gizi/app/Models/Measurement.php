<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Measurement extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $fillable = [
        'child_id',
        'berat',
        'tinggi',
        'tanggal_ukur',
        'cara_ukur',
        'umur_bulan',
        'z_bbu',
        'z_tbu',
        'z_bbtb',
        'kategori',
        'status_gabungan',
        'created_at',
    ];

    protected $casts = [
        'tanggal_ukur' => 'date',
        'kategori' => 'array',
        'created_at' => 'datetime',
    ];

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class, 'child_id');
    }
}

