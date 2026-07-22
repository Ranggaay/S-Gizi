<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Child extends Model
{
    use HasFactory, SoftDeletes;

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

    public function latestMeasurement(): HasOne
    {
        return $this->hasOne(Measurement::class, 'child_id')->ofMany([
            'tanggal_ukur' => 'max',
            'id' => 'max',
        ]);
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
