<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NutritionistNotification extends Model
{
    use HasFactory;

    protected $fillable = [
        'nutritionist_id',
        'consultation_room_id',
        'child_id',
        'type',
        'title',
        'description',
        'priority',
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    public function nutritionist(): BelongsTo
    {
        return $this->belongsTo(Nutritionist::class);
    }

    public function room(): BelongsTo
    {
        return $this->belongsTo(ConsultationRoom::class, 'consultation_room_id');
    }

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }
}
