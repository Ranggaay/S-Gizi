<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\WhatsAppService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function __construct(private readonly WhatsAppService $wa) {}

    // ─── Register dengan OTP WA ───────────────────────────────────────────────

    /**
     * Step 1: validasi data pendaftaran, kirim OTP ke WA.
     */
    public function sendRegisterOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'          => ['required', 'string', 'max:120'],
            'phone'         => ['required', 'regex:/^(\+62|62|0)8[0-9]{7,13}$/'],
            'parent_gender' => ['required', 'in:ayah,bunda'],
            'password'      => ['required', 'confirmed', Password::min(8)],
        ]);

        $phone = $this->normalizePhone($validated['phone']);

        if (User::query()->where('phone', $phone)->exists()) {
            return response()->json(['message' => 'Nomor telepon sudah terdaftar.'], 422);
        }

        $otp = $this->generateOtp();

        Cache::put("register_otp:{$phone}", [
            'otp'           => $otp,
            'name'          => $validated['name'],
            'parent_gender' => $validated['parent_gender'],
            'password'      => Hash::make($validated['password']),
        ], now()->addMinutes(5));

        $sent = config('services.wa.enabled')
            ? $this->wa->sendOtp($phone, $otp)
            : true;

        return response()->json([
            'message'    => 'OTP telah dikirim ke WhatsApp Anda.',
            'phone'      => $phone,
            'debug_otp'  => config('services.wa.enabled') ? null : $otp,
        ], $sent || ! config('services.wa.enabled') ? 200 : 503);
    }

    /**
     * Step 2: verifikasi OTP, buat akun.
     */
    public function verifyRegisterOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'otp'   => ['required', 'digits:6'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $cached = Cache::get("register_otp:{$phone}");

        if (! $cached || $cached['otp'] !== $validated['otp']) {
            return response()->json(['message' => 'OTP salah atau sudah kedaluwarsa.'], 422);
        }

        if (User::query()->where('phone', $phone)->exists()) {
            Cache::forget("register_otp:{$phone}");
            return response()->json(['message' => 'Nomor telepon sudah terdaftar.'], 422);
        }

        Cache::forget("register_otp:{$phone}");

        $user = User::query()->create([
            'name'          => $cached['name'],
            'phone'         => $phone,
            'parent_gender' => $cached['parent_gender'],
            'role'          => 'orang_tua',
            'password'      => $cached['password'],
            'api_token'     => Str::random(80),
            'last_active_at' => now(),
        ]);

        return response()->json([
            'token' => $user->api_token,
            'user'  => $this->userPayload($user),
        ], 201);
    }

    // ─── Login ────────────────────────────────────────────────────────────────

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone'    => ['nullable', 'string'],
            'email'    => ['nullable', 'string'],
            'login'    => ['nullable', 'string'],
            'password' => ['required', 'string'],
        ]);

        $credential = trim((string) ($validated['login'] ?? $validated['email'] ?? $validated['phone'] ?? ''));
        if ($credential === '') {
            return response()->json(['message' => 'Nomor HP atau email wajib diisi.'], 422);
        }

        $user = str_contains($credential, '@')
            ? User::query()->where('email', $credential)->first()
            : User::query()->where('phone', $this->normalizePhone($credential))->first();

        if (! $user || ! $user->password || ! Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Nomor telepon atau password salah.'], 422);
        }

        $user->forceFill([
            'api_token'     => Str::random(80),
            'last_active_at' => now(),
        ])->save();
        $this->markNutritionistOnline($user);

        return response()->json([
            'token' => $user->api_token,
            'user'  => $this->userPayload($user),
        ]);
    }

    // ─── Lupa Password ───────────────────────────────────────────────────────

    public function forgotPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'regex:/^(\+62|62|0)8[0-9]{7,13}$/'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $user  = User::query()->where('phone', $phone)->first();

        if (! $user) {
            return response()->json(['message' => 'Nomor telepon tidak terdaftar.'], 404);
        }

        $otp = $this->generateOtp();

        $user->forceFill([
            'otp_code'       => $otp,
            'otp_expires_at' => now()->addMinutes(5),
        ])->saveQuietly();

        $sent = config('services.wa.enabled')
            ? $this->wa->sendPasswordResetOtp($phone, $otp)
            : true;

        return response()->json([
            'message'   => 'OTP telah dikirim ke WhatsApp Anda.',
            'debug_otp' => config('services.wa.enabled') ? null : $otp,
        ], $sent || ! config('services.wa.enabled') ? 200 : 503);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone'    => ['required', 'string'],
            'otp'      => ['required', 'digits:6'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $user  = User::query()->where('phone', $phone)->first();

        if (! $user || $user->otp_code !== $validated['otp'] || $user->otp_expires_at?->isPast()) {
            return response()->json(['message' => 'OTP salah atau sudah kedaluwarsa.'], 422);
        }

        $user->forceFill([
            'password'       => Hash::make($validated['password']),
            'otp_code'       => null,
            'otp_expires_at' => null,
            'api_token'      => Str::random(80),
            'last_active_at' => now(),
        ])->save();
        $this->markNutritionistOnline($user);

        return response()->json([
            'message' => 'Password berhasil diubah.',
            'token'   => $user->api_token,
            'user'    => $this->userPayload($user),
        ]);
    }

    public function verifyForgotPasswordOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'otp'   => ['required', 'digits:6'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $user  = User::query()->where('phone', $phone)->first();

        if (! $user) {
            return response()->json(['message' => 'Nomor telepon tidak terdaftar.'], 404);
        }

        if ($user->otp_code !== $validated['otp']) {
            return response()->json(['message' => 'OTP yang dimasukkan salah.'], 422);
        }

        if ($user->otp_expires_at?->isPast()) {
            return response()->json(['message' => 'OTP telah kedaluwarsa.'], 422);
        }

        return response()->json([
            'message' => 'OTP berhasil diverifikasi.',
        ]);
    }

    // ─── OTP login (phone-only flow lama) ────────────────────────────────────

    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'regex:/^(\+62|62|0)8[0-9]{7,13}$/'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $otp   = $this->generateOtp();

        User::query()->updateOrCreate(
            ['phone' => $phone],
            [
                'role'           => 'orang_tua',
                'otp_code'       => $otp,
                'otp_expires_at' => now()->addMinutes(5),
            ]
        );

        if (config('services.wa.enabled')) {
            $this->wa->sendOtp($phone, $otp);
        }

        return response()->json([
            'message'   => 'OTP berhasil dikirim.',
            'phone'     => $phone,
            'debug_otp' => config('services.wa.enabled') ? null : $otp,
        ]);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'otp'   => ['required', 'digits:6'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $user  = User::query()->where('phone', $phone)->first();

        if (! $user || $user->otp_code !== $validated['otp'] || $user->otp_expires_at?->isPast()) {
            return response()->json(['message' => 'OTP salah atau sudah kedaluwarsa.'], 422);
        }

        $user->forceFill([
            'api_token'      => Str::random(80),
            'otp_code'       => null,
            'otp_expires_at' => null,
            'last_active_at' => now(),
        ])->save();
        $this->markNutritionistOnline($user);

        return response()->json([
            'token' => $user->api_token,
            'user'  => $this->userPayload($user),
        ]);
    }

    // ─── Register lama (tanpa OTP) — dipertahankan untuk kompatibilitas ──────

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name'          => ['required', 'string', 'max:120'],
            'phone'         => ['required', 'regex:/^(\+62|62|0)8[0-9]{7,13}$/'],
            'parent_gender' => ['required', 'in:ayah,bunda'],
            'password'      => ['required', 'confirmed', Password::min(8)],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        if (User::query()->where('phone', $phone)->exists()) {
            return response()->json(['message' => 'Nomor telepon sudah terdaftar.'], 422);
        }

        $user = User::query()->create([
            'name'          => $validated['name'],
            'phone'         => $phone,
            'parent_gender' => $validated['parent_gender'],
            'role'          => 'orang_tua',
            'password'      => $validated['password'],
            'api_token'     => Str::random(80),
            'last_active_at' => now(),
        ]);

        return response()->json([
            'token' => $user->api_token,
            'user'  => $this->userPayload($user),
        ], 201);
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private function generateOtp(): string
    {
        return config('services.wa.enabled') ? (string) random_int(100000, 999999) : '123456';
    }

    private function userPayload(User $user): array
    {
        $user->loadMissing('nutritionist');
        $nutritionist = $user->nutritionist;

        return [
            'id'             => $user->id,
            'name'           => $user->name,
            'email'          => $user->email,
            'phone'          => $user->phone,
            'role'           => $user->role,
            'status'         => $user->status ?: (strtolower((string) $user->account_status) === 'nonaktif' ? 'nonaktif' : 'aktif'),
            'account_status' => $user->account_status,
            'avatar'         => $user->avatar,
            'parent_gender'  => $user->parent_gender,
            'last_active_at' => optional($user->last_active_at)->toISOString(),
            'children_count' => $user->children()->count(),
            'nutritionist'   => $nutritionist ? [
                'id'               => $nutritionist->id,
                'expert_id'        => $nutritionist->expert_id,
                'title'            => $nutritionist->title,
                'specialization'   => $nutritionist->specialization,
                'experience'       => $nutritionist->experience,
                'experience_years' => $nutritionist->experience_years,
                'bio'              => $nutritionist->bio,
                'str_sip'          => $nutritionist->str_sip,
                'is_online'        => $nutritionist->is_online,
                'is_available'     => $nutritionist->is_available,
                'max_consultation' => $nutritionist->max_consultation,
            ] : null,
        ];
    }

    private function markNutritionistOnline(User $user): void
    {
        $user->loadMissing('nutritionist');
        if (! $user->nutritionist) {
            return;
        }

        $user->nutritionist->forceFill([
            'is_online' => true,
            'last_active_at' => now(),
        ])->saveQuietly();
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if (str_starts_with($digits, '0')) {
            $digits = '62' . substr($digits, 1);
        }
        if (! str_starts_with($digits, '62')) {
            $digits = '62' . $digits;
        }

        return '+' . $digits;
    }
}
