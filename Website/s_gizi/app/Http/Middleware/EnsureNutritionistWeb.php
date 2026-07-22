<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureNutritionistWeb
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::user();

        if (! $user) {
            return redirect()->route('admin.login');
        }

        if (! in_array($user->role, ['ahli_gizi', 'nutritionist', 'ahli gizi'], true) || ! $user->nutritionist) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('admin.login')->withErrors([
                'login' => 'Akses ahli gizi tidak diizinkan.',
            ]);
        }

        if (($user->account_status ?? 'Aktif') !== 'Aktif' || ($user->status ?? 'aktif') === 'nonaktif') {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('admin.login')->withErrors([
                'login' => 'Akun dinonaktifkan.',
            ]);
        }

        $request->session()->put('admin_last_activity', time());
        $user->forceFill(['last_active_at' => now()])->saveQuietly();
        $user->nutritionist->forceFill([
            'is_online' => true,
            'last_active_at' => now(),
        ])->saveQuietly();

        return $next($request);
    }
}
