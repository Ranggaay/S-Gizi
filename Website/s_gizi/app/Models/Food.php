<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Food extends Model
{
    use HasFactory;

    protected $fillable = [
        'nama',
        'kategori',
    ];

    public function conditions(): HasMany
    {
        return $this->hasMany(FoodCondition::class, 'food_id');
    }
}

