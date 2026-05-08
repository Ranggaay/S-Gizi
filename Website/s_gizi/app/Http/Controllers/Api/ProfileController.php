<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Api\Concerns\ResolvesApiUser;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

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
        ]);

        $user->update($validated);

        return response()->json([
            'data' => [
                'id' => $user->id,
                'phone' => $user->phone,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role ?? 'orang_tua',
                'children_count' => $user->children()->count(),
                'joined_at' => optional($user->created_at)->toDateString(),
            ],
        ]);
    }
}
