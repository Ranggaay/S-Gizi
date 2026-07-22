<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ArticleController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $limit = (int) $request->query('limit', 50);
        $limit = $limit > 0 ? min($limit, 100) : 50;

        $category = trim((string) $request->query('category', ''));

        $query = Article::query()
            ->where('published', true)
            ->where('status', 'Published')
            ->latest('published_at')
            ->latest();

        if ($category !== '' && strtolower($category) !== 'semua') {
            $query->where('category', $category);
        }

        $articles = $query
            ->limit($limit)
            ->get()
            ->map(function (Article $article) {
                $article->increment('views_count');
                $excerpt = trim((string) ($article->excerpt ?? ''));
                $content = trim((string) ($article->content ?? ''));

                if ($excerpt === '' && $content !== '') {
                    $excerpt = mb_strlen($content) > 160
                        ? mb_substr($content, 0, 160) . '...'
                        : $content;
                }

                return [
                    'id' => (int) $article->id,
                    'title' => (string) $article->title,
                    'description' => $excerpt !== '' ? $excerpt : '-',
                    'content' => $content,
                    'category' => (string) ($article->category ?? 'Nutrisi Anak'),
                    'tags' => $article->tags ?? [],
                    'slug' => (string) ($article->slug ?? ''),
                    'author' => (string) ($article->author ?? 'Admin S-Gizi'),
                    'read_time' => (int) ($article->read_time ?: 1),
                    'views_count' => (int) ($article->views_count + 1),
                    'created_at' => optional($article->published_at ?? $article->created_at)->toISOString(),
                    // field opsional agar model Flutter tetap aman
                    'image' => $article->thumbnail ? asset($article->thumbnail) : null,
                    'url' => null,
                    'source_name' => 'S-Gizi',
                ];
            })
            ->values();

        return response()->json([
            'source' => 'db_articles',
            'data' => $articles,
        ]);
    }
}
