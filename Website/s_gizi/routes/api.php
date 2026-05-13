<?php

use App\Http\Controllers\Api\HasilController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChildController;
use App\Http\Controllers\Api\GiziController;
use App\Http\Controllers\Api\ArticleController;
use App\Http\Controllers\Api\NewsController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\RecommendationController;
use App\Http\Controllers\Api\ConsultationController;
use Illuminate\Support\Facades\Route;

Route::post('/hasil', [HasilController::class, 'store']);
Route::post('/send-otp', [AuthController::class, 'sendOtp'])->middleware('throttle:5,1');
Route::post('/verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
Route::post('/auth/send-otp', [AuthController::class, 'sendOtp'])->middleware('throttle:5,1');
Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
Route::get('/profile', [ProfileController::class, 'show']);
Route::put('/profile', [ProfileController::class, 'update']);
Route::apiResource('/children', ChildController::class)->except(['show']);
Route::post('/gizi/hitung', [GiziController::class, 'hitung']);
Route::get('/gizi/riwayat/{childId}', [GiziController::class, 'riwayat']);
Route::get('/riwayat/{childId}', [GiziController::class, 'riwayat']);
Route::get('/rekomendasi/{status}', [RecommendationController::class, 'show']);
Route::get('/news', [NewsController::class, 'index']);
Route::get('/articles', [ArticleController::class, 'index']);
Route::get('/consultation/rooms', [ConsultationController::class, 'rooms']);
Route::post('/consultation/rooms', [ConsultationController::class, 'openRoom']);
Route::get('/consultation/rooms/{roomId}/messages', [ConsultationController::class, 'messages']);
Route::post('/consultation/rooms/{roomId}/messages', [ConsultationController::class, 'sendMessage']);
Route::post('/consultation/rooms/{roomId}/expert-reply', [ConsultationController::class, 'sendExpertReply']);
Route::patch('/consultation/rooms/{roomId}/status', [ConsultationController::class, 'updateStatus']);

