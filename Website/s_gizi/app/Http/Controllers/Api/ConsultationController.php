<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\ConsultationMessage;
use App\Models\ConsultationRoom;
use App\Models\Measurement;
use App\Models\Nutritionist;
use App\Models\NutritionistNote;
use App\Helpers\NutritionStatusHelper;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;

class ConsultationController extends Controller
{
    use ResolvesApiUser;

    public function nutritionists(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $rows = Nutritionist::query()
            ->with('user')
            ->where('is_available', true)
            ->whereHas('user', function ($query) {
                $query->whereIn('role', ['ahli_gizi', 'nutritionist', 'ahli gizi'])
                    ->where(function ($nested) {
                        $nested->where('status', 'aktif')
                            ->orWhereNull('status');
                    })
                    ->where(function ($nested) {
                        $nested->where('account_status', 'Aktif')
                            ->orWhereNull('account_status');
                    });
            })
            ->get()
            ->map(function (Nutritionist $nutritionist): ?array {
                $name = (string) ($nutritionist->user?->name ?? 'Ahli Gizi');
                $expertId = trim((string) ($nutritionist->expert_id ?? ''));
                if ($expertId === '') {
                    $expertId = 'expert-'.$nutritionist->user_id;
                }
                $consultationCount = ConsultationRoom::query()
                    ->where('expert_id', $expertId)
                    ->where('status', 'active')
                    ->count();
                if ($consultationCount >= (int) ($nutritionist->max_consultation ?: 25)) {
                    return null;
                }

                return [
                    'id' => $nutritionist->id,
                    'expert_id' => $expertId,
                    'name' => trim($name.($nutritionist->title ? ', '.$nutritionist->title : '')),
                    'specialization' => (string) ($nutritionist->specialization ?? 'Spesialis Gizi Anak'),
                    'focus_tag' => $this->focusTag($nutritionist->specialization),
                    'experience' => (string) (($nutritionist->experience_years ?? 0).' tahun pengalaman'),
                    'bio' => (string) ($nutritionist->bio ?? ''),
                    'str_sip' => (string) ($nutritionist->str_sip ?? ''),
                    'is_online' => (bool) ($nutritionist->user?->last_active_at?->gte(now()->subMinutes(5))),
                    'is_available' => (bool) $nutritionist->is_available,
                    'max_consultation' => (int) ($nutritionist->max_consultation ?: 25),
                    'consultation_count' => $consultationCount,
                    'photo_url' => $nutritionist->user?->avatar ? asset($nutritionist->user->avatar) : '',
                ];
            })
            ->filter()
            ->sortBy([
                ['is_online', 'desc'],
                ['consultation_count', 'asc'],
            ])
            ->values();

        return response()->json(['data' => $rows]);
    }

    public function nutritionistDashboard(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $role = mb_strtolower(trim((string) ($user->role ?? '')));
        if (!in_array($role, ['nutritionist', 'ahli_gizi', 'ahli gizi'], true)) {
            return response()->json(['message' => 'Akses khusus ahli gizi.'], 403);
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);

        $rooms = $this->nutritionistRoomsQuery($expertId)
            ->where('status', 'active')
            ->latest('last_message_at')
            ->latest('updated_at')
            ->get();

        $roomPayload = $rooms->map(fn (ConsultationRoom $room): array => $this->roomPayload($room))->values();
        $riskRooms = $roomPayload->filter(fn (array $room): bool => $room['risk'] !== 'normal')->values();

        $activities = $rooms->take(8)->map(function (ConsultationRoom $room): array {
            $measurements = $room->child?->measurements()->orderBy('tanggal_ukur')->get() ?? collect();
            $latest = $measurements->last();
            $previous = $measurements->count() > 1 ? $measurements->slice(-2, 1)->first() : null;
            $statusChanged = $latest && $previous && $latest->status_gabungan !== $previous->status_gabungan;
            return [
                'title' => $statusChanged
                    ? 'Status anak berubah'
                    : ($latest ? 'Pengukuran baru diterima' : 'Konsultasi diperbarui'),
                'description' => trim(($room->child?->nama ?? 'Anak').' - '.($room->last_message ?? 'Room konsultasi aktif')),
                'time' => optional($room->last_message_at ?? $room->updated_at)->toISOString(),
            ];
        })->values();

        return response()->json([
            'profile' => [
                'name' => $user->name,
                'phone' => $user->phone,
                'email' => $user->email,
                'gender' => $user->parent_gender,
                'profile_image' => $user->avatar ? asset($user->avatar) : '',
                'nutritionist' => [
                    'id' => $nutritionist->id,
                    'expert_id' => $expertId,
                    'title' => $nutritionist->title,
                    'specialization' => $nutritionist->specialization,
                    'experience' => $nutritionist->experience,
                    'experience_years' => $nutritionist->experience_years,
                    'bio' => $nutritionist->bio,
                    'str_sip' => $nutritionist->str_sip,
                    'is_online' => (bool) $nutritionist->is_online,
                    'is_available' => (bool) $nutritionist->is_available,
                    'max_consultation' => (int) ($nutritionist->max_consultation ?: 25),
                ],
            ],
            'stats' => [
                'active_consultations' => $rooms->count(),
                'monitored_children' => $rooms->pluck('child_id')->unique()->count(),
                'risk_children' => $riskRooms->count(),
                'unanswered' => $roomPayload->where('unread_count', '>', 0)->count(),
                'need_monitoring' => $roomPayload->where('monitoring_status', 'perlu_dipantau')->count(),
                'need_remeasure' => $roomPayload->where('validation_status', 'perlu_ukur_ulang')->count(),
            ],
            'rooms' => $roomPayload,
            'risk_children' => $riskRooms,
            'activities' => $activities,
        ]);
    }

    public function nutritionistRooms(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);

        $rooms = $this->nutritionistRoomsQuery($expertId)
            ->where('status', 'active')
            ->latest('last_message_at')
            ->latest('updated_at')
            ->get()
            ->map(fn (ConsultationRoom $room): array => $this->roomPayload($room))
            ->values();

        return response()->json(['data' => $rooms]);
    }

    public function nutritionistNotifications(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $rooms = $this->nutritionistRoomsQuery($expertId)
            ->where('status', 'active')
            ->latest('last_message_at')
            ->latest('updated_at')
            ->get();

        $items = [];
        foreach ($rooms as $room) {
            $payload = $this->roomPayload($room);
            if (($payload['unread_count'] ?? 0) > 0) {
                $items[] = [
                    'id' => 'message-'.$room->id,
                    'type' => 'message',
                    'title' => 'Pesan Baru',
                    'description' => $payload['parent_name'].' mengirim pesan pada konsultasi '.$payload['child_name'].'.',
                    'child_name' => $payload['child_name'],
                    'priority' => 'Sedang',
                    'time' => $payload['last_message_at'],
                    'is_read' => false,
                ];
            }
            if (($payload['validation_status'] ?? '') === 'perlu_ukur_ulang') {
                $items[] = [
                    'id' => 'remeasure-'.$room->id,
                    'type' => 'remeasure',
                    'title' => 'Perlu Ukur Ulang',
                    'description' => $payload['validation_note'] ?: 'Data pengukuran perlu dicek ulang.',
                    'child_name' => $payload['child_name'],
                    'priority' => 'Sedang',
                    'time' => $payload['last_message_at'],
                    'is_read' => false,
                ];
            }
            if (($payload['monitoring_status'] ?? '') === 'perlu_dipantau') {
                $items[] = [
                    'id' => 'monitor-'.$room->id,
                    'type' => 'monitor',
                    'title' => 'Perlu Dipantau',
                    'description' => $payload['validation_note'] ?: 'Anak perlu dipantau melalui konsultasi gizi.',
                    'child_name' => $payload['child_name'],
                    'priority' => 'Tinggi',
                    'time' => $payload['last_message_at'],
                    'is_read' => false,
                ];
            }
        }

        return response()->json(['data' => array_values($items)]);
    }

    public function nutritionistProfile(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        return response()->json(['data' => $this->nutritionistProfilePayload($nutritionist, $user)]);
    }

    public function updateNutritionistProfileStatus(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $validated = $request->validate([
            'is_active' => ['required', 'boolean'],
        ]);

        $nutritionist->update(['is_available' => (bool) $validated['is_active']]);

        return response()->json(['data' => $this->nutritionistProfilePayload($nutritionist->fresh(), $user)]);
    }

    public function nutritionistChildren(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $search = trim((string) $request->query('search', ''));
        $filter = mb_strtolower(trim((string) $request->query('filter', 'all')));
        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);

        $rooms = $this->nutritionistRoomsQuery($expertId)
            ->latest('last_message_at')
            ->latest('updated_at')
            ->get()
            ->unique('child_id')
            ->values();

        $children = $rooms->map(fn (ConsultationRoom $room): array => $this->nutritionistChildPayload($room))
            ->filter(function (array $row) use ($search, $filter): bool {
                if ($search !== '') {
                    $haystack = mb_strtolower(implode(' ', [
                        $row['name'] ?? '',
                        $row['parent_name'] ?? '',
                        $row['parent_phone'] ?? '',
                    ]));
                    if (!str_contains($haystack, mb_strtolower($search))) {
                        return false;
                    }
                }

                if ($filter === 'high_risk') {
                    return ($row['risk_status'] ?? '') === 'Risiko Tinggi';
                }
                if ($filter === 'anomaly') {
                    return (bool) ($row['is_anomaly'] ?? false);
                }
                if ($filter === 'normal') {
                    return ($row['risk_status'] ?? '') === 'Stabil';
                }

                return true;
            })
            ->values();

        return response()->json([
            'data' => [
                'summary' => [
                    'total' => $children->count(),
                    'high_risk' => $children->where('risk_status', 'Risiko Tinggi')->count(),
                    'anomaly' => $children->where('is_anomaly', true)->count(),
                    'normal' => $children->where('risk_status', 'Stabil')->count(),
                ],
                'children' => $children,
            ],
        ]);
    }

    public function nutritionistChildDetail(Request $request, int $childId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $room = $this->nutritionistRoomsQuery($expertId)
            ->where('child_id', $childId)
            ->latest('last_message_at')
            ->latest('updated_at')
            ->first();

        if (!$room || !$room->child) {
            return response()->json(['message' => 'Data anak tidak ditemukan.'], 404);
        }

        return response()->json(['data' => $this->nutritionistChildDetailPayload($room)]);
    }

    public function nutritionistChildDetailFromChat(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $room = $this->nutritionistRoomsQuery($expertId)->where('id', $roomId)->first();
        if (!$room || !$room->child) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $payload = $this->nutritionistChildDetailPayload($room);
        $payload['notes'] = NutritionistNote::query()
            ->where('nutritionist_id', $nutritionist->id)
            ->where('consultation_room_id', $room->id)
            ->latest()
            ->get()
            ->map(fn (NutritionistNote $note): array => [
                'id' => $note->id,
                'child_id' => $note->child_id,
                'note' => (string) $note->note,
                'created_at' => optional($note->created_at)->toISOString(),
            ])
            ->values();

        return response()->json(['data' => $payload]);
    }

    public function storeNutritionistNote(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $room = $this->nutritionistRoomsQuery($expertId)->where('id', $roomId)->first();
        if (!$room || !$room->child_id) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $validated = $request->validate([
            'category' => ['nullable', 'string', 'max:80'],
            'note' => ['required', 'string', 'max:2000'],
        ]);

        $note = NutritionistNote::query()->create([
            'consultation_room_id' => $room->id,
            'nutritionist_id' => $nutritionist->id,
            'child_id' => $room->child_id,
            'category' => $validated['category'] ?? 'Catatan',
            'note' => $validated['note'],
        ]);

        return response()->json([
            'data' => [
                'id' => $note->id,
                'child_id' => $note->child_id,
                'note' => (string) $note->note,
                'created_at' => optional($note->created_at)->toISOString(),
            ],
        ], 201);
    }

    public function markNutritionistNotificationRead(Request $request, int|string $id): JsonResponse
    {
        return response()->json(['message' => 'Notifikasi ditandai sudah dibaca.']);
    }

    public function markAllNutritionistNotificationsRead(Request $request): JsonResponse
    {
        return response()->json(['message' => 'Semua notifikasi ditandai sudah dibaca.']);
    }

    public function nutritionistMessages(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $room = $this->nutritionistRoomsQuery($expertId)->where('id', $roomId)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        ConsultationMessage::query()
            ->where('room_id', $room->id)
            ->where('sender_type', 'parent')
            ->where('is_read', false)
            ->update(['is_read' => true]);

        $messages = ConsultationMessage::query()
            ->where('room_id', $room->id)
            ->orderBy('created_at')
            ->get()
            ->map(fn (ConsultationMessage $m): array => $this->messagePayload($m))
            ->values();

        return response()->json([
            'room' => $this->roomPayload($room->fresh(['user', 'child.measurements'])),
            'data' => $messages,
        ]);
    }

    public function nutritionistSendMessage(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $room = $this->nutritionistRoomsQuery($expertId)->where('id', $roomId)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        if (in_array((string) $room->status, ['closed', 'selesai', 'resolved'], true)) {
            return response()->json(['message' => 'Konsultasi ini sudah selesai.'], 403);
        }

        if (Schema::hasColumn('consultation_rooms', 'started_by') && (string) ($room->started_by ?? 'parent') !== 'parent') {
            return response()->json(['message' => 'Anda tidak memiliki akses ke konsultasi ini.'], 403);
        }

        $hasParentMessage = ConsultationMessage::query()
            ->where('room_id', $room->id)
            ->where('sender_type', 'parent')
            ->exists();
        if (!$hasParentMessage) {
            return response()->json(['message' => 'Chat belum tersedia. Orang tua belum memulai konsultasi.'], 403);
        }

        $validated = $request->validate([
            'message' => ['required', 'string', 'max:3000'],
        ]);

        $message = ConsultationMessage::query()->create([
            'room_id' => $room->id,
            'sender_type' => 'expert',
            'message' => $validated['message'],
            'is_read' => false,
        ]);

        $room->update([
            'status' => 'active',
            'last_message' => $validated['message'],
            'last_message_at' => now(),
            'unread_count' => ((int) $room->unread_count) + 1,
        ]);

        return response()->json(['data' => $this->messagePayload($message)]);
    }

    public function nutritionistClose(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return response()->json(['message' => 'Data ahli gizi belum tersedia.'], 404);
        }

        $expertId = $this->resolveNutritionistExpertId($nutritionist, $user);
        $room = $this->nutritionistRoomsQuery($expertId)->where('id', $roomId)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        if (Schema::hasColumn('consultation_rooms', 'started_by') && (string) ($room->started_by ?? 'parent') !== 'parent') {
            return response()->json(['message' => 'Anda tidak memiliki akses ke konsultasi ini.'], 403);
        }

        $room->update(['status' => 'closed']);

        return response()->json(['message' => 'Konsultasi ditandai selesai.']);
    }

    public function rooms(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $childId = (int) $request->query('child_id', 0);
        $query = ConsultationRoom::query()->where('user_id', $user->id);
        if ($childId > 0) {
            $query->where('child_id', $childId);
        }

        $rooms = $query->latest('last_message_at')->latest('updated_at')->get()
            ->map(function (ConsultationRoom $room): array {
                $nutritionist = Nutritionist::query()
                    ->with('user')
                    ->where('expert_id', (string) $room->expert_id)
                    ->first();
                $expert = $this->nutritionistDisplayPayload($nutritionist);

                return [
                    'id' => $room->id,
                    'child_id' => $room->child_id,
                    'child_name' => (string) optional($room->child)->nama,
                    'expert_id' => (string) $room->expert_id,
                    'expert_name' => $expert['name'] ?: (string) $room->expert_name,
                    'specialization' => $expert['specialization'] ?: (string) ($room->specialization ?? ''),
                    'asset_image' => $expert['asset_image'] ?: (string) ($room->asset_image ?? ''),
                    'online' => $expert['online'] ?? (bool) $room->online,
                    'status' => (string) $room->status,
                    'last_message' => (string) ($room->last_message ?? ''),
                    'last_message_at' => optional($room->last_message_at)->toISOString(),
                    'unread_count' => (int) $room->unread_count,
                    'last_shared_measurement_id' => $room->last_shared_measurement_id,
                    'updated_at' => optional($room->updated_at)->toISOString(),
                ];
            })
            ->values();

        return response()->json(['data' => $rooms]);
    }

    public function openRoom(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $validated = $request->validate([
            'child_id' => ['required', 'integer'],
            'expert_id' => ['required', 'string', 'max:80'],
            'expert_name' => ['required', 'string', 'max:150'],
            'specialization' => ['nullable', 'string', 'max:150'],
            'asset_image' => ['nullable', 'string', 'max:255'],
            'online' => ['nullable', 'boolean'],
        ]);

        $child = Child::query()->where('id', $validated['child_id'])->where('user_id', $user->id)->first();
        if (!$child) {
            return response()->json(['message' => 'Anak tidak ditemukan.'], 404);
        }

        $nutritionist = Nutritionist::query()
            ->with('user')
            ->where('expert_id', $validated['expert_id'])
            ->first();
        $activeCount = ConsultationRoom::query()
            ->where('expert_id', $validated['expert_id'])
            ->where('status', 'active')
            ->count();
        if (! $nutritionist
            || ! $nutritionist->is_available
            || $activeCount >= (int) ($nutritionist->max_consultation ?: 25)
            || ($nutritionist->user?->status === 'nonaktif')
            || ($nutritionist->user?->account_status === 'Nonaktif')) {
            return response()->json(['message' => 'Ahli gizi tidak tersedia untuk konsultasi baru.'], 422);
        }

        $roomDefaults = [
            'expert_name' => $validated['expert_name'],
            'specialization' => $validated['specialization'] ?? '',
            'asset_image' => $validated['asset_image'] ?? '',
            'online' => (bool) ($validated['online'] ?? false),
            'status' => 'pending',
            'unread_count' => 0,
        ];
        if (Schema::hasColumn('consultation_rooms', 'started_by')) {
            $roomDefaults['started_by'] = 'parent';
        }

        $room = ConsultationRoom::query()->firstOrCreate(
            [
                'user_id' => $user->id,
                'child_id' => $child->id,
                'expert_id' => $validated['expert_id'],
            ],
            $roomDefaults
        );

        $expert = $this->nutritionistDisplayPayload($nutritionist);

        return response()->json([
            'data' => [
                'id' => $room->id,
                'child_id' => $room->child_id,
                'child_name' => (string) $child->nama,
                'expert_id' => (string) $room->expert_id,
                'expert_name' => $expert['name'] ?: (string) $room->expert_name,
                'specialization' => $expert['specialization'] ?: (string) ($room->specialization ?? ''),
                'asset_image' => $expert['asset_image'] ?: (string) ($room->asset_image ?? ''),
                'online' => $expert['online'] ?? (bool) $room->online,
                'status' => (string) $room->status,
                'last_message' => (string) ($room->last_message ?? ''),
                'last_message_at' => optional($room->last_message_at)->toISOString(),
                'last_shared_measurement_id' => $room->last_shared_measurement_id,
                'updated_at' => optional($room->updated_at)->toISOString(),
            ],
        ]);
    }

    public function messages(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $room = ConsultationRoom::query()->where('id', $roomId)->where('user_id', $user->id)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $messages = ConsultationMessage::query()
            ->where('room_id', $room->id)
            ->orderBy('created_at')
            ->get()
            ->map(fn (ConsultationMessage $m): array => [
                'id' => $m->id,
                'sender_type' => (string) $m->sender_type,
                'message' => (string) $m->message,
                'is_read' => (bool) $m->is_read,
                'created_at' => optional($m->created_at)->toISOString(),
            ])
            ->values();

        // Saat parent membuka room, tandai pesan dari ahli sebagai sudah dibaca.
        ConsultationMessage::query()
            ->where('room_id', $room->id)
            ->where('sender_type', 'expert')
            ->where('is_read', false)
            ->update(['is_read' => true]);
        if ($room->unread_count > 0) {
            $room->update(['unread_count' => 0]);
        }

        return response()->json(['data' => $messages]);
    }

    public function sendMessage(Request $request, int $roomId): JsonResponse
    {
        // PRESENTASI TA: Pesan orang tua disimpan ke room konsultasi dan dibedakan lewat sender_type.
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $room = ConsultationRoom::query()->where('id', $roomId)->where('user_id', $user->id)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $validated = $request->validate([
            'message' => ['required', 'string', 'max:3000'],
            'measurement_id' => ['nullable', 'integer'],
        ]);

        $isFirstParentMessage = !ConsultationMessage::query()
            ->where('room_id', $room->id)
            ->where('sender_type', 'parent')
            ->exists();

        $message = ConsultationMessage::query()->create([
            'room_id' => $room->id,
            'sender_type' => 'parent',
            'message' => $validated['message'],
            'is_read' => false,
        ]);

        $roomUpdate = [
            'status' => 'active',
            'last_message' => $validated['message'],
            'last_message_at' => now(),
        ];
        if (!empty($validated['measurement_id'])) {
            $roomUpdate['last_shared_measurement_id'] = $validated['measurement_id'];
        }
        $room->update($roomUpdate);

        if ($isFirstParentMessage) {
            $analysis = $this->initialAnalysisMessage($room->fresh(['child.measurements']));
            if ($analysis !== null) {
                ConsultationMessage::query()->create([
                    'room_id' => $room->id,
                    'sender_type' => 'system',
                    'message' => $analysis,
                    'is_read' => true,
                ]);
            }
        }

        return response()->json([
            'data' => [
                'id' => $message->id,
                'sender_type' => (string) $message->sender_type,
                'message' => (string) $message->message,
                'is_read' => (bool) $message->is_read,
                'created_at' => optional($message->created_at)->toISOString(),
            ],
        ]);
    }

    public function updateStatus(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $room = ConsultationRoom::query()->where('id', $roomId)->where('user_id', $user->id)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $validated = $request->validate([
            'status' => ['required', 'in:pending,active,closed,aktif,menunggu,selesai'],
        ]);

        $room->update(['status' => $this->normalizeRoomStatus($validated['status'])]);

        return response()->json(['message' => 'Status berhasil diperbarui.']);
    }

    public function markMeasurementShared(Request $request, int $roomId): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $room = ConsultationRoom::query()->where('id', $roomId)->where('user_id', $user->id)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $validated = $request->validate([
            'measurement_id' => ['required', 'integer'],
        ]);

        $room->update([
            'last_shared_measurement_id' => $validated['measurement_id'],
        ]);

        return response()->json([
            'message' => 'Update perkembangan berhasil ditandai sudah dikirim.',
            'last_shared_measurement_id' => $room->last_shared_measurement_id,
        ]);
    }

    public function sendExpertReply(Request $request, int $roomId): JsonResponse
    {
        // PRESENTASI TA: Balasan ahli gizi disimpan dan menambah penghitung pesan belum dibaca.
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $room = ConsultationRoom::query()->where('id', $roomId)->where('user_id', $user->id)->first();
        if (!$room) {
            return response()->json(['message' => 'Room tidak ditemukan.'], 404);
        }

        $validated = $request->validate([
            'message' => ['required', 'string', 'max:3000'],
        ]);

        $message = ConsultationMessage::query()->create([
            'room_id' => $room->id,
            'sender_type' => 'expert',
            'message' => $validated['message'],
            'is_read' => false,
        ]);

        $room->update([
            'status' => 'active',
            'last_message' => $validated['message'],
            'last_message_at' => now(),
            'unread_count' => ((int) $room->unread_count) + 1,
        ]);

        return response()->json([
            'data' => [
                'id' => $message->id,
                'sender_type' => (string) $message->sender_type,
                'message' => (string) $message->message,
                'is_read' => (bool) $message->is_read,
                'created_at' => optional($message->created_at)->toISOString(),
            ],
        ]);
    }

    private function nutritionistProfilePayload(?Nutritionist $nutritionist, $user): array
    {
        return [
            'id' => (int) ($nutritionist?->id ?? 0),
            'name' => (string) ($user?->name ?? 'Ahli Gizi'),
            'phone' => (string) ($user?->phone ?? '-'),
            'email' => (string) ($user?->email ?? '-'),
            'profession' => trim((string) ($nutritionist?->title ?: 'Ahli Gizi')),
            'workplace' => (string) ($nutritionist?->specialization ?: 'S-Gizi'),
            'photo' => $user?->avatar ? asset($user->avatar) : null,
            'is_active' => (bool) ($nutritionist?->is_available ?? true),
        ];
    }

    private function nutritionistChildPayload(ConsultationRoom $room): array
    {
        $child = $room->child;
        $parent = $room->user;
        $latest = $child?->measurements()->latest('tanggal_ukur')->latest('id')->first();
        $status = NutritionStatusHelper::getStatus($latest, $latest?->status_gabungan);

        return [
            'id' => (int) ($child?->id ?? 0),
            'name' => (string) ($child?->nama ?? $child?->nama_anak ?? 'Anak'),
            'age_text' => $child?->tanggal_lahir ? $this->ageLabel($child->tanggal_lahir) : '-',
            'gender' => $this->genderLabel((string) ($child?->jenis_kelamin ?? '')),
            'parent_name' => (string) ($parent?->name ?? 'Orang Tua'),
            'parent_phone' => (string) ($parent?->phone ?? '-'),
            'risk_status' => NutritionStatusHelper::riskLabel($status),
            'bbu_status' => NutritionStatusHelper::bbuStatus($latest),
            'tbu_status' => NutritionStatusHelper::tbuStatus($latest),
            'bbtb_status' => NutritionStatusHelper::bbtbStatus($latest),
            'weight_kg' => (float) ($latest?->berat ?? 0),
            'height_cm' => (float) ($latest?->tinggi ?? 0),
            'zscore_tbu' => $latest?->z_tbu !== null ? (float) $latest->z_tbu : 0,
            'last_measurement_date' => optional($latest?->tanggal_ukur)->toDateString() ?: '-',
            'is_anomaly' => (bool) ($latest?->is_anomaly ?? false),
            'has_consultation' => true,
            'consultation_id' => (int) $room->id,
        ];
    }

    private function nutritionistChildDetailPayload(ConsultationRoom $room): array
    {
        $child = $room->child;
        $latest = $child?->measurements()->latest('tanggal_ukur')->latest('id')->first();
        $histories = $child?->measurements()->latest('tanggal_ukur')->latest('id')->take(8)->get() ?? collect();
        $status = NutritionStatusHelper::getStatus($latest, $latest?->status_gabungan);

        return [
            'id' => (int) ($child?->id ?? 0),
            'name' => (string) ($child?->nama ?? $child?->nama_anak ?? 'Anak'),
            'age_text' => $child?->tanggal_lahir ? $this->ageLabel($child->tanggal_lahir) : '-',
            'gender' => $this->genderLabel((string) ($child?->jenis_kelamin ?? '')),
            'birth_date' => optional($child?->tanggal_lahir)->toDateString() ?: '-',
            'parent_name' => (string) ($room->user?->name ?? 'Orang Tua'),
            'parent_phone' => (string) ($room->user?->phone ?? '-'),
            'risk_status' => NutritionStatusHelper::riskLabel($status),
            'latest_measurement' => [
                'measurement_id' => (int) ($latest?->id ?? 0),
                'measurement_date' => optional($latest?->tanggal_ukur)->toDateString() ?: '-',
                'age_at_measurement' => $latest?->umur_bulan !== null ? ((int) round((float) $latest->umur_bulan)).' Bulan' : '-',
                'weight_kg' => (float) ($latest?->berat ?? 0),
                'height_cm' => (float) ($latest?->tinggi ?? 0),
                'position' => (string) ($latest?->cara_ukur ?? '-'),
            ],
            'zscore_result' => [
                'bbu_score' => $latest?->z_bbu !== null ? (float) $latest->z_bbu : 0,
                'bbu_status' => NutritionStatusHelper::bbuStatus($latest),
                'tbu_score' => $latest?->z_tbu !== null ? (float) $latest->z_tbu : 0,
                'tbu_status' => NutritionStatusHelper::tbuStatus($latest),
                'bbtb_score' => $latest?->z_bbtb !== null ? (float) $latest->z_bbtb : 0,
                'bbtb_status' => NutritionStatusHelper::bbtbStatus($latest),
            ],
            'interpretation' => $this->childInterpretation($status, $latest),
            'short_histories' => $histories->map(fn (Measurement $measurement): array => [
                'date' => optional($measurement->tanggal_ukur)->toDateString() ?: '-',
                'weight_kg' => (float) $measurement->berat,
                'height_cm' => (float) $measurement->tinggi,
                'risk_status' => NutritionStatusHelper::riskLabel(NutritionStatusHelper::getStatus($measurement, $measurement->status_gabungan)),
            ])->values(),
            'has_consultation' => true,
            'consultation_id' => (int) $room->id,
            'notes' => [],
        ];
    }

    private function childInterpretation(string $status, ?Measurement $measurement): string
    {
        if (!$measurement) {
            return 'Belum ada pengukuran terbaru untuk anak ini.';
        }

        return match (NutritionStatusHelper::riskLabel($status)) {
            'Risiko Tinggi' => 'Anak perlu pemantauan intensif dan tindak lanjut konsultasi gizi.',
            'Perlu Pantau' => 'Anak perlu dipantau berkala sesuai hasil pengukuran terbaru.',
            'Stabil' => 'Status anak stabil berdasarkan pengukuran terbaru.',
            default => 'Lengkapi pengukuran untuk melihat interpretasi status gizi.',
        };
    }

    private function genderLabel(string $gender): string
    {
        return match (mb_strtoupper(trim($gender))) {
            'L' => 'Laki-laki',
            'P' => 'Perempuan',
            default => $gender !== '' ? $gender : '-',
        };
    }

    private function nutritionistRoomsQuery(string $expertId)
    {
        return ConsultationRoom::query()
            ->with(['user', 'child.measurements'])
            ->where('expert_id', $expertId);
    }

    private function resolveNutritionistExpertId($nutritionist, $user): string
    {
        $expertId = Schema::hasColumn('nutritionists', 'expert_id')
            ? trim((string) ($nutritionist->expert_id ?? ''))
            : '';
        if ($expertId !== '') {
            return $expertId;
        }

        $expertId = ConsultationRoom::query()
            ->where('expert_name', (string) ($user->name ?? ''))
            ->whereNotNull('expert_id')
            ->value('expert_id');

        $expertId = trim((string) ($expertId ?: 'expert-'.$user->id));
        if (Schema::hasColumn('nutritionists', 'expert_id')) {
            $nutritionist->forceFill(['expert_id' => $expertId])->save();
        }

        return $expertId;
    }

    private function roomPayload(ConsultationRoom $room): array
    {
        $child = $room->child;
        $parent = $room->user;
        $measurements = $child?->measurements()
            ->orderBy('tanggal_ukur')
            ->get() ?? collect();
        $latest = $measurements->last();
        $previous = $measurements->count() > 1 ? $measurements->slice(-2, 1)->first() : null;
        $status = (string) ($latest?->status_gabungan ?? 'Belum Diukur');
        $risk = $this->riskLevel($status, $latest, $previous);

        return [
            'id' => $room->id,
            'parent_id' => $room->user_id,
            'parent_name' => (string) ($parent?->name ?? 'Orang Tua'),
            'child_id' => $room->child_id,
            'child_name' => (string) ($child?->nama ?? $child?->nama_anak ?? 'Anak'),
            'child_age' => $child?->tanggal_lahir ? $this->ageLabel($child->tanggal_lahir) : '-',
            'child_gender' => (string) ($child?->jenis_kelamin ?? '-'),
            'status' => $status,
            'risk' => $risk,
            'last_message' => (string) ($room->last_message ?? ''),
            'last_message_at' => optional($room->last_message_at ?? $room->updated_at)->toISOString(),
            'unread_count' => ConsultationMessage::query()
                ->where('room_id', $room->id)
                ->where('sender_type', 'parent')
                ->where('is_read', false)
                ->count(),
            'room_status' => (string) $room->status,
            'latest_measurement' => $latest ? $this->measurementPayload($latest) : null,
            'previous_measurement' => $previous ? $this->measurementPayload($previous) : null,
            'weights' => $measurements->pluck('berat')->map(fn ($v) => (float) $v)->values(),
            'heights' => $measurements->pluck('tinggi')->map(fn ($v) => (float) $v)->values(),
            'z_bbu_scores' => $measurements->pluck('z_bbu')->map(fn ($v) => $v !== null ? (float) $v : null)->values(),
            'z_scores' => $measurements->pluck('z_tbu')->map(fn ($v) => (float) $v)->values(),
            'z_bbtb_scores' => $measurements->pluck('z_bbtb')->map(fn ($v) => $v !== null ? (float) $v : null)->values(),
            'measurement_dates' => $measurements->map(fn (Measurement $measurement) => optional($measurement->tanggal_ukur)->toDateString())->values(),
            'measurement_statuses' => $measurements->map(fn (Measurement $measurement) => (string) ($measurement->status_gabungan ?? ''))->values(),
            'weight_delta' => $latest && $previous ? (float) $latest->berat - (float) $previous->berat : null,
            'height_delta' => $latest && $previous ? (float) $latest->tinggi - (float) $previous->tinggi : null,
            'risk_reasons' => $this->riskReasons($status, $latest, $previous),
            'is_anomaly' => (bool) ($latest?->is_anomaly ?? false),
            'validation_status' => (string) ($latest?->validation_status ?? 'valid'),
            'validation_note' => (string) ($latest?->validation_note ?? ''),
            'monitoring_status' => (string) ($latest?->monitoring_status ?? 'normal'),
            'is_confirmed_by_parent' => (bool) ($latest?->is_confirmed_by_parent ?? false),
        ];
    }

    private function nutritionistDisplayPayload(?Nutritionist $nutritionist): array
    {
        if (! $nutritionist) {
            return [
                'name' => '',
                'specialization' => '',
                'asset_image' => '',
                'online' => null,
            ];
        }

        $name = trim((string) ($nutritionist->user?->name ?? ''));
        $title = trim((string) ($nutritionist->title ?? ''));
        if ($name !== '' && $title !== '') {
            $name = trim($name.', '.$title);
        }

        return [
            'name' => $name,
            'specialization' => (string) ($nutritionist->specialization ?? ''),
            'asset_image' => $nutritionist->user?->avatar ? asset($nutritionist->user->avatar) : '',
            'online' => (bool) ($nutritionist->user?->last_active_at?->gte(now()->subMinutes(5))),
        ];
    }

    private function messagePayload(ConsultationMessage $message): array
    {
        return [
            'id' => $message->id,
            'sender_type' => (string) $message->sender_type,
            'message' => (string) $message->message,
            'is_read' => (bool) $message->is_read,
            'created_at' => optional($message->created_at)->toISOString(),
        ];
    }

    private function normalizeRoomStatus(string $status): string
    {
        return match (mb_strtolower(trim($status))) {
            'aktif', 'menunggu', 'active' => 'active',
            'selesai', 'closed' => 'closed',
            default => 'pending',
        };
    }

    private function focusTag(?string $specialization): string
    {
        $value = mb_strtolower((string) $specialization);
        if (str_contains($value, 'stunting') || str_contains($value, 'tumbuh') || str_contains($value, 'tinggi')) {
            return 'growth';
        }
        if (str_contains($value, 'berat') || str_contains($value, 'gizi kurang') || str_contains($value, 'underweight')) {
            return 'weight';
        }
        if (str_contains($value, 'obes') || str_contains($value, 'lebih')) {
            return 'obesity';
        }
        return 'general';
    }

    private function initialAnalysisMessage(?ConsultationRoom $room): ?string
    {
        $measurement = $room?->child?->measurements()
            ->orderByDesc('tanggal_ukur')
            ->first();

        if (!$measurement) {
            return null;
        }

        return implode("\n", [
            'Hasil Analisis Anak',
            'Berat Badan: '.number_format((float) $measurement->berat, 1).' kg',
            'Tinggi Badan: '.number_format((float) $measurement->tinggi, 0).' cm',
            'Status WHO: '.(string) ($measurement->status_gabungan ?? 'Belum Diukur'),
            'Z-score BB/U: '.($measurement->z_bbu !== null ? number_format((float) $measurement->z_bbu, 1) : '-'),
            'Z-score TB/U: '.($measurement->z_tbu !== null ? number_format((float) $measurement->z_tbu, 1) : '-'),
            'Z-score BB/TB: '.($measurement->z_bbtb !== null ? number_format((float) $measurement->z_bbtb, 1) : '-'),
            'Status Validasi: '.$this->validationLabel((string) ($measurement->validation_status ?? 'valid')),
            'Status Pemantauan: '.$this->monitoringLabel((string) ($measurement->monitoring_status ?? 'normal')),
            'Catatan: '.((string) ($measurement->validation_note ?? '') ?: '-'),
            'Tanggal Pengukuran: '.optional($measurement->tanggal_ukur)->toDateString(),
        ]);
    }

    private function validationLabel(string $status): string
    {
        return match ($status) {
            'perlu_ukur_ulang' => 'Perlu Ukur Ulang',
            default => 'Valid',
        };
    }

    private function monitoringLabel(string $status): string
    {
        return match ($status) {
            'perlu_dipantau' => 'Perlu Dipantau',
            default => 'Normal',
        };
    }

    private function measurementPayload(Measurement $measurement): array
    {
        return [
            'id' => $measurement->id,
            'berat' => (float) $measurement->berat,
            'tinggi' => (float) $measurement->tinggi,
            'tanggal_ukur' => optional($measurement->tanggal_ukur)->toDateString(),
            'status_gabungan' => (string) ($measurement->status_gabungan ?? ''),
            'z_bbu' => $measurement->z_bbu !== null ? (float) $measurement->z_bbu : null,
            'z_tbu' => $measurement->z_tbu !== null ? (float) $measurement->z_tbu : null,
            'z_bbtb' => $measurement->z_bbtb !== null ? (float) $measurement->z_bbtb : null,
            'is_anomaly' => (bool) $measurement->is_anomaly,
            'validation_status' => (string) ($measurement->validation_status ?? 'valid'),
            'validation_note' => (string) ($measurement->validation_note ?? ''),
            'monitoring_status' => (string) ($measurement->monitoring_status ?? 'normal'),
            'is_confirmed_by_parent' => (bool) ($measurement->is_confirmed_by_parent ?? false),
        ];
    }

    private function riskLevel(string $status, ?Measurement $measurement, ?Measurement $previous = null): string
    {
        $value = mb_strtolower($status);
        if (str_contains($value, 'berat') || str_contains($value, 'severely') || str_contains($value, 'buruk')) {
            return 'high';
        }
        if ($measurement && (($measurement->z_tbu ?? 0) <= -3 || ($measurement->z_bbu ?? 0) <= -3 || ($measurement->z_bbtb ?? 0) <= -3)) {
            return 'high';
        }
        if (str_contains($value, 'stunting') || str_contains($value, 'kurang') || str_contains($value, 'under') || str_contains($value, 'rendah')) {
            return 'warning';
        }
        if ($measurement && (($measurement->z_tbu ?? 0) <= -2 || ($measurement->z_bbu ?? 0) <= -2 || ($measurement->z_bbtb ?? 0) <= -2)) {
            return 'warning';
        }
        if ($measurement && $previous) {
            $weightDown = (float) $measurement->berat < (float) $previous->berat;
            $heightStagnant = (float) $measurement->tinggi <= (float) $previous->tinggi;
            $statusWorse = $this->statusSeverity($measurement->status_gabungan) > $this->statusSeverity($previous->status_gabungan);
            if ($weightDown || $heightStagnant || $statusWorse) {
                return 'warning';
            }
        }
        return 'normal';
    }

    private function riskReasons(string $status, ?Measurement $measurement, ?Measurement $previous): array
    {
        $reasons = [];
        $value = mb_strtolower($status);
        if (str_contains($value, 'stunting')) {
            $reasons[] = 'Stunting';
        }
        if (str_contains($value, 'kurang') || str_contains($value, 'under')) {
            $reasons[] = 'Gizi kurang';
        }
        if ($measurement && (($measurement->z_tbu ?? 0) < -2 || ($measurement->z_bbu ?? 0) < -2 || ($measurement->z_bbtb ?? 0) < -2)) {
            $reasons[] = 'Z-score < -2';
        }
        if ($measurement && $previous && (float) $measurement->berat < (float) $previous->berat) {
            $reasons[] = 'BB turun';
        }
        if ($measurement && $previous && (float) $measurement->tinggi <= (float) $previous->tinggi) {
            $reasons[] = 'TB stagnan';
        }
        if ($measurement && $previous && $this->statusSeverity($measurement->status_gabungan) > $this->statusSeverity($previous->status_gabungan)) {
            $reasons[] = 'Status memburuk';
        }
        return array_values(array_unique($reasons));
    }

    private function statusSeverity(?string $status): int
    {
        $value = mb_strtolower((string) $status);
        if (str_contains($value, 'buruk') || str_contains($value, 'severely')) {
            return 3;
        }
        if (str_contains($value, 'stunting') || str_contains($value, 'kurang') || str_contains($value, 'under') || str_contains($value, 'rendah')) {
            return 2;
        }
        if (str_contains($value, 'lebih') || str_contains($value, 'obes')) {
            return 1;
        }
        return 0;
    }

    private function ageLabel($birthDate): string
    {
        $birth = \Carbon\Carbon::parse($birthDate);
        $now = now();
        $diff = $birth->diff($now);
        $years = (int) $diff->y;
        $months = (int) $diff->m;
        $totalMonths = ($years * 12) + $months;

        if ($years < 2) {
            return max(0, $totalMonths).' Bulan';
        }
        if ($months <= 0) {
            return $years.' Tahun';
        }
        return $years.' Tahun '.$months.' Bulan';
    }
}



