<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Helpers\NutritionStatusHelper;
use App\Models\Makanan;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\View\View;

class FoodController extends Controller
{
    public function index(Request $request): View
    {
        $q = (string) $request->query('q', '');
        $filter = (string) $request->query('filter', 'Semua');
        $recommendation = $request->boolean('recommendation');
        $recommendationStatus = (string) $request->query('status', $filter);
        $recommendationFoodIds = collect(explode(',', (string) $request->query('food_ids', '')))
            ->map(fn ($id) => (int) $id)
            ->filter()
            ->unique()
            ->values();
        $archive = strtolower((string) $request->query('archive', 'aktif'));
        $archive = match ($archive) {
            'arsip', 'diarsipkan', 'archived' => 'arsip',
            'semua', 'all' => 'semua',
            default => 'aktif',
        };

        $baseQuery = $this->applyArchiveFilter(Makanan::query(), $archive);

        $foods = $this->applyArchiveFilter(Makanan::query()->with('creator'), $archive)
            ->when($q !== '', function ($qb) use ($q) {
                $qb->where(function ($w) use ($q) {
                    $w->where('nama', 'like', "%{$q}%")
                        ->orWhere('kategori_status', 'like', "%{$q}%")
                        ->orWhere('prioritas_menu', 'like', "%{$q}%")
                        ->orWhere('badges', 'like', "%{$q}%")
                        ->orWhere('alasan', 'like', "%{$q}%");
                });
            })
            ->when($recommendation && $recommendationFoodIds->isNotEmpty(), function ($qb) use ($recommendationFoodIds) {
                $qb->whereIn('id', $recommendationFoodIds);
            })
            ->when($recommendation && $recommendationFoodIds->isEmpty() && $recommendationStatus !== '', function ($qb) use ($recommendationStatus) {
                $this->applyRecommendationFilter($qb, $recommendationStatus);
            })
            ->when(! $recommendation && $filter !== '' && $filter !== 'Semua', function ($qb) use ($filter) {
                if (in_array($filter, ['Published', 'Draft', 'Menunggu Verifikasi', 'Ditolak', 'Archived'], true)) {
                    $qb->where('status_menu', $filter);
                } elseif ($filter === 'Dari Ahli Gizi') {
                    $qb->whereHas('creator', fn ($query) => $query->where('role', 'nutritionist'));
                } else {
                    $qb->where(function ($query) use ($filter) {
                        $query->where('kategori_status', $filter)
                            ->orWhere('prioritas_menu', $filter)
                            ->orWhere('badges', 'like', "%{$filter}%");
                    });
                }
            })
            ->orderByRaw("CASE status_menu WHEN 'Menunggu Verifikasi' THEN 1 WHEN 'Published' THEN 2 WHEN 'Draft' THEN 3 WHEN 'Ditolak' THEN 4 ELSE 5 END")
            ->orderBy('nama')
            ->paginate(12)
            ->withQueryString();

        $summary = [
            'total' => (clone $baseQuery)->count(),
            'pending' => (clone $baseQuery)->where('status_menu', 'Menunggu Verifikasi')->count(),
            'gizi_kurang' => (clone $baseQuery)->whereIn('kategori_status', ['Gizi Kurang', 'Gizi Buruk', 'Wasting', 'Underweight'])->count(),
            'obesitas' => (clone $baseQuery)->where('kategori_status', 'Obesitas')->count(),
            'draft' => (clone $baseQuery)->where('status_menu', 'Draft')->count(),
        ];

        return view('admin.foods.index', compact('foods', 'q', 'filter', 'archive', 'recommendation', 'recommendationStatus', 'recommendationFoodIds', 'summary'));
    }

    public function create(): View
    {
        return view('admin.foods.create');
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $this->validatedFood($request);
        $data['thumbnail'] = $this->storeThumbnail($request);
        $data['created_by'] = $request->user()?->id;

        Makanan::query()->create($data);

        return redirect()->route('admin.foods.index')->with('success', 'Makanan berhasil ditambahkan.');
    }

    public function show(Makanan $food): View
    {
        return view('admin.foods.show', compact('food'));
    }

    public function edit(Makanan $food): View
    {
        return view('admin.foods.edit', compact('food'));
    }

    public function update(Request $request, Makanan $food): RedirectResponse
    {
        $data = $this->validatedFood($request, $food);
        $thumbnail = $this->storeThumbnail($request);
        if ($thumbnail) {
            $data['thumbnail'] = $thumbnail;
        }
        if (($data['status_menu'] ?? null) === 'Published') {
            $data['verified_by'] = $request->user()?->id;
            $data['verified_at'] = now();
            $data['rejection_reason'] = null;
        }

        $food->update($data);

        return redirect()->route('admin.foods.index')->with('success', 'Makanan berhasil diperbarui.');
    }

    public function approve(Request $request, Makanan $food): RedirectResponse
    {
        $food->update([
            'status_menu' => 'Published',
            'verified_by' => $request->user()?->id,
            'verified_at' => now(),
            'rejection_reason' => null,
        ]);

        return back()->with('success', 'Rekomendasi makanan disetujui dan dipublikasikan.');
    }

    public function reject(Request $request, Makanan $food): RedirectResponse
    {
        $data = $request->validate([
            'rejection_reason' => ['required', 'string', 'max:1000'],
        ]);

        $food->update([
            'status_menu' => 'Ditolak',
            'verified_by' => $request->user()?->id,
            'verified_at' => now(),
            'rejection_reason' => $data['rejection_reason'],
        ]);

        return back()->with('success', 'Rekomendasi makanan ditolak dan alasan tersimpan.');
    }

    public function destroy(Makanan $food): RedirectResponse
    {
        $food->delete();

        return redirect()->route('admin.foods.index')->with('success', 'Menu berhasil dihapus.');
    }

    public function archive(Makanan $food): RedirectResponse
    {
        $food->update(['status_menu' => 'Archived']);

        return redirect()
            ->route('admin.foods.index', ['archive' => 'arsip'])
            ->with('success', 'Menu berhasil diarsipkan.');
    }

    private function applyArchiveFilter($query, string $archive)
    {
        return match ($archive) {
            'arsip' => $query->where('status_menu', 'Archived'),
            'semua' => $query,
            default => $query->where(function ($where) {
                $where->whereNull('status_menu')
                    ->orWhere('status_menu', '!=', 'Archived');
            }),
        };
    }

    private function applyRecommendationFilter($query, string $status): void
    {
        $terms = $this->recommendationTerms($status);

        $query->where(function ($where) use ($terms) {
            $where->whereIn('kategori_status', $terms);
        });
    }

    private function recommendationTerms(string $status): array
    {
        $localized = NutritionStatusHelper::localize($status);

        return collect([
            $localized,
            match ($localized) {
                NutritionStatusHelper::GIZI_BAIK => 'Normal',
                NutritionStatusHelper::PENDEK, NutritionStatusHelper::SANGAT_PENDEK => 'Stunting',
                NutritionStatusHelper::GIZI_BURUK => 'Wasting',
                NutritionStatusHelper::GIZI_KURANG => 'Wasting',
                NutritionStatusHelper::OBESITAS, NutritionStatusHelper::GIZI_LEBIH, NutritionStatusHelper::RISIKO_BB_LEBIH => 'Obesitas',
                default => null,
            },
            match (strtolower($status)) {
                'sangat kurang', 'kurang' => 'Underweight',
                default => null,
            },
        ])->filter()->unique()->values()->all();
    }

    private function validatedFood(Request $request, ?Makanan $food = null): array
    {
        $thumbnailRule = $food?->exists ? 'nullable' : 'required';
        $data = $request->validate([
            'thumbnail' => [$thumbnailRule, 'image', 'max:3072'],
            'nama' => ['required', 'string', 'max:255'],
            'kategori_status' => ['required', 'string', 'max:100'],
            'usia_min' => ['required', 'integer', 'min:0'],
            'usia_max' => ['required', 'integer', 'min:0'],
            'usia_kategori' => ['required', 'string', 'max:40'],
            'kalori' => ['required', 'integer', 'min:0'],
            'protein' => ['required', 'integer', 'min:0'],
            'lemak' => ['required', 'integer', 'min:0'],
            'karbohidrat' => ['required', 'integer', 'min:0'],
            'serat' => ['required', 'integer', 'min:0'],
            'gula' => ['required', 'integer', 'min:0'],
            'badges_input' => ['nullable', 'string', 'max:255'],
            'status_menu' => ['required', 'string', 'max:30'],
            'prioritas_menu' => ['required', 'string', 'max:40'],
            'alasan' => ['required', 'string'],
            'bahan' => ['nullable', 'string'],
            'cara_memasak' => ['nullable', 'string'],
        ]);

        $data['badges'] = collect(explode(',', (string) ($data['badges_input'] ?? '')))
            ->map(fn ($badge) => trim($badge))
            ->filter()
            ->values()
            ->all();

        unset($data['badges_input'], $data['thumbnail']);

        return $data;
    }

    private function storeThumbnail(Request $request): ?string
    {
        if (! $request->hasFile('thumbnail')) {
            return null;
        }

        $directory = public_path('assets/foods');
        if (! is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        $file = $request->file('thumbnail');
        $filename = 'menu-'.now()->format('YmdHis').'-'.Str::random(8).'.'.$file->getClientOriginalExtension();
        $file->move($directory, $filename);

        return 'assets/foods/'.$filename;
    }
}
