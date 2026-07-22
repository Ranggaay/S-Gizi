<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\View\View;

class AuthController extends Controller
{
    public function showLogin(): View
    {
        return view('auth.admin-login');
    }

    public function login(Request $request): RedirectResponse
    {
        $validated = $request->validate([
            'login' => ['required', 'string', 'max:255'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $key = $this->throttleKey($request);
        if (RateLimiter::tooManyAttempts($key, 5)) {
            return back()
                ->withInput($request->only('login'))
                ->withErrors(['login' => 'Terlalu banyak percobaan login. Coba lagi dalam 5 menit.']);
        }

        $identifier = trim($validated['login']);
        $user = User::query()
            ->where(function ($query) use ($identifier) {
                $query->where('email', $identifier)
                    ->orWhere('phone', $this->normalizePhone($identifier));
            })
            ->whereIn('role', ['super_admin', 'admin_operasional', 'ahli_gizi', 'nutritionist', 'ahli gizi'])
            ->first();

        if (! $user) {
            RateLimiter::hit($key, 300);

            return back()->withInput($request->only('login'))->withErrors([
                'login' => 'Email tidak ditemukan.',
            ]);
        }

        if (! $user->password || ! Hash::check($validated['password'], $user->password)) {
            RateLimiter::hit($key, 300);

            return back()->withInput($request->only('login'))->withErrors([
                'login' => 'Password salah.',
            ]);
        }

        if (($user->account_status ?? 'Aktif') !== 'Aktif' || ($user->status ?? 'aktif') === 'nonaktif') {
            RateLimiter::hit($key, 300);

            return back()->withInput($request->only('login'))->withErrors([
                'login' => 'Akun dinonaktifkan.',
            ]);
        }

        RateLimiter::clear($key);
        Auth::login($user, false);
        $request->session()->regenerate();
        $request->session()->put('admin_last_activity', time());

        $user->update([
            'last_login_at' => now(),
            'last_active_at' => now(),
            'last_login_ip' => $request->ip(),
            'last_login_user_agent' => Str::limit((string) $request->userAgent(), 500, ''),
        ]);

        if (in_array($user->role, ['ahli_gizi', 'nutritionist', 'ahli gizi'], true)) {
            $user->nutritionist?->forceFill([
                'is_online' => true,
                'last_active_at' => now(),
            ])->saveQuietly();

            return redirect()->intended(route('nutritionist.dashboard'));
        }

        return redirect()->intended(route('admin.dashboard'));
    }

    public function logout(Request $request): RedirectResponse
    {
        $user = Auth::user();
        if ($user?->nutritionist) {
            $user->nutritionist->forceFill([
                'is_online' => false,
                'last_active_at' => now(),
            ])->saveQuietly();
        }

        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login')->with('status', 'Anda berhasil logout.');
    }

    public function showForgotPassword(): View
    {
        return view('auth.admin-forgot-password');
    }

    public function sendResetLink(Request $request): RedirectResponse
    {
        $request->validate(['email' => ['required', 'email']]);

        $status = Password::sendResetLink($request->only('email'));

        return $status === Password::RESET_LINK_SENT
            ? back()->with('status', 'Link reset password sudah dikirim jika email terdaftar.')
            : back()->withErrors(['email' => 'Email tidak ditemukan.']);
    }

    public function showResetPassword(Request $request, string $token): View
    {
        return view('auth.admin-reset-password', [
            'token' => $token,
            'email' => $request->query('email'),
        ]);
    }

    public function resetPassword(Request $request): RedirectResponse
    {
        $request->validate([
            'token' => ['required'],
            'email' => ['required', 'email'],
            'password' => ['required', 'confirmed', PasswordRule::min(8)],
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function (User $user, string $password) {
                $user->forceFill([
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        return $status === Password::PASSWORD_RESET
            ? redirect()->route('admin.login')->with('status', 'Password berhasil diperbarui.')
            : back()->withErrors(['email' => 'Token reset password tidak valid.']);
    }

    private function throttleKey(Request $request): string
    {
        return Str::lower((string) $request->input('login')).'|'.$request->ip();
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if ($digits === '') {
            return $phone;
        }
        if (str_starts_with($digits, '0')) {
            $digits = '62'.substr($digits, 1);
        }
        if (! str_starts_with($digits, '62')) {
            $digits = '62'.$digits;
        }

        return '+'.$digits;
    }
}
