<?php

use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\ChildController;
use App\Http\Controllers\Admin\FoodConditionController;
use App\Http\Controllers\Admin\FoodController;
use App\Http\Controllers\Admin\ArticleController;
use App\Http\Controllers\Admin\AdminPageController;
use App\Http\Controllers\Admin\LmsDataController;
use App\Http\Controllers\Admin\MeasurementController;
use App\Http\Controllers\Nutritionist\NutritionistWebController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('admin.dashboard'));

Route::middleware('guest')->group(function () {
    Route::get('/admin/login', [AdminAuthController::class, 'showLogin'])->name('admin.login');
    Route::post('/admin/login', [AdminAuthController::class, 'login'])->name('admin.login.store');
    Route::get('/admin/lupa-password', [AdminAuthController::class, 'showForgotPassword'])->name('admin.password.request');
    Route::post('/admin/lupa-password', [AdminAuthController::class, 'sendResetLink'])->name('admin.password.email');
    Route::get('/admin/reset-password/{token}', [AdminAuthController::class, 'showResetPassword'])->name('password.reset');
    Route::post('/admin/reset-password', [AdminAuthController::class, 'resetPassword'])->name('admin.password.update');
});

Route::prefix('admin')->name('admin.')->group(function () {
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');
});

Route::prefix('admin')->name('admin.')->middleware('admin.web')->group(function () {
    Route::get('/', fn () => redirect()->route('admin.dashboard'));
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::get('/monitoring-anak', [AdminPageController::class, 'monitoring'])->name('monitoring');
    Route::get('/konsultasi', [AdminPageController::class, 'consultations'])->name('consultations');
    Route::get('/konsultasi/anak/{child}', [AdminPageController::class, 'openChildConsultation'])->name('consultations.child');
    Route::get('/konsultasi/orang-tua/{parent}', [AdminPageController::class, 'openParentConsultation'])->name('consultations.parent');
    Route::get('/konsultasi/ahli-gizi/{nutritionist}', [AdminPageController::class, 'openNutritionistConsultations'])->name('consultations.nutritionist');
    Route::get('/orang-tua', [AdminPageController::class, 'parents'])->name('parents');
    Route::get('/orang-tua/tambah', [AdminPageController::class, 'createParent'])->name('parents.create');
    Route::post('/orang-tua', [AdminPageController::class, 'storeParent'])->name('parents.store');
    Route::patch('/orang-tua/{parent}', [AdminPageController::class, 'updateParent'])->name('parents.update');
    Route::patch('/orang-tua/{parent}/nonaktifkan', [AdminPageController::class, 'deactivateParent'])->middleware('super.admin')->name('parents.deactivate');
    Route::delete('/orang-tua/{parent}', [AdminPageController::class, 'destroyParent'])->middleware('super.admin')->name('parents.destroy');
    Route::get('/orang-tua/{parent}', [AdminPageController::class, 'parentDetail'])->name('parents.show');
    Route::get('/ahli-gizi', [AdminPageController::class, 'nutritionists'])->name('nutritionists');
    Route::get('/ahli-gizi/tambah', [AdminPageController::class, 'createNutritionist'])->name('nutritionists.create');
    Route::post('/ahli-gizi', [AdminPageController::class, 'storeNutritionist'])->name('nutritionists.store');
    Route::get('/ahli-gizi/{nutritionist}/edit', [AdminPageController::class, 'editNutritionist'])->name('nutritionists.edit');
    Route::put('/ahli-gizi/{nutritionist}', [AdminPageController::class, 'updateNutritionist'])->name('nutritionists.update');
    Route::patch('/ahli-gizi/{nutritionist}/nonaktifkan', [AdminPageController::class, 'deactivateNutritionist'])->name('nutritionists.deactivate');
    Route::patch('/ahli-gizi/{nutritionist}/aktifkan', [AdminPageController::class, 'activateNutritionist'])->name('nutritionists.activate');
    Route::get('/ahli-gizi/{nutritionist}', [AdminPageController::class, 'nutritionistDetail'])->name('nutritionists.show');
    Route::get('/pengaturan', [AdminPageController::class, 'settings'])->name('settings');
    Route::patch('/pengaturan/profil', [AdminPageController::class, 'updateProfile'])->name('settings.profile.update');
    Route::patch('/pengaturan/password', [AdminPageController::class, 'updatePassword'])->name('settings.password.update');
    Route::post('/pengaturan/admin', [AdminPageController::class, 'storeAdmin'])->middleware('super.admin')->name('settings.admin.store');
    Route::patch('/pengaturan/admin/{admin}', [AdminPageController::class, 'updateAdmin'])->middleware('super.admin')->name('settings.admin.update');
    Route::patch('/pengaturan/admin/{admin}/nonaktifkan', [AdminPageController::class, 'deactivateAdmin'])->middleware('super.admin')->name('settings.admin.deactivate');

    Route::patch('/children/{child}/restore', [ChildController::class, 'restore'])->withTrashed()->name('children.restore');
    Route::delete('/children/{child}', [ChildController::class, 'destroy'])->middleware('super.admin')->name('children.destroy');
    Route::resource('children', ChildController::class)->except(['destroy'])->withTrashed(['show']);
    Route::patch('/foods/{food}/archive', [FoodController::class, 'archive'])->name('foods.archive');
    Route::patch('/foods/{food}/approve', [FoodController::class, 'approve'])->name('foods.approve');
    Route::patch('/foods/{food}/reject', [FoodController::class, 'reject'])->name('foods.reject');
    Route::resource('foods', FoodController::class);
    Route::patch('/articles/{article}/approve', [ArticleController::class, 'approve'])->name('articles.approve');
    Route::patch('/articles/{article}/reject', [ArticleController::class, 'reject'])->name('articles.reject');
    Route::resource('articles', ArticleController::class)->only(['index', 'store', 'update', 'destroy']);
    Route::get('/lms', [LmsDataController::class, 'index'])->name('lms.index');
    Route::post('/lms', [LmsDataController::class, 'store'])->name('lms.store');
    Route::put('/lms/{type}/{id}', [LmsDataController::class, 'update'])->name('lms.update');
    Route::delete('/lms/{type}/{id}', [LmsDataController::class, 'destroy'])->name('lms.destroy');

    Route::get('/food-conditions', [FoodConditionController::class, 'index'])->name('food_conditions.index');
    Route::post('/food-conditions', [FoodConditionController::class, 'store'])->name('food_conditions.store');
    Route::delete('/food-conditions/{foodCondition}', [FoodConditionController::class, 'destroy'])->name('food_conditions.destroy');

    Route::get('/measurements', [MeasurementController::class, 'index'])->name('measurements.index');
});

Route::prefix('nutritionist')->name('nutritionist.')->middleware('nutritionist.web')->group(function () {
    Route::get('/', fn () => redirect()->route('nutritionist.dashboard'));
    Route::get('/dashboard', [NutritionistWebController::class, 'dashboard'])->name('dashboard');
    Route::get('/konsultasi', [NutritionistWebController::class, 'consultations'])->name('consultations');
    Route::post('/konsultasi/{room}/messages', [NutritionistWebController::class, 'sendMessage'])->name('consultations.messages.store');
    Route::post('/konsultasi/{room}/selesai', [NutritionistWebController::class, 'closeConsultation'])->name('consultations.close');
    Route::get('/konsultasi/{room}/anak', [NutritionistWebController::class, 'childDetail'])->name('consultations.child');
    Route::post('/konsultasi/{room}/catatan', [NutritionistWebController::class, 'storeNote'])->name('consultations.notes.store');
    Route::get('/rekomendasi', fn () => redirect()->route('nutritionist.recommendations.manage'))->name('recommendations');
    Route::get('/rekomendasi/manajemen', [NutritionistWebController::class, 'recommendations'])->name('recommendations.manage');
    Route::get('/rekomendasi/kirim', [NutritionistWebController::class, 'recommendations'])->defaults('mode', 'send')->name('recommendations.send');
    Route::post('/rekomendasi', [NutritionistWebController::class, 'storeRecommendation'])->name('recommendations.store');
    Route::put('/rekomendasi/{food}', [NutritionistWebController::class, 'updateRecommendation'])->name('recommendations.update');
    Route::patch('/rekomendasi/{food}/arsip', [NutritionistWebController::class, 'archiveRecommendation'])->name('recommendations.archive');
    Route::delete('/rekomendasi/{food}', [NutritionistWebController::class, 'destroyRecommendation'])->name('recommendations.destroy');
    Route::post('/konsultasi/{room}/rekomendasi', [NutritionistWebController::class, 'sendRecommendation'])->name('consultations.recommendations.send');
    Route::get('/artikel', fn () => redirect()->route('nutritionist.articles.manage'))->name('articles');
    Route::get('/artikel/manajemen', [NutritionistWebController::class, 'articles'])->name('articles.manage');
    Route::get('/artikel/kirim', [NutritionistWebController::class, 'articles'])->defaults('mode', 'send')->name('articles.send');
    Route::post('/artikel', [NutritionistWebController::class, 'storeArticle'])->name('articles.store');
    Route::put('/artikel/{article}', [NutritionistWebController::class, 'updateArticle'])->name('articles.update');
    Route::patch('/artikel/{article}/arsip', [NutritionistWebController::class, 'archiveArticle'])->name('articles.archive');
    Route::delete('/artikel/{article}', [NutritionistWebController::class, 'destroyArticle'])->name('articles.destroy');
    Route::post('/konsultasi/{room}/artikel', [NutritionistWebController::class, 'shareArticle'])->name('consultations.articles.share');
    Route::get('/notifikasi', [NutritionistWebController::class, 'notifications'])->name('notifications');
    Route::post('/notifikasi/{notification}/read', [NutritionistWebController::class, 'readNotification'])->name('notifications.read');
    Route::post('/notifikasi/read-all', [NutritionistWebController::class, 'readAllNotifications'])->name('notifications.read_all');
    Route::get('/profil', [NutritionistWebController::class, 'profile'])->name('profile');
    Route::put('/profil', [NutritionistWebController::class, 'updateProfile'])->name('profile.update');
    Route::put('/profil/status', [NutritionistWebController::class, 'updateStatus'])->name('profile.status');
    Route::put('/profil/password', [NutritionistWebController::class, 'updatePassword'])->name('profile.password');
});
