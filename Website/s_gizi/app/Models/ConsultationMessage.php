<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ConsultationMessage extends Model
{
    use HasFactory;

    protected $fillable = [
        'room_id',
        'sender_type',
        'message',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function room(): BelongsTo
    {
        return $this->belongsTo(ConsultationRoom::class, 'room_id');
    }
}

