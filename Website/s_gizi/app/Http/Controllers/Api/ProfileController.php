<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class ProfileController extends Controller
{
    use ResolvesApiUser;

    public function show(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        return response()->json([
            'data' => [
                'id' => $user->id,
                'phone' => $user->phone,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'orang_tua',
                'parent_gender' => $user->parent_gender,
                'nutritionist' => $this->nutritionistPayload($user),
                'tanggal_lahir' => optional($user->tanggal_lahir)->toDateString(),
                'last_active_at' => optional($user->last_active_at)->toISOString(),
                'children_count' => $user->children()->count(),
                'joined_at' => optional($user->created_at)->toDateString(),
            ],
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'phone' => ['required', 'string', 'max:30'],
            'email' => ['nullable', 'email', 'max:160'],
            'parent_gender' => ['nullable', 'in:ayah,bunda'],
            'tanggal_lahir' => ['nullable', 'date', 'before_or_equal:today'],
            'specialization' => ['nullable', 'string', 'max:150'],
            'experience' => ['nullable', 'string', 'max:80'],
            'str_sip' => ['nullable', 'string', 'max:120'],
        ]);

        $user->update(collect($validated)->only([
            'name',
            'phone',
            'email',
            'parent_gender',
            'tanggal_lahir',
        ])->toArray());

        if ($user->nutritionist && collect($validated)->hasAny(['specialization', 'experience', 'str_sip'])) {
            $user->nutritionist->update(collect($validated)->only([
                'specialization',
                'experience',
                'str_sip',
            ])->toArray());
        }

        $user->refresh();

        return response()->json([
            'data' => [
                'id' => $user->id,
                'phone' => $user->phone,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'orang_tua',
                'parent_gender' => $user->parent_gender,
                'nutritionist' => $this->nutritionistPayload($user),
                'tanggal_lahir' => optional($user->tanggal_lahir)->toDateString(),
                'last_active_at' => optional($user->last_active_at)->toISOString(),
                'children_count' => $user->children()->count(),
                'joined_at' => optional($user->created_at)->toDateString(),
            ],
        ]);
    }

    public function updatePassword(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $validated = $request->validate([
            'old_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        if (!$user->password || !Hash::check($validated['old_password'], $user->password)) {
            return response()->json([
                'message' => 'Password lama tidak sesuai.',
            ], 422);
        }

        $user->forceFill([
            'password' => Hash::make($validated['password']),
        ])->save();

        return response()->json([
            'message' => 'Password berhasil diperbarui.',
        ]);
    }

    public function logoutAllDevices(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        $user->forceFill([
            'api_token' => null,
        ])->save();
        if ($user->nutritionist) {
            $user->nutritionist->forceFill([
                'is_online' => false,
                'last_active_at' => now(),
            ])->saveQuietly();
        }

        return response()->json([
            'message' => 'Berhasil logout dari semua perangkat.',
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $user = $this->userFromToken($request);
        if (!$user) {
            return $this->unauthenticated();
        }

        DB::transaction(function () use ($user) {
            $user->children()->delete();
            $user->delete();
        });

        return response()->json([
            'message' => 'Akun berhasil dihapus.',
        ]);
    }

    private function nutritionistPayload($user): ?array
    {
        $user->loadMissing('nutritionist');
        $nutritionist = $user->nutritionist;
        if (!$nutritionist) {
            return null;
        }

        return [
            'id' => $nutritionist->id,
            'expert_id' => $nutritionist->expert_id,
            'title' => $nutritionist->title,
            'specialization' => $nutritionist->specialization,
            'experience' => $nutritionist->experience,
            'experience_years' => $nutritionist->experience_years,
            'bio' => $nutritionist->bio,
            'str_sip' => $nutritionist->str_sip,
            'is_online' => $nutritionist->is_online,
            'is_available' => $nutritionist->is_available,
        ];
    }
}
