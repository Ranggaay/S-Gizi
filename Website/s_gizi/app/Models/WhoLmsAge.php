<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WhoLmsAge extends Model
{
    protected $table = 'who_lms_age';
    public $timestamps = false;

    protected $fillable = [
        'umur',
        'jk',
        'indikator',
        'L',
        'M',
        'S',
    ];
}

