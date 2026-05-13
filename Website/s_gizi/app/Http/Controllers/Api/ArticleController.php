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
            ->latest();

        if ($category !== '' && strtolower($category) !== 'semua') {
            $query->where('category', $category);
        }

        $articles = $query
            ->limit($limit)
            ->get()
            ->map(function (Article $article) {
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
                    'created_at' => optional($article->created_at)->toISOString(),
                    // field opsional agar model Flutter tetap aman
                    'image' => null,
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

