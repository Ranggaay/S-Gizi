<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Article extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'created_by',
        'slug',
        'category',
        'thumbnail',
        'excerpt',
        'tags',
        'content',
        'published',
        'status',
        'verified_by',
        'verified_at',
        'rejection_reason',
        'published_at',
        'author',
        'views_count',
        'read_time',
    ];

    protected $casts = [
        'published' => 'boolean',
        'tags' => 'array',
        'published_at' => 'datetime',
        'verified_at' => 'datetime',
    ];

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function verifier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'verified_by');
    }
}
