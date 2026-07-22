<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdminWeb
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = Auth::user();

        if (! $user) {
            return redirect()->route('admin.login');
        }

        if (! in_array($user->role, ['super_admin', 'admin_operasional'], true)) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('admin.login')->withErrors([
                'login' => 'Akses admin tidak diizinkan.',
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

        $lastActivity = (int) $request->session()->get('admin_last_activity', time());
        if ((time() - $lastActivity) > 1800) {
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('admin.login')->withErrors([
                'login' => 'Sesi berakhir karena tidak aktif selama 30 menit.',
            ]);
        }

        $request->session()->put('admin_last_activity', time());

        return $next($request);
    }
}
