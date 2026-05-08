<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Makanan;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class FoodController extends Controller
{
    public function index(Request $request): View
    {
        $q = (string) $request->query('q', '');

        $foods = Makanan::query()
            ->when($q !== '', function ($qb) use ($q) {
                $qb->where(function ($w) use ($q) {
                    $w->where('nama', 'like', "%{$q}%")
                        ->orWhere('kategori', 'like', "%{$q}%");
                });
            })
            ->orderBy('nama')
            ->paginate(15)
            ->withQueryString();

        return view('admin.foods.index', compact('foods', 'q'));
    }

    public function create(): View
    {
        return view('admin.foods.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'kategori' => ['required', 'string', 'max:100'],
        ]);

        Makanan::query()->create($data);

        return redirect()->route('admin.foods.index')->with('success', 'Makanan berhasil ditambahkan.');
    }

    public function edit(Food $food): View
    {
        return view('admin.foods.edit', compact('food'));
    }

    public function update(Request $request, Food $food): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'kategori' => ['required', 'string', 'max:100'],
        ]);

        $food->update($data);

        return redirect()->route('admin.foods.index')->with('success', 'Makanan berhasil diperbarui.');
    }

    public function destroy(Food $food): RedirectResponse
    {
        $food->delete();

        return redirect()->route('admin.foods.index')->with('success', 'Makanan berhasil dihapus.');
    }
}

