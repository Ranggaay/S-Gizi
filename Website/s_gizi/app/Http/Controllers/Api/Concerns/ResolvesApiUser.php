<?php

namespace App\Http\Controllers\Api\Concerns;

use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

trait ResolvesApiUser
{
    private function userFromToken(Request $request): ?User
    {
        $token = $request->bearerToken();
        if (!$token) {
            return null;
        }

        $user = User::query()->where('api_token', $token)->first();
        if ($user) {
            $this->markUserActive($user);
        }

        return $user;
    }

    private function markUserActive(User $user): void
    {
        $now = now();
        $recentlyActive = $user->last_active_at && $user->last_active_at->gt($now->copy()->subMinutes(5));

        if (! $recentlyActive) {
            $user->forceFill(['last_active_at' => $now])->saveQuietly();
        }

        if ($user->nutritionist) {
            $nutritionistRecentlyActive = $user->nutritionist->last_active_at
                && $user->nutritionist->last_active_at->gt($now->copy()->subMinutes(5));

            if (! $user->nutritionist->is_online || ! $nutritionistRecentlyActive) {
                $user->nutritionist->forceFill([
                    'is_online' => true,
                    'last_active_at' => $now,
                ])->saveQuietly();
            }
        }
    }

    private function unauthenticated(): JsonResponse
    {
        return response()->json([
            'message' => 'Token tidak valid atau belum login.',
        ], 401);
    }
}
