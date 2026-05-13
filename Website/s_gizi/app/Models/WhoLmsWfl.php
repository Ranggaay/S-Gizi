<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WhoLmsWfl extends Model
{
    protected $table = 'who_lms_wfl';
    public $timestamps = false;

    protected $fillable = [
        'panjang',
        'jk',
        'L',
        'M',
        'S',
    ];
}

