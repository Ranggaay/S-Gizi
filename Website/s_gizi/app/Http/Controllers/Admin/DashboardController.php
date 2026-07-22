<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Helpers\NutritionStatusHelper;
use App\Models\Article;
use App\Models\Child;
use App\Models\ConsultationRoom;
use App\Models\User;
use App\Models\Makanan;
use App\Models\Measurement;
use App\Models\Nutritionist;
use Illuminate\Support\Carbon;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $latestMeasurements = Measurement::query()
            ->with(['child.user'])
            ->whereIn('id', function ($query) {
                $query->selectRaw('max(id)')
                    ->from('measurements')
                    ->groupBy('child_id');
            })
            ->latest('tanggal_ukur')
            ->get();

        $statusBuckets = Measurement::query()
            ->get()
            ->map(fn ($measurement) => NutritionStatusHelper::getStatus($measurement))
            ->countBy();

        $monthlyMeasurements = collect(range(5, 0))->map(function ($offset) {
            $month = now()->subMonths($offset);

            return [
                'label' => $month->translatedFormat('M'),
                'total' => Measurement::query()
                    ->whereYear('tanggal_ukur', $month->year)
                    ->whereMonth('tanggal_ukur', $month->month)
                    ->count(),
            ];
        });

        return view('admin.dashboard', [
            'countChildren' => Child::query()->count(),
            'countUsers' => User::query()->where('role', 'orang_tua')->count(),
            'countMeasurements' => Measurement::query()->count(),
            'countFoods' => Makanan::query()->count(),
            'countHighRisk' => $latestMeasurements
                ->filter(fn ($row) => in_array(NutritionStatusHelper::getStatus($row), [
                    NutritionStatusHelper::SANGAT_PENDEK,
                    NutritionStatusHelper::OBESITAS,
                    NutritionStatusHelper::GIZI_BURUK,
                    NutritionStatusHelper::PENDEK,
                    NutritionStatusHelper::GIZI_KURANG,
                    NutritionStatusHelper::GIZI_LEBIH,
                    NutritionStatusHelper::RISIKO_BB_LEBIH,
                ], true))
                ->count(),
            'countConsultations' => ConsultationRoom::query()->whereIn('status', ['active', 'waiting', 'open'])->count(),
            'countNutritionists' => Nutritionist::query()->where('is_online', true)->count(),
            'countArticles' => Article::query()->where('published', true)->count(),
            'statusDistribution' => $statusBuckets,
            'monthlyMeasurements' => $monthlyMeasurements,
            'consultationStats' => [
                'selesai' => ConsultationRoom::query()->whereIn('status', ['closed', 'resolved', 'selesai'])->count(),
                'belum' => ConsultationRoom::query()->where(function ($query) {
                    $query->where('unread_count', '>', 0)->orWhereIn('status', ['waiting', 'unanswered', 'open']);
                })->count(),
            ],
            'highRiskChildren' => $latestMeasurements->take(4),
            'latestConsultations' => ConsultationRoom::query()
                ->with(['user', 'child'])
                ->latest('last_message_at')
                ->take(4)
                ->get(),
            'lastSyncedAt' => Carbon::now()->translatedFormat('d M Y H:i'),
        ]);
    }
}
