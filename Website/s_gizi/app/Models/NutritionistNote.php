<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NutritionistNote extends Model
{
    use HasFactory;

    protected $fillable = [
        'consultation_room_id',
        'nutritionist_id',
        'child_id',
        'category',
        'note',
    ];

    public function room(): BelongsTo
    {
        return $this->belongsTo(ConsultationRoom::class, 'consultation_room_id');
    }

    public function nutritionist(): BelongsTo
    {
        return $this->belongsTo(Nutritionist::class);
    }

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }
}
