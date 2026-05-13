<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ArticleController extends Controller
{
    public function index(): View
    {
        return view('admin.articles.index', [
            'articles' => Article::query()->latest()->paginate(20),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        Article::query()->create($request->validate([
            'title' => ['required', 'string', 'max:160'],
            'category' => ['required', 'string', 'max:80'],
            'excerpt' => ['nullable', 'string', 'max:240'],
            'content' => ['required', 'string'],
            'published' => ['nullable', 'boolean'],
        ]) + ['published' => $request->boolean('published')]);

        return back()->with('success', 'Artikel berhasil ditambahkan.');
    }

    public function update(Request $request, Article $article): RedirectResponse
    {
        $article->update($request->validate([
            'title' => ['required', 'string', 'max:160'],
            'category' => ['required', 'string', 'max:80'],
            'excerpt' => ['nullable', 'string', 'max:240'],
            'content' => ['required', 'string'],
            'published' => ['nullable', 'boolean'],
        ]) + ['published' => $request->boolean('published')]);

        return back()->with('success', 'Artikel berhasil diperbarui.');
    }

    public function destroy(Article $article): RedirectResponse
    {
        $article->delete();

        return back()->with('success', 'Artikel berhasil dihapus.');
    }
}
