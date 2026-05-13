<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Child;
use App\Models\User;
use App\Models\Makanan;
use App\Models\Measurement;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        return view('admin.dashboard', [
            'countChildren' => Child::query()->count(),
            'countUsers' => User::query()->count(),
            'countMeasurements' => Measurement::query()->count(),
            'countFoods' => Makanan::query()->count(),
            'statusDistribution' => Measurement::query()
                ->selectRaw('status_gabungan, count(*) as total')
                ->groupBy('status_gabungan')
                ->orderByDesc('total')
                ->get(),
        ]);
    }
}

