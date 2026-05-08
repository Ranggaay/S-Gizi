<?php

use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ChildController;
use App\Http\Controllers\Admin\FoodConditionController;
use App\Http\Controllers\Admin\FoodController;
use App\Http\Controllers\Admin\ArticleController;
use App\Http\Controllers\Admin\LmsDataController;
use App\Http\Controllers\Admin\MeasurementController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('admin.dashboard'));

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/', fn () => redirect()->route('admin.dashboard'));
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::resource('children', ChildController::class)->except(['show']);
    Route::resource('foods', FoodController::class)->except(['show']);
    Route::resource('articles', ArticleController::class)->only(['index', 'store', 'update', 'destroy']);
    Route::get('/lms', [LmsDataController::class, 'index'])->name('lms.index');
    Route::post('/lms', [LmsDataController::class, 'store'])->name('lms.store');
    Route::put('/lms/{type}/{id}', [LmsDataController::class, 'update'])->name('lms.update');
    Route::delete('/lms/{type}/{id}', [LmsDataController::class, 'destroy'])->name('lms.destroy');

    Route::get('/food-conditions', [FoodConditionController::class, 'index'])->name('food_conditions.index');
    Route::post('/food-conditions', [FoodConditionController::class, 'store'])->name('food_conditions.store');
    Route::delete('/food-conditions/{foodCondition}', [FoodConditionController::class, 'destroy'])->name('food_conditions.destroy');

    Route::get('/measurements', [MeasurementController::class, 'index'])->name('measurements.index');
    Route::get('/measurements/export', [MeasurementController::class, 'export'])->name('measurements.export');
});
