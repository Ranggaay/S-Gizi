<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhatsAppService
{
    public function sendOtp(string $phone, string $otp): bool
    {
        $message = "Kode OTP S-Gizi Anda: *{$otp}*\n\nKode berlaku 5 menit. Jangan bagikan ke siapapun.";

        return $this->send($phone, $message);
    }

    public function sendPasswordResetOtp(string $phone, string $otp): bool
    {
        $message = "Kode reset password S-Gizi: *{$otp}*\n\nKode berlaku 5 menit. Jangan bagikan ke siapapun.";

        return $this->send($phone, $message);
    }

    private function send(string $phone, string $message): bool
    {
        $url = rtrim((string) config('services.wa.url'), '/') . '/send';
        $secret = (string) config('services.wa.secret');

        try {
            $response = Http::withHeaders(['x-secret-key' => $secret])
                ->timeout(10)
                ->post($url, compact('phone', 'message'));

            if (! $response->successful()) {
                Log::warning('WA service gagal kirim OTP.', [
                    'phone' => $phone,
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
            }

            return $response->successful();
        } catch (\Throwable $e) {
            Log::error('WA service tidak dapat dihubungi.', [
                'phone' => $phone,
                'error' => $e->getMessage(),
            ]);

            return false;
        }
    }
}
