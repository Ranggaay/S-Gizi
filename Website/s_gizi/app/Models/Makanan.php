<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Makanan extends Model
{
    use HasFactory;

    protected $table = 'makanan';

    protected $fillable = [
        'nama',
        'created_by',
        'thumbnail',
        'usia_min',
        'usia_max',
        'usia_kategori',
        'kategori_status',
        'badges',
        'status_menu',
        'verified_by',
        'verified_at',
        'rejection_reason',
        'prioritas_menu',
        'kalori',
        'protein',
        'lemak',
        'karbohidrat',
        'serat',
        'gula',
        'alasan',
        'bahan',
        'cara_memasak',
    ];

    protected $casts = [
        'badges' => 'array',
        'verified_at' => 'datetime',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}
