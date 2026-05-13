<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Makanan extends Model
{
    use HasFactory;

    protected $table = 'makanan';

    protected $fillable = [
        'nama',
        'usia_min',
        'usia_max',
        'kategori_status',
        'kalori',
        'protein',
        'lemak',
        'karbohidrat',
        'alasan',
    ];
}

