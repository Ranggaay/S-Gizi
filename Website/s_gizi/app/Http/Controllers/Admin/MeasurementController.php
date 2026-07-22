<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Measurement;
use Illuminate\Http\Request;
use Illuminate\View\View;

class MeasurementController extends Controller
{
    public function index(Request $request): View
    {
        $q = (string) $request->query('q', '');

        $measurements = Measurement::query()
            ->with('child')
            ->when($q !== '', function ($qb) use ($q) {
                $qb->whereHas('child', fn ($cqb) => $cqb->where('nama', 'like', "%{$q}%"));
            })
            ->orderByDesc('tanggal_ukur')
            ->orderByDesc('id')
            ->paginate(20)
            ->withQueryString();

        return view('admin.measurements.index', compact('measurements', 'q'));
    }

}
