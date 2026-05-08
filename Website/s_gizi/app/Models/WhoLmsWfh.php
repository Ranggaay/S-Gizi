<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WhoLmsWfh extends Model
{
    protected $table = 'who_lms_wfh';
    public $timestamps = false;

    protected $fillable = [
        'tinggi',
        'jk',
        'L',
        'M',
        'S',
    ];
}

