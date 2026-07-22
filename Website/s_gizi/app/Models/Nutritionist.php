<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Nutritionist extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'expert_id',
        'title',
        'specialization',
        'experience',
        'experience_years',
        'bio',
        'str_sip',
        'is_online',
        'is_available',
        'max_consultation',
        'last_active_at',
    ];

    protected function casts(): array
    {
        return [
            'is_online' => 'boolean',
            'is_available' => 'boolean',
            'last_active_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
