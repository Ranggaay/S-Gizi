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

        return User::query()->where('api_token', $token)->first();
    }

    private function unauthenticated(): JsonResponse
    {
        return response()->json([
            'message' => 'Token tidak valid atau belum login.',
        ], 401);
    }
}
