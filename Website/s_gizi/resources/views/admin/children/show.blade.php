<x-admin-layout :title="'Detail Anak'">
    @php
        $latest = $child->measurements->first();
        $ageMonths = $child->tanggal_lahir ? (int) $child->tanggal_lahir->diffInMonths(now()) : null;
        $latestStatus = \App\Helpers\NutritionStatusHelper::getStatus($latest);
        $measurementDate = function ($measurement) {
            $rawDate = $measurement?->getRawOriginal('tanggal_ukur');
            if (!$rawDate) return '-';

            return \Illuminate\Support\Carbon::parse($rawDate)->locale('id')->translatedFormat('d M Y');
        };
        $chartRows = $child->measurements->sortBy('tanggal_ukur')->values()->map(fn ($row) => [
            'date' => $row->tanggal_ukur?->format('d/m/Y'),
            'short_date' => $row->tanggal_ukur?->format('d/m/y'),
            'berat' => (float) $row->berat,
            'tinggi' => (float) $row->tinggi,
            'status' => \App\Helpers\NutritionStatusHelper::getStatus($row),
        ]);
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div>
            <h1 class="sg-page-title">Medical Record Anak</h1>
            <p class="sg-page-subtitle">Profil anak, riwayat pengukuran, z-score, rekomendasi makanan, dan konsultasi.</p>
        </div>
        <a class="btn btn-outline-primary rounded-4 px-4 py-3" href="{{ route('admin.children.index') }}"><i class="bi bi-arrow-left me-2"></i>Kembali</a>
    </div>

    <div id="childDetail" class="row g-4">
        <div class="col-xl-4">
            <div class="sg-card p-4 h-100">
                <div class="d-flex align-items-center gap-3 mb-4">
                    <span class="sg-letter-avatar" style="width:72px;height:72px;border-radius:24px;font-size:28px">{{ strtoupper(substr($child->nama ?? 'A', 0, 1)) }}</span>
                    <div>
                        <h4 class="fw-bold mb-1">{{ $child->nama }}</h4>
                        <div class="text-muted">{{ $child->jenis_kelamin === 'P' ? 'Perempuan' : 'Laki-laki' }} - {{ $ageMonths ?? '-' }} bulan</div>
                    </div>
                </div>
                <div class="vstack gap-3">
                    <div class="d-flex justify-content-between"><span class="text-muted">Orang Tua</span><strong>{{ $child->user?->name ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Tanggal Lahir</span><strong>{{ $child->tanggal_lahir?->format('d M Y') ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Status Gizi</span><span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($latestStatus) }}">{{ $latestStatus }}</span></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Pengukuran Terakhir</span><strong>{{ $measurementDate($latest) }}</strong></div>
                </div>
            </div>
        </div>

        <div class="col-xl-8">
            <div class="sg-card p-4 h-100">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <div>
                        <h5 class="fw-bold mb-1">Grafik Pertumbuhan</h5>
                        <div class="small text-muted">Tren berat dan tinggi dari riwayat pengukuran</div>
                    </div>
                    <span class="sg-status sg-status-green">z-score</span>
                </div>
                <canvas id="growthChart" height="120"></canvas>
            </div>
        </div>
    </div>

    <div class="row g-4 mt-1">
        <div class="col-xl-8">
            <div class="sg-card p-4">
                <h5 class="fw-bold mb-3">Riwayat Pengukuran</h5>
                <div class="table-responsive">
                    <table class="table sg-table mb-0" style="min-width:720px">
                        <thead><tr><th>Tanggal</th><th>Berat</th><th>Tinggi</th><th>BB/U</th><th>TB/U</th><th>BB/TB</th><th>Status</th></tr></thead>
                        <tbody>
                        @forelse ($child->measurements as $row)
                            <tr>
                                <td>{{ $measurementDate($row) }}</td>
                                <td>{{ number_format((float) $row->berat, 1) }} kg</td>
                                <td>{{ number_format((float) $row->tinggi, 1) }} cm</td>
                                <td>{{ number_format((float) $row->z_bbu, 2) }}</td>
                                <td>{{ number_format((float) $row->z_tbu, 2) }}</td>
                                <td>{{ number_format((float) $row->z_bbtb, 2) }}</td>
                                @php($rowStatus = \App\Helpers\NutritionStatusHelper::getStatus($row))
                                <td><span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($rowStatus) }}">{{ $rowStatus }}</span></td>
                            </tr>
                        @empty
                            <tr><td colspan="7" class="text-center text-muted py-4">Belum ada riwayat pengukuran.</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col-xl-4">
            <div class="sg-card p-4 mb-4">
                <h5 class="fw-bold mb-3">Detail Z-score WHO</h5>
                <div class="vstack gap-3">
                    <div><div class="small text-muted">Berat menurut umur</div><div class="fs-4 fw-bold">{{ $latest ? number_format((float) $latest->z_bbu, 2) : '-' }}</div></div>
                    <div><div class="small text-muted">Tinggi menurut umur</div><div class="fs-4 fw-bold">{{ $latest ? number_format((float) $latest->z_tbu, 2) : '-' }}</div></div>
                    <div><div class="small text-muted">Berat menurut tinggi</div><div class="fs-4 fw-bold">{{ $latest ? number_format((float) $latest->z_bbtb, 2) : '-' }}</div></div>
                </div>
            </div>
            <div class="sg-card p-4">
                <h5 class="fw-bold mb-3">Rekomendasi Makanan</h5>
                <div class="vstack gap-2">
                    @forelse ($recommendedFoods as $food)
                        <div class="border rounded-4 p-3">
                            <div class="fw-semibold">{{ $food->nama }}</div>
                            <div class="small text-muted">{{ $food->kategori_status }} - {{ $food->prioritas_menu }}</div>
                            <div class="small text-muted">{{ \Illuminate\Support\Str::limit($food->alasan, 90) }}</div>
                        </div>
                    @empty
                        <span class="sg-status sg-status-gray">Belum ada menu yang cocok dengan status {{ $latestStatus }}</span>
                    @endforelse
                </div>
                <a href="{{ route('admin.foods.index', ['filter' => $latestStatus, 'status' => $latestStatus, 'recommendation' => 1, 'food_ids' => $recommendedFoods->pluck('id')->implode(',')]) }}" class="btn btn-primary rounded-4 w-100 mt-4">Buka rekomendasi</a>
            </div>
        </div>
    </div>

    <div class="sg-card p-4 mt-4">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
            <h5 class="fw-bold mb-0">Riwayat Konsultasi</h5>
            <a href="{{ route('admin.consultations.child', $child) }}" class="btn btn-sm btn-outline-primary rounded-pill">Buka dashboard chat</a>
        </div>
        @forelse ($consultationRooms as $room)
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 border rounded-4 px-3 py-2 mb-2">
                <div>
                    <div class="fw-semibold">{{ $room->user?->name ?? $child->user?->name ?? 'Orang Tua' }}</div>
                    <div class="small text-muted">{{ $room->last_message ?: 'Belum ada pesan terbaru' }}</div>
                </div>
                <a class="btn btn-sm btn-primary rounded-pill" href="{{ route('admin.consultations', ['room' => $room->id, 'q' => $child->nama]) }}">Buka Chat</a>
            </div>
        @empty
            <div class="text-muted">Anak dengan nama {{ $child->nama }} belum pernah melakukan konsultasi.</div>
        @endforelse
    </div>

    <x-slot:scripts>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
        <script>
            const rows = @json($chartRows);
            new Chart(document.getElementById('growthChart'), {
                type: 'line',
                data: {
                    labels: rows.map(row => row.short_date || '-'),
                    datasets: [
                        { label: 'Berat', data: rows.map(row => row.berat), borderColor: '#4B8E96', backgroundColor: 'rgba(75,142,150,.12)', tension: .35 },
                        { label: 'Tinggi', data: rows.map(row => row.tinggi), borderColor: '#38B87C', backgroundColor: 'rgba(56,184,124,.12)', tension: .35 }
                    ]
                },
                options: {
                    plugins: {
                        legend: { position: 'bottom' },
                        tooltip: {
                            callbacks: {
                                title: items => rows[items[0].dataIndex]?.date || '-',
                                afterBody: items => 'Status: ' + (rows[items[0].dataIndex]?.status || '-')
                            }
                        }
                    },
                    scales: { y: { beginAtZero: false }, x: { ticks: { maxRotation: 0, autoSkip: true } } }
                }
            });
        </script>
    </x-slot:scripts>
</x-admin-layout>
