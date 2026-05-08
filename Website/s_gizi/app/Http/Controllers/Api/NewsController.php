<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class NewsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = trim((string) $request->query('q', 'gizi balita stunting makanan sehat balita'));
        $url = 'https://news.google.com/rss/search';
        $response = Http::timeout(12)->get($url, [
            'q' => $query,
            'hl' => 'id',
            'gl' => 'ID',
            'ceid' => 'ID:id',
        ]);

        if (!$response->ok()) return $this->empty($query);

        $xml = @simplexml_load_string($response->body());
        if (!$xml || !isset($xml->channel->item)) return $this->empty($query);

        $allowedCategories = [
            'Stunting',
            'MPASI',
            'Nutrisi Anak',
            'Protein',
            'Vitamin',
            'Parenting Anak',
            'Kesehatan Balita',
        ];

        $articles = collect($xml->channel->item)
            ->values()
            ->map(function ($item, $index) {
                $rawTitle = trim((string) $item->title);
                $description = trim(strip_tags((string) $item->description));
                $content = mb_strlen($description) > 320
                    ? mb_substr($description, 0, 320) . '...'
                    : $description;
                $excerpt = mb_strlen($description) > 140
                    ? mb_substr($description, 0, 160) . '...'
                    : $description;
                [$title, $sourceName] = $this->splitTitleSource($rawTitle);
                $category = $this->detectCategory($title . ' ' . $description);

                return [
                    'id' => $index + 1,
                    'title' => $title !== '' ? $title : 'Artikel Gizi Balita',
                    'image' => $this->extractImageUrl((string) $item->description),
                    'category' => $category,
                    'description' => $excerpt !== '' ? $excerpt : 'Informasi terbaru seputar gizi balita dan pencegahan stunting.',
                    'content' => $content !== '' ? $content : 'Baca artikel lengkap pada sumber berita.',
                    'created_at' => (string) $item->pubDate,
                    'source_name' => $sourceName,
                    'source' => 'google_news',
                    'country' => 'id',
                    'url' => (string) $item->link,
                ];
            })
            ->filter(function ($article) use ($allowedCategories) {
                return in_array($article['category'], $allowedCategories, true);
            })
            ->take(12)
            ->values();

        return response()->json([
            'source' => 'news_api_filtered',
            'country' => 'id',
            'query' => $query,
            'data' => $articles,
        ]);
    }

    private function empty(string $query): JsonResponse
    {
        return response()->json([
            'source' => 'news_api_filtered',
            'country' => 'id',
            'query' => $query,
            'data' => [],
        ]);
    }

    private function extractImageUrl(string $descriptionHtml): ?string
    {
        if (preg_match('/<img[^>]+src="([^">]+)"/i', $descriptionHtml, $match)) {
            return trim((string) ($match[1] ?? '')) ?: null;
        }
        return null;
    }

    private function detectCategory(string $text): string
    {
        $value = mb_strtolower($text);

        if (str_contains($value, 'stunting')) return 'Stunting';
        if (str_contains($value, 'mpasi')) return 'MPASI';
        if (str_contains($value, 'protein') || str_contains($value, 'ikan') || str_contains($value, 'telur')) return 'Protein';
        if (str_contains($value, 'vitamin') || str_contains($value, 'mineral') || str_contains($value, 'mikronutrien')) return 'Vitamin';
        if (str_contains($value, 'parenting') || str_contains($value, 'pola asuh') || str_contains($value, 'orang tua')) return 'Parenting Anak';
        if (str_contains($value, 'balita') || str_contains($value, 'tumbuh kembang') || str_contains($value, 'imunisasi')) return 'Kesehatan Balita';
        if (str_contains($value, 'gizi') || str_contains($value, 'nutrisi') || str_contains($value, 'who nutrition')) return 'Nutrisi Anak';
        return 'Nutrisi Anak';
    }

    private function splitTitleSource(string $rawTitle): array
    {
        $title = trim($rawTitle);
        $source = null;
        if (str_contains($rawTitle, ' - ')) {
            $parts = explode(' - ', $rawTitle);
            if (count($parts) >= 2) {
                $source = trim((string) array_pop($parts));
                $title = trim(implode(' - ', $parts));
            }
        }
        return [$title, $source];
    }
}
