<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ConsultationRoom extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'child_id',
        'expert_id',
        'expert_name',
        'specialization',
        'asset_image',
        'online',
        'status',
        'last_message',
        'last_message_at',
        'unread_count',
    ];

    protected $casts = [
        'online' => 'boolean',
        'last_message_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(ConsultationMessage::class, 'room_id');
    }
}

