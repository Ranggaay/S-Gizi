<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\GiziRequest;
use App\Services\GiziService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;

class HasilController extends Controller
{
    public function __construct(private readonly GiziService $giziService)
    {
    }

    public function store(GiziRequest $request): JsonResponse
    {
        try {
            $result = $this->giziService->hitung($request->validated());
            return response()->json($result, isset($result['error']) ? 422 : 200);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json(['error' => $e->getMessage()], 404);
        } catch (\Throwable $e) {
            Log::error('API hitung gizi gagal.', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json(['error' => 'Terjadi kesalahan saat menghitung status gizi.'], 422);
        }
    }
}

