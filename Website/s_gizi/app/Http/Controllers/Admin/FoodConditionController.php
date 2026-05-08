<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Makanan;
use App\Models\FoodCondition;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;

class FoodConditionController extends Controller
{
    public function index(Request $request): View
    {
        $status = (string) $request->query('status', '');

        $mappings = FoodCondition::query()
            ->with('food')
            ->when($status !== '', fn ($qb) => $qb->where('status_gizi', $status))
            ->orderBy('status_gizi')
            ->paginate(20)
            ->withQueryString();

        $foods = Makanan::query()->orderBy('nama')->get(['id', 'nama', 'kategori']);

        return view('admin.food_conditions.index', compact('mappings', 'foods', 'status'));
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'food_id' => ['required', 'integer', 'exists:foods,id'],
            'status_gizi' => ['required', 'string', 'max:255'],
        ]);

        FoodCondition::query()->firstOrCreate($data);

        return redirect()->route('admin.food_conditions.index')->with('success', 'Mapping berhasil disimpan.');
    }

    public function destroy(FoodCondition $foodCondition): RedirectResponse
    {
        $foodCondition->delete();

        return redirect()->route('admin.food_conditions.index')->with('success', 'Mapping berhasil dihapus.');
    }
}

