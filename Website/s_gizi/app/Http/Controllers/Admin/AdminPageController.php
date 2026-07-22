<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Helpers\NutritionStatusHelper;
use App\Models\Child;
use App\Models\ConsultationMessage;
use App\Models\ConsultationRoom;
use App\Models\Nutritionist;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Illuminate\View\View;

class AdminPageController extends Controller
{
    public function monitoring(Request $request): View
    {
        $q = trim((string) $request->query('q', ''));
        $statusFilter = (string) $request->query('status', 'Semua');
        $timeFilter = (string) $request->query('time', 'Semua');
        $sort = (string) $request->query('sort', 'Terbaru diukur');

        $children = Child::query()
            ->with(['user', 'measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id')])
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($nested) use ($q) {
                    $nested->where('nama', 'like', "%{$q}%")
                        ->orWhereHas('user', fn ($user) => $user->where('name', 'like', "%{$q}%"));
                });
            })
            ->get();

        $rows = $children->map(function (Child $child) {
            $latest = $child->measurements->first();
            $previous = $child->measurements->skip(1)->first();
            $status = NutritionStatusHelper::getStatus($latest);

            return [
                'child' => $child,
                'latest' => $latest,
                'previous' => $previous,
                'status' => $status,
                'risk' => NutritionStatusHelper::riskLabel($status),
                'risk_score' => NutritionStatusHelper::riskScore($status),
            ];
        });

        $totalChildren = $rows->count();
        $highRiskCount = $rows->where('risk', 'Risiko Tinggi')->count();
        $unmeasuredCount = $rows->filter(fn ($row) => $row['latest'] === null)->count();
        $todayMeasurements = $rows->filter(fn ($row) => $row['latest']?->tanggal_ukur?->isToday())->count();

        $rows = $rows
            ->when($statusFilter !== 'Semua', fn ($collection) => $collection->filter(fn ($row) => $row['status'] === $statusFilter))
            ->when($timeFilter !== 'Semua', function ($collection) use ($timeFilter) {
                return $collection->filter(function ($row) use ($timeFilter) {
                    $date = $row['latest']?->tanggal_ukur;
                    if (!$date) {
                        return false;
                    }

                    return match ($timeFilter) {
                        'Hari Ini' => $date->isToday(),
                        '7 Hari' => $date->gte(now()->subDays(7)),
                        '30 Hari' => $date->gte(now()->subDays(30)),
                        default => true,
                    };
                });
            });

        $rows = (match ($sort) {
            'Terbaru diukur' => $rows->sortByDesc(fn ($row) => $row['latest']?->tanggal_ukur?->timestamp ?? 0),
            'Belum diukur' => $rows->sortBy(fn ($row) => $row['latest'] ? 1 : 0),
            'Nama anak' => $rows->sortBy(fn ($row) => $row['child']->nama),
            default => $rows->sortByDesc('risk_score'),
        })->values();

        $perPage = 10;
        $page = LengthAwarePaginator::resolveCurrentPage();
        $paginatedRows = new LengthAwarePaginator(
            $rows->forPage($page, $perPage)->values(),
            $rows->count(),
            $perPage,
            $page,
            [
                'path' => $request->url(),
                'query' => $request->query(),
            ],
        );

        return view('admin.monitoring', [
            'rows' => $paginatedRows,
            'q' => $q,
            'statusFilter' => $statusFilter,
            'timeFilter' => $timeFilter,
            'sort' => $sort,
            'summary' => [
                'totalChildren' => $totalChildren,
                'highRiskCount' => $highRiskCount,
                'unmeasuredCount' => $unmeasuredCount,
                'todayMeasurements' => $todayMeasurements,
            ],
        ]);
    }

    public function consultations(Request $request): View
    {
        $q = trim((string) $request->query('q', ''));
        $filter = (string) $request->query('filter', 'Semua');
        $selectedRoomId = $request->integer('room');
        $expertId = trim((string) $request->query('expert_id', ''));
        $expertName = trim((string) $request->query('expert_name', ''));

        $roomsQuery = ConsultationRoom::query()
            ->with([
                'user',
                'child.user',
                'child.measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id')->take(8),
            ])
            ->when($expertId !== '', fn ($query) => $query->where('expert_id', $expertId))
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($nested) use ($q) {
                    $nested->where('last_message', 'like', "%{$q}%")
                        ->orWhereHas('user', fn ($user) => $user->where('name', 'like', "%{$q}%"))
                        ->orWhereHas('child', fn ($child) => $child->where('nama', 'like', "%{$q}%"));
                });
            })
            ->latest('last_message_at');

        $rooms = $roomsQuery->get()->map(function (ConsultationRoom $room) {
            $latest = $room->child?->measurements?->first();
            $status = NutritionStatusHelper::getStatus($latest);

            $room->monitoring_status = $status;
            $room->monitoring_risk = NutritionStatusHelper::riskLabel($status);
            $room->monitoring_risk_score = NutritionStatusHelper::riskScore($status);

            return $room;
        });

        $rooms = match ($filter) {
            'Belum Dibalas' => $rooms->filter(fn ($room) => (int) $room->unread_count > 0),
            'Aktif' => $rooms->filter(fn ($room) => in_array($room->status, ['aktif', 'active', 'open', 'waiting'], true)),
            'Risiko Tinggi' => $rooms->filter(fn ($room) => $room->monitoring_risk === 'Risiko Tinggi'),
            'Hari Ini' => $rooms->filter(fn ($room) => $room->last_message_at?->isToday()),
            'Selesai' => $rooms->filter(fn ($room) => in_array($room->status, ['selesai', 'closed', 'resolved'], true)),
            default => $rooms,
        };

        $rooms = $rooms->values();
        $selectedRoom = $selectedRoomId
            ? $rooms->firstWhere('id', $selectedRoomId)
            : $rooms->first();

        if ($selectedRoom) {
            $selectedRoom->load([
                'messages' => fn ($query) => $query->oldest()->take(40),
                'child.user',
                'child.measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id')->take(8),
            ]);
        }

        return view('admin.consultations', [
            'rooms' => $rooms,
            'selectedRoom' => $selectedRoom,
            'q' => $q,
            'filter' => $filter,
            'expertId' => $expertId,
            'expertName' => $expertName,
        ]);
    }

    public function parents(): View
    {
        return $this->parentsIndex(request());
    }

    public function parentsIndex(Request $request): View
    {
        $q = trim((string) $request->query('q', ''));
        $filter = (string) $request->query('filter', 'Semua');
        $sort = (string) $request->query('sort', 'Terbaru daftar');

        $parents = User::query()
            ->with([
                'children.measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id'),
            ])
            ->withCount([
                'children',
                'children as measurement_count' => fn ($query) => $query->whereHas('measurements'),
            ])
            ->where('role', 'orang_tua')
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($nested) use ($q) {
                    $nested->where('name', 'like', "%{$q}%")
                        ->orWhere('email', 'like', "%{$q}%")
                        ->orWhere('phone', 'like', "%{$q}%")
                        ->orWhereHas('children', fn ($child) => $child->where('nama', 'like', "%{$q}%"));
                });
            })
            ->get();

        $consultationCounts = ConsultationRoom::query()
            ->selectRaw('user_id, count(*) as total')
            ->groupBy('user_id')
            ->pluck('total', 'user_id');

        $activeConsultationCounts = ConsultationRoom::query()
            ->selectRaw('user_id, count(*) as total')
            ->whereIn('status', ['aktif', 'active', 'open', 'waiting'])
            ->groupBy('user_id')
            ->pluck('total', 'user_id');

        $rows = $parents->map(function (User $parent) use ($consultationCounts, $activeConsultationCounts) {
            $childRows = $parent->children->map(function (Child $child) {
                $latest = $child->measurements->first();
                $status = NutritionStatusHelper::getStatus($latest);

                return [
                    'child' => $child,
                    'latest' => $latest,
                    'status' => $status,
                    'risk' => NutritionStatusHelper::riskLabel($status),
                    'risk_score' => NutritionStatusHelper::riskScore($status),
                ];
            });

            $riskScore = (int) $childRows->max('risk_score');
            $familyStatus = match ($riskScore) {
                3 => 'Risiko Tinggi',
                2 => 'Perlu Pantau',
                1 => 'Stabil',
                default => 'Belum Ukur',
            };

            $lastMeasurement = $childRows
                ->pluck('latest')
                ->filter()
                ->sortByDesc(fn ($measurement) => $measurement->tanggal_ukur?->timestamp ?? 0)
                ->first();

            $lastConsultationAt = ConsultationRoom::query()
                ->where('user_id', $parent->id)
                ->latest('last_message_at')
                ->value('last_message_at');
            $lastConsultationAt = $lastConsultationAt ? Carbon::parse($lastConsultationAt) : null;

            return [
                'parent' => $parent,
                'children' => $childRows,
                'family_status' => $familyStatus,
                'risk_score' => $riskScore,
                'account_status' => $parent->account_status ?: 'Aktif',
                'consultations_count' => (int) ($consultationCounts[$parent->id] ?? 0),
                'active_consultations_count' => (int) ($activeConsultationCounts[$parent->id] ?? 0),
                'last_active' => $parent->last_active_at ?? $lastConsultationAt ?? $lastMeasurement?->created_at ?? $parent->updated_at,
                'has_linked_data' => $parent->children_count > 0
                    || (int) ($consultationCounts[$parent->id] ?? 0) > 0
                    || (int) $parent->measurement_count > 0,
            ];
        });

        $summary = [
            'totalParents' => $rows->count(),
            'activeConsultations' => $rows->sum('active_consultations_count'),
            'highRiskFamilies' => $rows->where('family_status', 'Risiko Tinggi')->count(),
            'unmeasuredFamilies' => $rows->where('family_status', 'Belum Ukur')->count(),
        ];

        $rows = $rows
            ->when($filter !== 'Semua', function ($collection) use ($filter) {
                return $collection->filter(function ($row) use ($filter) {
                    return match ($filter) {
                        'Aktif' => $row['account_status'] === 'Aktif',
                        'Nonaktif' => $row['account_status'] === 'Nonaktif',
                        'Risiko Tinggi' => $row['family_status'] === 'Risiko Tinggi',
                        'Belum Ukur' => $row['family_status'] === 'Belum Ukur',
                        'Konsultasi Aktif' => $row['active_consultations_count'] > 0,
                        default => true,
                    };
                });
            });

        $rows = (match ($sort) {
            'Terbaru daftar' => $rows->sortByDesc(fn ($row) => $row['parent']->created_at?->timestamp ?? 0),
            'Jumlah anak terbanyak' => $rows->sortByDesc(fn ($row) => $row['parent']->children_count),
            'Risiko tertinggi' => $rows->sortByDesc('risk_score'),
            default => $rows->sortBy(fn ($row) => $row['parent']->name),
        })->values();

        $perPage = 10;
        $page = LengthAwarePaginator::resolveCurrentPage();
        $paginatedRows = new LengthAwarePaginator(
            $rows->forPage($page, $perPage)->values(),
            $rows->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()],
        );

        return view('admin.parents', [
            'rows' => $paginatedRows,
            'q' => $q,
            'filter' => $filter,
            'sort' => $sort,
            'summary' => $summary,
        ]);
    }

    public function parentDetail(User $parent): View
    {
        abort_unless((string) $parent->role === 'orang_tua', 404);

        $parent->load([
            'children.measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id')->take(8),
        ]);

        $consultationsCount = ConsultationRoom::query()->where('user_id', $parent->id)->count();
        $lastMeasurement = $parent->children
            ->flatMap(fn ($child) => $child->measurements)
            ->sortByDesc(fn ($measurement) => $measurement->tanggal_ukur?->timestamp ?? 0)
            ->first();
        $lastConsultationAt = ConsultationRoom::query()
            ->where('user_id', $parent->id)
            ->latest('last_message_at')
            ->value('last_message_at');
        $lastConsultationAt = $lastConsultationAt ? Carbon::parse($lastConsultationAt) : null;

        return view('admin.parents.show', [
            'parent' => $parent,
            'consultationsCount' => $consultationsCount,
            'lastMeasurement' => $lastMeasurement,
            'lastActive' => $parent->last_active_at ?? $lastConsultationAt ?? $lastMeasurement?->created_at ?? $parent->updated_at,
        ]);
    }

    public function createParent(): View
    {
        return view('admin.parents.create');
    }

    public function storeParent(Request $request): RedirectResponse
    {
        $request->merge(['phone' => $this->normalizeAdminPhone((string) $request->input('phone', ''))]);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:32', Rule::unique('users', 'phone')],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')],
            'parent_gender' => ['required', Rule::in(['ayah', 'bunda'])],
            'password' => ['required', 'confirmed', Password::min(8)],
            'account_status' => ['required', Rule::in(['Aktif', 'Nonaktif'])],
        ]);

        $parent = User::query()->create([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'] ?: null,
            'role' => 'orang_tua',
            'parent_gender' => $validated['parent_gender'],
            'password' => Hash::make($validated['password']),
            'account_status' => $validated['account_status'],
            'status' => $validated['account_status'] === 'Aktif' ? 'aktif' : 'nonaktif',
        ]);

        return redirect()
            ->route('admin.parents.show', $parent)
            ->with('success', 'Akun orang tua berhasil ditambahkan.');
    }

    public function updateParent(Request $request, User $parent): RedirectResponse
    {
        abort_unless((string) $parent->role === 'orang_tua', 404);
        $isSuperAdmin = $request->user()?->role === 'super_admin';

        $rules = [
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:32', Rule::unique('users', 'phone')->ignore($parent->id)],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')->ignore($parent->id)],
            'account_status' => ['required', Rule::in(['Aktif', 'Nonaktif', 'Diblokir'])],
        ];

        if ($isSuperAdmin) {
            $rules['password'] = ['nullable', 'confirmed', Password::min(8)];
        } else {
            $rules['password'] = ['prohibited'];
            $rules['password_confirmation'] = ['prohibited'];
        }

        $validated = $request->validate($rules);

        $payload = collect($validated)
            ->except(['password_confirmation'])
            ->filter(fn ($value, $key) => $key !== 'password' || filled($value))
            ->all();

        if (! empty($payload['password'])) {
            $payload['password'] = Hash::make($payload['password']);
        }

        $parent->update($payload);

        return back()->with('success', ! empty($payload['password'])
            ? 'Data orang tua dan password berhasil diperbarui.'
            : 'Data orang tua berhasil diperbarui.');
    }

    public function deactivateParent(User $parent): RedirectResponse
    {
        abort_unless(auth()->user()?->role === 'super_admin', 403);
        abort_unless((string) $parent->role === 'orang_tua', 404);

        $parent->update(['account_status' => 'Nonaktif']);

        return back()->with('success', 'Akun orang tua berhasil dinonaktifkan.');
    }

    public function destroyParent(User $parent): RedirectResponse
    {
        abort_unless(auth()->user()?->role === 'super_admin', 403);
        abort_unless((string) $parent->role === 'orang_tua', 404);

        $parent->delete();

        return redirect()->route('admin.parents')->with('success', 'Akun orang tua berhasil dihapus.');
    }

    public function openChildConsultation(Child $child): RedirectResponse
    {
        $room = ConsultationRoom::query()
            ->where('child_id', $child->id)
            ->latest('last_message_at')
            ->latest('updated_at')
            ->first();

        if (!$room) {
            return back()->with('warning', 'Anak dengan nama '.$child->nama.' belum pernah melakukan konsultasi.');
        }

        return redirect()->route('admin.consultations', [
            'room' => $room->id,
            'q' => $child->nama,
        ]);
    }

    public function openParentConsultation(User $parent): RedirectResponse
    {
        abort_unless((string) $parent->role === 'orang_tua', 404);

        $room = ConsultationRoom::query()
            ->where('user_id', $parent->id)
            ->latest('last_message_at')
            ->latest('updated_at')
            ->first();

        if (!$room) {
            $childName = $parent->children()->value('nama') ?: $parent->name;
            return back()->with('warning', 'Anak dengan nama '.$childName.' belum pernah melakukan konsultasi.');
        }

        return redirect()->route('admin.consultations', [
            'room' => $room->id,
            'q' => $parent->name,
        ]);
    }

    public function openNutritionistConsultations(Nutritionist $nutritionist): RedirectResponse
    {
        $expertId = trim((string) ($nutritionist->expert_id ?: 'expert-'.$nutritionist->user_id));
        $room = ConsultationRoom::query()
            ->where('expert_id', $expertId)
            ->latest('last_message_at')
            ->latest('updated_at')
            ->first();

        if (!$room) {
            return back()->with('warning', 'Ahli gizi ini belum memiliki riwayat konsultasi.');
        }

        return redirect()->route('admin.consultations', [
            'room' => $room->id,
            'expert_id' => $expertId,
            'expert_name' => $nutritionist->user?->name,
        ]);
    }

    public function nutritionists(Request $request): View
    {
        $q = trim((string) $request->query('q', ''));
        $filter = (string) $request->query('filter', 'Semua');

        $nutritionists = Nutritionist::query()
            ->with('user')
            ->when($q !== '', function ($query) use ($q) {
                $query->where('specialization', 'like', "%{$q}%")
                    ->orWhereHas('user', fn ($user) => $user->where('name', 'like', "%{$q}%"));
            })
            ->latest()
            ->get();

        $rows = $nutritionists->map(fn (Nutritionist $nutritionist) => $this->nutritionistMonitoringRow($nutritionist));

        $summary = [
            'totalNutritionists' => $rows->count(),
            'onlineToday' => $rows->filter(fn ($row) => $row['is_online'])->count(),
            'activeConsultations' => $rows->sum('active_consultations'),
            'availableNutritionists' => $rows->filter(fn ($row) => $row['capacity'] !== 'Penuh' && $row['account_status'] === 'Aktif' && $row['is_available'])->count(),
        ];

        $rows = $rows
            ->when($filter !== 'Semua', function ($collection) use ($filter) {
                return $collection->filter(function ($row) use ($filter) {
                    return match ($filter) {
                        'Online' => $row['is_online'],
                        'Offline' => ! $row['is_online'],
                        'Aktif' => $row['account_status'] === 'Aktif',
                        'Nonaktif' => $row['account_status'] === 'Nonaktif',
                        default => true,
                    };
                });
            })
            ->values();

        $perPage = 9;
        $page = LengthAwarePaginator::resolveCurrentPage();
        $paginatedRows = new LengthAwarePaginator(
            $rows->forPage($page, $perPage)->values(),
            $rows->count(),
            $perPage,
            $page,
            ['path' => $request->url(), 'query' => $request->query()],
        );

        return view('admin.nutritionists', [
            'rows' => $paginatedRows,
            'q' => $q,
            'filter' => $filter,
            'summary' => $summary,
        ]);
    }

    public function nutritionistDetail(Nutritionist $nutritionist): View
    {
        $nutritionist->load('user');

        return view('admin.nutritionists.show', [
            'row' => $this->nutritionistMonitoringRow($nutritionist, true),
        ]);
    }

    public function createNutritionist(): View
    {
        return view('admin.nutritionists.form', [
            'nutritionist' => new Nutritionist(),
            'mode' => 'create',
        ]);
    }

    public function storeNutritionist(Request $request): RedirectResponse
    {
        $request->merge(['phone' => $this->normalizeAdminPhone((string) $request->input('phone', ''))]);
        $validated = $this->validateNutritionistPayload($request);
        $avatar = $this->storeNutritionistAvatar($request);

        $user = User::query()->create([
            'name' => $validated['name'],
            'email' => $validated['email'] ?: null,
            'phone' => $validated['phone'],
            'role' => 'ahli_gizi',
            'account_status' => $validated['account_status'],
            'status' => $validated['account_status'] === 'Aktif' ? 'aktif' : 'nonaktif',
            'avatar' => $avatar,
            'parent_gender' => $validated['gender'],
            'password' => $validated['password'],
        ]);

        $user->nutritionist()->create([
            'expert_id' => $validated['expert_id'],
            'title' => $validated['title'],
            'specialization' => $validated['specialization'],
            'experience' => $validated['experience_years'].' tahun pengalaman',
            'experience_years' => $validated['experience_years'],
            'bio' => $validated['bio'],
            'str_sip' => $validated['str_sip'],
            'is_online' => false,
            'is_available' => $validated['account_status'] === 'Aktif',
            'max_consultation' => $validated['max_consultation'],
        ]);

        return redirect()->route('admin.nutritionists')->with('success', 'Ahli gizi berhasil ditambahkan.');
    }

    public function editNutritionist(Nutritionist $nutritionist): View
    {
        $nutritionist->load('user');

        return view('admin.nutritionists.form', [
            'nutritionist' => $nutritionist,
            'mode' => 'edit',
        ]);
    }

    public function updateNutritionist(Request $request, Nutritionist $nutritionist): RedirectResponse
    {
        $nutritionist->load('user');
        $request->merge(['phone' => $this->normalizeAdminPhone((string) $request->input('phone', ''))]);
        $validated = $this->validateNutritionistPayload($request, $nutritionist);
        $avatar = $this->storeNutritionistAvatar($request);

        $userPayload = [
            'name' => $validated['name'],
            'email' => $validated['email'] ?: null,
            'phone' => $validated['phone'],
            'account_status' => $validated['account_status'],
            'status' => $validated['account_status'] === 'Aktif' ? 'aktif' : 'nonaktif',
            'parent_gender' => $validated['gender'],
        ];
        if ($avatar) {
            $userPayload['avatar'] = $avatar;
        }
        if (!empty($validated['password'])) {
            $userPayload['password'] = $validated['password'];
        }

        $nutritionist->user?->update($userPayload);

        $nutritionist->update([
            'expert_id' => $validated['expert_id'],
            'title' => $validated['title'],
            'specialization' => $validated['specialization'],
            'experience' => $validated['experience_years'].' tahun pengalaman',
            'experience_years' => $validated['experience_years'],
            'bio' => $validated['bio'],
            'str_sip' => $validated['str_sip'],
            'is_available' => $validated['account_status'] === 'Aktif',
            'max_consultation' => $validated['max_consultation'],
        ]);

        return redirect()->route('admin.nutritionists')->with('success', 'Data ahli gizi berhasil diperbarui.');
    }

    public function deactivateNutritionist(Nutritionist $nutritionist): RedirectResponse
    {
        $nutritionist->user?->update(['account_status' => 'Nonaktif', 'status' => 'nonaktif']);
        $nutritionist->update(['is_online' => false, 'is_available' => false]);

        return back()->with('success', 'Akun ahli gizi berhasil dinonaktifkan.');
    }

    public function activateNutritionist(Nutritionist $nutritionist): RedirectResponse
    {
        $nutritionist->user?->update(['account_status' => 'Aktif', 'status' => 'aktif']);
        $nutritionist->update(['is_available' => true]);

        return back()->with('success', 'Akun ahli gizi berhasil diaktifkan.');
    }

    public function settings(): View
    {
        $admin = auth()->user();
        $admins = User::query()
            ->whereIn('role', ['super_admin', 'admin_operasional'])
            ->latest('last_login_at')
            ->latest()
            ->get();

        $activities = $admins
            ->map(fn (User $row) => [
                'admin' => $row->name ?: 'Admin S-Gizi',
                'action' => $row->last_login_at ? 'login ke sistem admin' : 'akun admin dibuat',
                'time' => $row->last_login_at ?? $row->created_at,
            ])
            ->filter(fn ($activity) => $activity['time'] !== null)
            ->sortByDesc(fn ($activity) => $activity['time']->timestamp)
            ->values();

        return view('admin.settings', [
            'admin' => $admin,
            'admins' => $admins,
            'activities' => $activities,
            'isSuperAdmin' => $admin?->role === 'super_admin',
        ]);
    }

    public function storeAdmin(Request $request): RedirectResponse
    {
        $request->merge(['phone' => $this->normalizeAdminPhone((string) $request->input('phone', ''))]);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')],
            'phone' => ['required', 'string', 'max:32', Rule::unique('users', 'phone')],
            'password' => ['required', 'confirmed', Password::min(8)],
            'role' => ['required', Rule::in(['super_admin', 'admin_operasional'])],
            'account_status' => ['required', Rule::in(['Aktif', 'Nonaktif'])],
        ]);

        User::query()->create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $this->normalizeAdminPhone($validated['phone']),
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'account_status' => $validated['account_status'],
            'status' => $validated['account_status'] === 'Aktif' ? 'aktif' : 'nonaktif',
        ]);

        return back()->with('success', 'Admin berhasil ditambahkan.');
    }

    public function updateProfile(Request $request): RedirectResponse
    {
        /** @var User $admin */
        $admin = auth()->user();
        $request->merge(['phone' => $this->normalizeAdminPhone((string) $request->input('phone', ''))]);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($admin->id)],
            'phone' => ['required', 'string', 'max:32', Rule::unique('users', 'phone')->ignore($admin->id)],
        ]);

        $admin->update($validated);

        return back()->with('success', 'Profil admin berhasil diperbarui.');
    }

    public function updatePassword(Request $request): RedirectResponse
    {
        /** @var User $admin */
        $admin = auth()->user();

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        if (! $admin->password || ! Hash::check($validated['current_password'], $admin->password)) {
            return back()->withErrors(['current_password' => 'Password lama tidak sesuai.']);
        }

        $admin->update([
            'password' => Hash::make($validated['password']),
        ]);

        return back()->with('success', 'Password admin berhasil diperbarui.');
    }

    public function updateAdmin(Request $request, User $admin): RedirectResponse
    {
        abort_unless(in_array($admin->role, ['super_admin', 'admin_operasional'], true), 404);
        $request->merge(['phone' => $this->normalizeAdminPhone((string) $request->input('phone', ''))]);

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', Rule::unique('users', 'email')->ignore($admin->id)],
            'phone' => ['required', 'string', 'max:32', Rule::unique('users', 'phone')->ignore($admin->id)],
            'password' => ['nullable', 'confirmed', Password::min(8)],
            'role' => ['required', Rule::in(['super_admin', 'admin_operasional'])],
            'account_status' => ['required', Rule::in(['Aktif', 'Nonaktif'])],
        ]);

        $payload = [
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'],
            'role' => $validated['role'],
            'account_status' => $validated['account_status'],
            'status' => $validated['account_status'] === 'Aktif' ? 'aktif' : 'nonaktif',
        ];

        if (! empty($validated['password'])) {
            $payload['password'] = Hash::make($validated['password']);
        }

        $admin->update($payload);

        return back()->with('success', 'Data admin berhasil diperbarui.');
    }

    public function deactivateAdmin(User $admin): RedirectResponse
    {
        abort_if($admin->id === auth()->id(), 422, 'Admin tidak dapat menonaktifkan akunnya sendiri.');
        abort_unless(in_array($admin->role, ['super_admin', 'admin_operasional'], true), 404);

        $admin->update([
            'account_status' => 'Nonaktif',
            'status' => 'nonaktif',
        ]);

        return back()->with('success', 'Admin berhasil dinonaktifkan.');
    }

    private function nutritionistMonitoringRow(Nutritionist $nutritionist, bool $withRooms = false): array
    {
        $nutritionist->loadMissing('user');
        $user = $nutritionist->user;
        $expertId = trim((string) ($nutritionist->expert_id ?: 'expert-'.$nutritionist->user_id));
        $rooms = ConsultationRoom::query()
            ->with(['child.measurements' => fn ($query) => $query->latest('tanggal_ukur')->latest('id')->take(1), 'user'])
            ->where('expert_id', $expertId)
            ->get();

        $activeRooms = $rooms->filter(fn ($room) => in_array($room->status, ['aktif', 'active', 'open', 'waiting'], true));
        $completedRooms = $rooms->filter(fn ($room) => in_array($room->status, ['selesai', 'closed', 'resolved'], true));
        $highRiskChildren = $rooms
            ->pluck('child')
            ->filter()
            ->unique('id')
            ->filter(function ($child) {
                $status = NutritionStatusHelper::getStatus($child->measurements->first());

                return NutritionStatusHelper::riskLabel($status) === 'Risiko Tinggi';
            })
            ->count();

        $rawUserLastActiveAt = $user?->getRawOriginal('last_active_at');
        $rawNutritionistLastActiveAt = $nutritionist->getRawOriginal('last_active_at');
        $lastActiveAt = collect([$rawUserLastActiveAt, $rawNutritionistLastActiveAt])
            ->filter()
            ->map(fn ($timestamp) => Carbon::parse($timestamp))
            ->sortDesc()
            ->first();
        $isAccountActive = ! (($user?->status ?? 'aktif') === 'nonaktif' || ($user?->account_status ?? 'Aktif') === 'Nonaktif');
        $isOnline = $isAccountActive && (bool) $nutritionist->is_online && (bool) $lastActiveAt?->gte(now()->subMinutes(5));
        $presence = $isOnline ? 'Online' : 'Offline';

        $activeCount = $activeRooms->count();
        $capacity = match (true) {
            $activeCount >= (int) ($nutritionist->max_consultation ?: 25) => 'Penuh',
            $activeCount > 10 => 'Sedang',
            default => 'Ringan',
        };

        $roomIds = $rooms->pluck('id');
        $expertReplies = $roomIds->isEmpty()
            ? 0
            : ConsultationMessage::query()->whereIn('room_id', $roomIds)->where('sender_type', 'expert')->count();
        $parentMessages = $roomIds->isEmpty()
            ? 0
            : ConsultationMessage::query()->whereIn('room_id', $roomIds)->where('sender_type', 'parent')->count();
        $responseRate = $parentMessages > 0 ? min(100, (int) round(($expertReplies / $parentMessages) * 100)) : 0;

        return [
            'nutritionist' => $nutritionist,
            'user' => $user,
            'expert_id' => $expertId,
            'name' => trim(($user?->name ?? 'Ahli Gizi').' '.($nutritionist->title ? ', '.$nutritionist->title : '')),
            'account_status' => (($user?->status ?? 'aktif') === 'nonaktif' || ($user?->account_status ?? 'Aktif') === 'Nonaktif') ? 'Nonaktif' : 'Aktif',
            'is_available' => (bool) $nutritionist->is_available,
            'last_active_at' => $lastActiveAt,
            'last_online_label' => $isOnline
                ? 'Sedang online'
                : ($lastActiveAt?->locale('id')->translatedFormat('d M Y H:i') ?? 'Belum pernah online'),
            'is_online' => $isOnline,
            'presence' => $presence,
            'specializations' => $this->nutritionistSpecializationChips((string) $nutritionist->specialization),
            'experience' => ($nutritionist->experience_years ?: 0).' tahun pengalaman',
            'bio' => $nutritionist->bio,
            'avatar' => $user?->avatar,
            'active_consultations' => $activeCount,
            'completed_consultations' => $completedRooms->count(),
            'monitored_children' => $rooms->pluck('child_id')->filter()->unique()->count(),
            'monitored_families' => $rooms->pluck('user_id')->filter()->unique()->count(),
            'high_risk_children' => $highRiskChildren,
            'capacity' => $capacity,
            'response_rate' => $responseRate,
            'avg_response' => $expertReplies > 0 ? '+/- 15 menit' : '-',
            'rooms' => $withRooms ? $rooms->sortByDesc(fn ($room) => $room->last_message_at?->timestamp ?? 0)->values() : collect(),
        ];
    }

    private function nutritionistSpecializationChips(string $specialization): array
    {
        $known = ['Stunting', 'MPASI', 'Gizi Kurang', 'Obesitas Anak', 'Tumbuh Kembang'];
        $lower = strtolower($specialization);
        $chips = collect($known)->filter(fn ($item) => str_contains($lower, strtolower(str_replace(' Anak', '', $item))))->values()->all();

        return $chips ?: [$specialization ?: 'Gizi Anak'];
    }

    private function validateNutritionistPayload(Request $request, ?Nutritionist $nutritionist = null): array
    {
        $userId = $nutritionist?->user_id;
        $isCreate = $nutritionist === null || ! $nutritionist->exists;

        return $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'title' => ['nullable', 'string', 'max:80'],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')->ignore($userId)],
            'phone' => ['required', 'string', 'max:32', Rule::unique('users', 'phone')->ignore($userId)],
            'account_status' => ['required', Rule::in(['Aktif', 'Nonaktif'])],
            'gender' => ['nullable', Rule::in(['laki-laki', 'perempuan', 'ayah', 'bunda'])],
            'password' => [$isCreate ? 'required' : 'nullable', 'confirmed', Password::min(8)],
            'avatar' => ['nullable', 'image', 'max:2048'],
            'expert_id' => ['required', 'string', 'max:80', Rule::unique('nutritionists', 'expert_id')->ignore($nutritionist?->id)],
            'specialization' => ['required', Rule::in(['Stunting', 'Gizi Kurang', 'MPASI', 'Obesitas Anak', 'Tumbuh Kembang', 'Konsultasi Umum'])],
            'experience_years' => ['required', 'integer', 'min:0', 'max:60'],
            'bio' => ['nullable', 'string', 'max:1000'],
            'max_consultation' => ['required', 'integer', 'min:1', 'max:100'],
            'str_sip' => ['nullable', 'string', 'max:120'],
        ]);
    }

    private function normalizeAdminPhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if (str_starts_with($digits, '0')) {
            $digits = '62'.substr($digits, 1);
        }
        if (! str_starts_with($digits, '62')) {
            $digits = '62'.$digits;
        }

        return '+'.$digits;
    }

    private function storeNutritionistAvatar(Request $request): ?string
    {
        if (! $request->hasFile('avatar')) {
            return null;
        }

        $file = $request->file('avatar');
        $directory = public_path('assets/nutritionists');
        if (! is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        $filename = 'ahli-gizi-'.now()->format('YmdHis').'-'.uniqid().'.'.$file->getClientOriginalExtension();
        $file->move($directory, $filename);

        return 'assets/nutritionists/'.$filename;
    }
}
