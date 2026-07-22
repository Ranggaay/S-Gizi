<?php

namespace App\Http\Middleware;

use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureRole
{
    // Kode ini digunakan untuk memeriksa role pengguna sebelum memberikan akses ke endpoint.
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        // PRESENTASI TA: Middleware membatasi endpoint berdasarkan role pengguna.
        $user = auth()->user();
        if (! $user && $request->bearerToken()) {
            $user = User::query()->where('api_token', $request->bearerToken())->first();
        }

        $role = mb_strtolower(trim((string) ($user?->role ?? '')));
        $allowed = collect($roles)
            ->flatMap(fn ($role) => explode(',', $role))
            ->map(fn ($role) => mb_strtolower(trim($role)))
            ->filter()
            ->values();

        if (! $user || ! $allowed->contains($role)) {
            return response()->json(['message' => 'Akses tidak diizinkan.'], 403);
        }

        return $next($request);
    }
}
