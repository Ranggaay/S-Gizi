<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GrowthRecord extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'child_id',
        'tinggi_badan',
        'berat_badan',
        'umur_dalam_bulan',
        'z_score',
        'status_gizi',
        'created_at',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }
}
