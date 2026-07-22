<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Helpers\NutritionStatusHelper;
use App\Models\Child;
use App\Models\ConsultationRoom;
use App\Models\Makanan;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\View\View;

class ChildController extends Controller
{
    public function index(Request $request): View
    {
        $q = trim((string) $request->query('q', ''));
        $filter = (string) $request->query('filter', 'Semua');
        $sort = (string) $request->query('sort', 'terbaru');
        $time = (string) $request->query('time', 'Semua');
        $archive = strtolower((string) $request->query('archive', 'aktif'));
        $archive = match ($archive) {
            'arsip', 'diarsipkan', 'archived' => 'arsip',
            'semua', 'all' => 'semua',
            default => 'aktif',
        };

        $children = Child::query()
            ->when(
                $archive === 'arsip',
                fn ($query) => $query->onlyTrashed(),
                fn ($query) => $archive === 'semua' ? $query->withTrashed() : $query,
            )
            ->with(['user', 'latestMeasurement'])
            ->withCount('measurements')
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($nested) use ($q) {
                    $nested->where('nama', 'like', "%{$q}%")
                        ->orWhereHas('user', fn ($user) => $user->where('name', 'like', "%{$q}%"));
                });
            })
            ->get();

        $rows = $children->map(function (Child $child) {
            $latest = $child->latestMeasurement;
            $ageMonths = $child->tanggal_lahir ? (int) round($child->tanggal_lahir->diffInMonths(now())) : null;
            $status = $ageMonths !== null && $ageMonths > 60
                ? 'Di luar batas WHO balita'
                : NutritionStatusHelper::getStatus($latest);
            $risk = $status === 'Di luar batas WHO balita'
                ? 'Perlu Pantau'
                : NutritionStatusHelper::riskLabel($status);

            return [
                'child' => $child,
                'latest' => $latest,
                'age_months' => $ageMonths,
                'status' => $status,
                'risk' => $risk,
                'risk_score' => $status === 'Di luar batas WHO balita' ? 2 : NutritionStatusHelper::riskScore($status),
            ];
        });

        $summary = [
            'totalChildren' => $rows->count(),
            'highRiskCount' => $rows->where('risk', 'Risiko Tinggi')->count(),
            'unmeasuredCount' => $rows->filter(fn ($row) => $row['latest'] === null)->count(),
            'todayMeasurements' => $rows->filter(fn ($row) => $row['latest']?->tanggal_ukur?->isToday())->count(),
        ];

        $rows = $rows
            ->when($filter !== 'Semua', function ($collection) use ($filter) {
                return $collection->filter(function ($row) use ($filter) {
                    $latest = $row['latest'];

                    return match ($filter) {
                        'Stunting' => in_array($row['status'], [NutritionStatusHelper::PENDEK, NutritionStatusHelper::SANGAT_PENDEK], true),
                        'Risiko Tinggi' => $row['risk'] === 'Risiko Tinggi',
                        'Belum Diukur' => $latest === null,
                        'Belum Ukur > 30 Hari' => $latest === null || $latest->tanggal_ukur?->lt(now()->subDays(30)),
                        default => $row['status'] === $filter,
                    };
                });
            })
            ->when($time !== 'Semua', function ($collection) use ($time) {
                return $collection->filter(function ($row) use ($time) {
                    $date = $row['latest']?->tanggal_ukur;
                    if (!$date) {
                        return false;
                    }

                    return match ($time) {
                        'Hari Ini' => $date->isToday(),
                        '7 Hari' => $date->gte(now()->subDays(7)),
                        '30 Hari' => $date->gte(now()->subDays(30)),
                        default => true,
                    };
                });
            });

        $rows = (match ($sort) {
            'risiko' => $rows->sortByDesc('risk_score'),
            'nama' => $rows->sortBy(fn ($row) => $row['child']->nama),
            'umur' => $rows->sortByDesc(fn ($row) => $row['age_months'] ?? -1),
            default => $rows->sortByDesc(fn ($row) => $row['latest']?->tanggal_ukur?->timestamp ?? 0),
        })->values();

        $perPage = 10;
        $page = LengthAwarePaginator::resolveCurrentPage();
        $children = new LengthAwarePaginator(
            $rows->forPage($page, $perPage)->values(),
            $rows->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()],
        );

        return view('admin.children.index', compact('children', 'q', 'filter', 'sort', 'time', 'archive', 'summary'));
    }

    public function create(): View
    {
        return view('admin.children.create', [
            'parents' => $this->parentOptions(),
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'user_id' => ['nullable', 'exists:users,id'],
            'tanggal_lahir' => ['required', 'date'],
            'jenis_kelamin' => ['required', 'in:L,P'],
        ]);

        Child::query()->create($data);

        return redirect()->route('admin.children.index')->with('success', 'Data anak berhasil ditambahkan.');
    }

    public function edit(Child $child): View
    {
        return view('admin.children.edit', [
            'child' => $child,
            'parents' => $this->parentOptions(),
        ]);
    }

    public function show(Child $child): View
    {
        $child->load([
            'user',
            'measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id')->take(12),
        ]);

        $latest = $child->measurements->first();
        $latestStatus = NutritionStatusHelper::getStatus($latest);
        $recommendationStatuses = collect([
            $latestStatus,
            NutritionStatusHelper::bbuStatus($latest),
            NutritionStatusHelper::tbuStatus($latest),
            NutritionStatusHelper::bbtbStatus($latest),
            match ($latestStatus) {
                NutritionStatusHelper::GIZI_BAIK => 'Normal',
                default => null,
            },
        ])->filter()->unique()->values();

        $recommendedFoods = Makanan::query()
            ->where('status_menu', 'Published')
            ->where(function ($query) use ($recommendationStatuses) {
                foreach ($recommendationStatuses as $status) {
                    $query->orWhere('kategori_status', $status)
                        ->orWhere('badges', 'like', "%{$status}%")
                        ->orWhere('prioritas_menu', 'like', "%{$status}%");
                }
            })
            ->orderByRaw("CASE prioritas_menu WHEN 'Tinggi' THEN 1 WHEN 'Sedang' THEN 2 ELSE 3 END")
            ->take(4)
            ->get();

        $consultationRooms = ConsultationRoom::query()
            ->with(['user', 'messages' => fn ($query) => $query->latest()->take(1)])
            ->where('child_id', $child->id)
            ->latest('last_message_at')
            ->get();

        return view('admin.children.show', compact('child', 'recommendedFoods', 'consultationRooms'));
    }

    public function update(Request $request, Child $child): RedirectResponse
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:255'],
            'user_id' => ['nullable', 'exists:users,id'],
            'tanggal_lahir' => ['required', 'date'],
            'jenis_kelamin' => ['required', 'in:L,P'],
        ]);

        $child->update($data);

        return redirect()->route('admin.children.index')->with('success', 'Data anak berhasil diperbarui.');
    }

    public function destroy(Child $child): RedirectResponse
    {
        abort_unless(auth()->user()?->role === 'super_admin', 403);

        $child->delete();

        return redirect()->route('admin.children.index')->with('success', 'Data anak berhasil diarsipkan.');
    }

    public function restore(Child $child): RedirectResponse
    {
        if (!$child->trashed()) {
            return back()->with('warning', 'Data anak ini masih aktif.');
        }

        $child->restore();

        return redirect()
            ->route('admin.children.index', ['archive' => 'aktif'])
            ->with('success', 'Data anak berhasil diaktifkan kembali.');
    }

    private function parentOptions()
    {
        return User::query()
            ->where('role', 'orang_tua')
            ->orderBy('name')
            ->get(['id', 'name', 'phone']);
    }
}
