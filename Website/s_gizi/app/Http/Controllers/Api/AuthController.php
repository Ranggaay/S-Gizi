<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function sendOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'regex:/^(\+62|62|0)8[0-9]{7,13}$/'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $otp = app()->isProduction() ? (string) random_int(100000, 999999) : '123456';

        User::query()->updateOrCreate(
            ['phone' => $phone],
            [
                'role' => 'orang_tua',
                'otp_code' => $otp,
                'otp_expires_at' => now()->addMinutes(5),
            ]
        );

        return response()->json([
            'message' => 'OTP berhasil dikirim.',
            'phone' => $phone,
            'debug_otp' => app()->isProduction() ? null : $otp,
        ]);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'phone' => ['required', 'string'],
            'otp' => ['required', 'digits:6'],
        ]);

        $phone = $this->normalizePhone($validated['phone']);
        $user = User::query()->where('phone', $phone)->first();

        if (!$user || $user->otp_code !== $validated['otp'] || $user->otp_expires_at?->isPast()) {
            return response()->json([
                'message' => 'OTP salah atau sudah kedaluwarsa.',
            ], 422);
        }

        $user->forceFill([
            'api_token' => Str::random(80),
            'otp_code' => null,
            'otp_expires_at' => null,
        ])->save();

        return response()->json([
            'token' => $user->api_token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'phone' => $user->phone,
                'role' => $user->role,
            ],
        ]);
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if (str_starts_with($digits, '0')) {
            $digits = '62'.substr($digits, 1);
        }
        if (!str_starts_with($digits, '62')) {
            $digits = '62'.$digits;
        }

        return '+'.$digits;
    }
}
