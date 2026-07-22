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
// Register dengan OTP WA (flow baru)
Route::post('/auth/register/send-otp', [AuthController::class, 'sendRegisterOtp'])->middleware('throttle:5,1');
Route::post('/auth/register/verify', [AuthController::class, 'verifyRegisterOtp'])->middleware('throttle:10,1');

// Lupa password via WA
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,1');
Route::post('/auth/forgot-password/verify', [AuthController::class, 'verifyForgotPasswordOtp'])->middleware('throttle:10,1');
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:10,1');

// Login
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/login', [AuthController::class, 'login']);

// Register lama (tanpa OTP) — untuk kompatibilitas
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/register', [AuthController::class, 'register']);

// OTP login (phone-only flow lama)
Route::post('/send-otp', [AuthController::class, 'sendOtp'])->middleware('throttle:5,1');
Route::post('/verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
Route::post('/auth/send-otp', [AuthController::class, 'sendOtp'])->middleware('throttle:5,1');
Route::post('/auth/verify-otp', [AuthController::class, 'verifyOtp'])->middleware('throttle:10,1');
Route::get('/profile', [ProfileController::class, 'show']);
Route::put('/profile', [ProfileController::class, 'update']);
Route::put('/profile/password', [ProfileController::class, 'updatePassword']);
Route::post('/profile/logout-all', [ProfileController::class, 'logoutAllDevices']);
Route::delete('/profile', [ProfileController::class, 'destroy']);
Route::apiResource('/children', ChildController::class)->except(['show']);
Route::post('/gizi/hitung', [GiziController::class, 'hitung']);
Route::post('/parent/measurements/calculate', [GiziController::class, 'hitung']);
Route::post('/parent/measurements/{measurementId}/confirm', [GiziController::class, 'confirm']);
Route::get('/parent/measurements/{measurementId}/result', [GiziController::class, 'result']);
Route::get('/parent/measurements/{measurementId}/recommendations', [RecommendationController::class, 'forMeasurement']);
Route::get('/gizi/riwayat/{childId}', [GiziController::class, 'riwayat']);
Route::get('/riwayat/{childId}', [GiziController::class, 'riwayat']);
Route::get('/rekomendasi/{status}', [RecommendationController::class, 'show']);
Route::get('/news', [NewsController::class, 'index']);
Route::get('/articles', [ArticleController::class, 'index']);
Route::get('/consultation/rooms', [ConsultationController::class, 'rooms']);
Route::post('/consultation/rooms', [ConsultationController::class, 'openRoom']);
Route::post('/parent/consultations', [ConsultationController::class, 'openRoom']);
Route::get('/consultation/rooms/{roomId}/messages', [ConsultationController::class, 'messages']);
Route::post('/consultation/rooms/{roomId}/messages', [ConsultationController::class, 'sendMessage']);
Route::post('/consultation/rooms/{roomId}/expert-reply', [ConsultationController::class, 'sendExpertReply']);
Route::patch('/consultation/rooms/{roomId}/status', [ConsultationController::class, 'updateStatus']);
Route::patch('/consultation/rooms/{roomId}/shared-measurement', [ConsultationController::class, 'markMeasurementShared']);
Route::get('/nutritionists', [ConsultationController::class, 'nutritionists']);
Route::middleware('role:ahli_gizi,nutritionist,ahli gizi')->group(function () {
    Route::get('/nutritionist/dashboard', [ConsultationController::class, 'nutritionistDashboard']);
    Route::get('/nutritionist/profile', [ConsultationController::class, 'nutritionistProfile']);
    Route::put('/nutritionist/profile/status', [ConsultationController::class, 'updateNutritionistProfileStatus']);
    Route::get('/nutritionist/children', [ConsultationController::class, 'nutritionistChildren']);
    Route::get('/nutritionist/children/{childId}', [ConsultationController::class, 'nutritionistChildDetail']);
    Route::get('/nutritionist/rooms', [ConsultationController::class, 'nutritionistRooms']);
    Route::get('/nutritionist/consultations', [ConsultationController::class, 'nutritionistRooms']);
    Route::get('/nutritionist/notifications', [ConsultationController::class, 'nutritionistNotifications']);
    Route::post('/nutritionist/notifications/{id}/read', [ConsultationController::class, 'markNutritionistNotificationRead']);
    Route::post('/nutritionist/notifications/read-all', [ConsultationController::class, 'markAllNutritionistNotificationsRead']);
    Route::get('/nutritionist/rooms/{roomId}/messages', [ConsultationController::class, 'nutritionistMessages']);
    Route::get('/nutritionist/consultations/{roomId}', [ConsultationController::class, 'nutritionistMessages']);
    Route::get('/nutritionist/consultations/{roomId}/child-detail', [ConsultationController::class, 'nutritionistChildDetailFromChat']);
    Route::post('/nutritionist/rooms/{roomId}/messages', [ConsultationController::class, 'nutritionistSendMessage']);
    Route::post('/nutritionist/consultations/{roomId}/messages', [ConsultationController::class, 'nutritionistSendMessage']);
    Route::post('/nutritionist/consultations/{roomId}/close', [ConsultationController::class, 'nutritionistClose']);
    Route::post('/nutritionist/consultations/{roomId}/notes', [ConsultationController::class, 'storeNutritionistNote']);
});
