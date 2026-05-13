<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\ConsultationMessage;
use App\Models\ConsultationRoom;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ConsultationController extends Controller
{
    use ResolvesApiUser;

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
                return [
                    'id' => $room->id,
                    'child_id' => $room->child_id,
                    'child_name' => (string) optional($room->child)->nama,
                    'expert_id' => (string) $room->expert_id,
                    'expert_name' => (string) $room->expert_name,
                    'specialization' => (string) ($room->specialization ?? ''),
                    'asset_image' => (string) ($room->asset_image ?? ''),
                    'online' => (bool) $room->online,
                    'status' => (string) $room->status,
                    'last_message' => (string) ($room->last_message ?? ''),
                    'last_message_at' => optional($room->last_message_at)->toISOString(),
                    'unread_count' => (int) $room->unread_count,
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

        $room = ConsultationRoom::query()->firstOrCreate(
            [
                'user_id' => $user->id,
                'child_id' => $child->id,
                'expert_id' => $validated['expert_id'],
            ],
            [
                'expert_name' => $validated['expert_name'],
                'specialization' => $validated['specialization'] ?? '',
                'asset_image' => $validated['asset_image'] ?? '',
                'online' => (bool) ($validated['online'] ?? false),
                'status' => 'aktif',
                'unread_count' => 0,
            ]
        );

        return response()->json([
            'data' => [
                'id' => $room->id,
                'child_id' => $room->child_id,
                'child_name' => (string) $child->nama,
                'expert_id' => (string) $room->expert_id,
                'expert_name' => (string) $room->expert_name,
                'specialization' => (string) ($room->specialization ?? ''),
                'asset_image' => (string) ($room->asset_image ?? ''),
                'online' => (bool) $room->online,
                'status' => (string) $room->status,
                'last_message' => (string) ($room->last_message ?? ''),
                'last_message_at' => optional($room->last_message_at)->toISOString(),
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
            'sender_type' => 'parent',
            'message' => $validated['message'],
            'is_read' => true,
        ]);

        $room->update([
            'status' => 'menunggu',
            'last_message' => $validated['message'],
            'last_message_at' => now(),
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
            'status' => ['required', 'in:aktif,menunggu,selesai'],
        ]);

        $room->update(['status' => $validated['status']]);

        return response()->json(['message' => 'Status berhasil diperbarui.']);
    }

    public function sendExpertReply(Request $request, int $roomId): JsonResponse
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
            'message' => ['required', 'string', 'max:3000'],
        ]);

        $message = ConsultationMessage::query()->create([
            'room_id' => $room->id,
            'sender_type' => 'expert',
            'message' => $validated['message'],
            'is_read' => false,
        ]);

        $room->update([
            'status' => 'aktif',
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
}

