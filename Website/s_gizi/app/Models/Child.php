<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Child extends Model
{
    use HasFactory;

    protected $table = 'children';

    protected $fillable = [
        'nama',
        'nama_anak',
        'user_id',
        'tanggal_lahir',
        'jenis_kelamin',
    ];

    protected $casts = [
        'tanggal_lahir' => 'date',
    ];

    public function measurements(): HasMany
    {
        return $this->hasMany(Measurement::class, 'child_id');
    }

    public function growthRecords(): HasMany
    {
        return $this->hasMany(GrowthRecord::class, 'child_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

