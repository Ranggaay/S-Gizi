<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;

class ArticleController extends Controller
{
    public function index(Request $request): View
    {
        $q = trim((string) $request->query('q', ''));
        $filter = (string) $request->query('filter', 'Semua');
        $editId = $request->integer('edit');

        $base = Article::query();
        $summary = [
            'total' => (clone $base)->count(),
            'published' => (clone $base)->where('status', 'Published')->count(),
            'pending' => (clone $base)->where('status', 'Menunggu Verifikasi')->count(),
            'draft' => (clone $base)->where('status', 'Draft')->count(),
            'views' => (clone $base)->sum('views_count'),
        ];

        $articles = Article::query()
            ->with('creator')
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($nested) use ($q) {
                    $nested->where('title', 'like', "%{$q}%")
                        ->orWhere('category', 'like', "%{$q}%")
                        ->orWhere('tags', 'like', "%{$q}%");
                });
            })
            ->when($filter !== 'Semua', function ($query) use ($filter) {
                if (in_array($filter, ['Published', 'Draft', 'Menunggu Verifikasi', 'Ditolak', 'Archived'], true)) {
                    $query->where('status', $filter);
                } elseif ($filter === 'Dari Ahli Gizi') {
                    $query->whereHas('creator', fn ($creator) => $creator->where('role', 'nutritionist'));
                } else {
                    $query->where('category', $filter)
                        ->orWhere('tags', 'like', "%{$filter}%");
                }
            })
            ->latest('updated_at')
            ->paginate(8)
            ->withQueryString();

        $editingArticle = $editId ? Article::query()->find($editId) : null;

        return view('admin.articles.index', compact('articles', 'q', 'filter', 'summary', 'editingArticle'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validatedArticle($request);
        $data['thumbnail'] = $this->storeThumbnail($request);
        $data['status'] = $request->input('action') === 'publish' ? 'Published' : 'Draft';
        $data['published'] = $data['status'] === 'Published';
        $data['published_at'] = $data['published'] ? now() : null;
        $data['author'] = 'Admin S-Gizi';
        $data['created_by'] = $request->user()?->id;
        $data['slug'] = $this->uniqueSlug($data['title']);
        $data['read_time'] = $this->readTime($data['content']);

        Article::query()->create($data);

        return back()->with('success', $data['published'] ? 'Artikel berhasil dipublikasikan.' : 'Draft artikel berhasil disimpan.');
    }

    public function update(Request $request, Article $article): RedirectResponse
    {
        $data = $this->validatedArticle($request, $article);
        $thumbnail = $this->storeThumbnail($request);
        if ($thumbnail) {
            $data['thumbnail'] = $thumbnail;
        }

        $action = (string) $request->input('action', 'draft');
        if ($action === 'publish') {
            $data['status'] = 'Published';
            $data['published'] = true;
            $data['published_at'] = $article->published_at ?? now();
            $data['verified_by'] = $request->user()?->id;
            $data['verified_at'] = now();
            $data['rejection_reason'] = null;
        } elseif ($action === 'archive') {
            $data['status'] = 'Archived';
            $data['published'] = false;
        } else {
            $data['status'] = 'Draft';
            $data['published'] = false;
            $data['published_at'] = null;
        }

        $data['slug'] = $this->uniqueSlug($data['title'], $article);
        $data['read_time'] = $this->readTime($data['content']);
        $article->update($data);

        return redirect()->route('admin.articles.index')->with('success', 'Artikel berhasil diperbarui.');
    }

    public function approve(Request $request, Article $article): RedirectResponse
    {
        $article->update([
            'status' => 'Published',
            'published' => true,
            'published_at' => $article->published_at ?? now(),
            'verified_by' => $request->user()?->id,
            'verified_at' => now(),
            'rejection_reason' => null,
        ]);

        return back()->with('success', 'Artikel disetujui dan dipublikasikan.');
    }

    public function reject(Request $request, Article $article): RedirectResponse
    {
        $data = $request->validate([
            'rejection_reason' => ['required', 'string', 'max:1000'],
        ]);

        $article->update([
            'status' => 'Ditolak',
            'published' => false,
            'verified_by' => $request->user()?->id,
            'verified_at' => now(),
            'rejection_reason' => $data['rejection_reason'],
        ]);

        return back()->with('success', 'Artikel ditolak dan alasan tersimpan.');
    }

    public function destroy(Article $article): RedirectResponse
    {
        $article->delete();

        return back()->with('success', 'Artikel berhasil dihapus.');
    }

    private function validatedArticle(Request $request, ?Article $article = null): array
    {
        $thumbnailRule = $article?->exists ? 'nullable' : 'required';

        $data = $request->validate([
            'thumbnail' => [$thumbnailRule, 'image', 'max:3072'],
            'title' => ['required', 'string', 'max:180'],
            'category' => ['required', 'string', 'max:80'],
            'excerpt' => ['nullable', 'string', 'max:260'],
            'tags_input' => ['nullable', 'string', 'max:255'],
            'content' => ['required', 'string'],
        ]);

        $data['tags'] = collect(explode(',', (string) ($data['tags_input'] ?? '')))
            ->map(fn ($tag) => trim($tag))
            ->filter()
            ->values()
            ->all();
        unset($data['tags_input'], $data['thumbnail']);

        return $data;
    }

    private function storeThumbnail(Request $request): ?string
    {
        if (! $request->hasFile('thumbnail')) {
            return null;
        }

        $directory = public_path('assets/articles');
        if (! is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        $file = $request->file('thumbnail');
        $filename = 'artikel-'.now()->format('YmdHis').'-'.uniqid().'.'.$file->getClientOriginalExtension();
        $file->move($directory, $filename);

        return 'assets/articles/'.$filename;
    }

    private function uniqueSlug(string $title, ?Article $article = null): string
    {
        $base = Str::slug($title) ?: 'artikel-sgizi';
        $slug = $base;
        $counter = 2;

        while (Article::query()
            ->where('slug', $slug)
            ->when($article, fn ($query) => $query->where('id', '!=', $article->id))
            ->exists()) {
            $slug = $base.'-'.$counter++;
        }

        return $slug;
    }

    private function readTime(string $content): int
    {
        return max(1, (int) ceil(str_word_count(strip_tags($content)) / 200));
    }
}
