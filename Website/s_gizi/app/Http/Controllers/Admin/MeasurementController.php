<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Measurement;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;
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

    public function export(Request $request): StreamedResponse
    {
        $filename = 'riwayat-gizi-'.now()->format('Ymd-His').'.csv';

        return response()->streamDownload(function () {
            $out = fopen('php://output', 'w');
            fputcsv($out, ['Anak', 'Tanggal Ukur', 'Berat', 'Tinggi', 'Umur Bulan', 'BB/U', 'TB/U', 'BB/TB', 'Status']);
            Measurement::query()->with('child')->orderByDesc('tanggal_ukur')->chunk(200, function ($rows) use ($out) {
                foreach ($rows as $row) {
                    fputcsv($out, [
                        $row->child?->nama,
                        $row->tanggal_ukur?->toDateString(),
                        $row->berat,
                        $row->tinggi,
                        $row->umur_bulan,
                        $row->z_bbu,
                        $row->z_tbu,
                        $row->z_bbtb,
                        $row->status_gabungan,
                    ]);
                }
            });
            fclose($out);
        }, $filename, ['Content-Type' => 'text/csv']);
    }
}

