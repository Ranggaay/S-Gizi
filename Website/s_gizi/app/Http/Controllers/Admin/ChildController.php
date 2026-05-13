<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Child;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class ChildController extends Controller
{
    public function index(Request $request): View
    {
        $q = (string) $request->query('q', '');

        $children = Child::query()
            ->when($q !== '', fn ($qb) => $qb->where('nama', 'like', "%{$q}%"))
            ->orderBy('nama')
            ->paginate(15)
            ->withQueryString();

        return view('admin.children.index', compact('children', 'q'));
    }

    public function create(): View
    {
        return view('admin.children.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'tanggal_lahir' => ['required', 'date'],
            'jenis_kelamin' => ['required', 'in:L,P'],
        ]);

        Child::query()->create($data);

        return redirect()->route('admin.children.index')->with('success', 'Data anak berhasil ditambahkan.');
    }

    public function edit(Child $child): View
    {
        return view('admin.children.edit', compact('child'));
    }

    public function update(Request $request, Child $child): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'tanggal_lahir' => ['required', 'date'],
            'jenis_kelamin' => ['required', 'in:L,P'],
        ]);

        $child->update($data);

        return redirect()->route('admin.children.index')->with('success', 'Data anak berhasil diperbarui.');
    }

    public function destroy(Child $child): RedirectResponse
    {
        $child->delete();

        return redirect()->route('admin.children.index')->with('success', 'Data anak berhasil dihapus.');
    }
}

