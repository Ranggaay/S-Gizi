<x-nutritionist-layout title="Detail Anak">
    @php
        $riskClass = fn ($risk) => match ($risk) {
            'Risiko Tinggi' => 'risk-high',
            'Perlu Dipantau' => 'risk-watch',
            'Perlu Ukur Ulang' => 'risk-repeat',
            'Stabil', 'Normal' => 'risk-normal',
            default => 'risk-neutral',
        };
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div><h1 class="page-title">Detail Anak</h1><p class="page-subtitle">Data ini hanya dibuka dari konsultasi yang ditugaskan kepada Anda.</p></div>
        <a class="btn btn-outline-primary rounded-pill px-4" href="{{ route('nutritionist.consultations', ['room' => $room->id]) }}">Kembali ke Chat</a>
    </div>

    <div class="row g-4" id="child-detail">
        <div class="col-xl-4">
            <div class="sg-card p-4 h-100">
                <h5 class="fw-bold mb-3">Profil Anak</h5>
                <div class="vstack gap-3">
                    <div class="d-flex justify-content-between"><span class="text-muted">Nama</span><strong>{{ $child?->nama ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Jenis Kelamin</span><strong>{{ $child?->jenis_kelamin === 'P' ? 'Perempuan' : 'Laki-laki' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Tanggal Lahir</span><strong>{{ $child?->tanggal_lahir?->format('d/m/Y') ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Umur</span><strong>{{ $summary['age_label'] }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Orang Tua</span><strong>{{ $parent?->name ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Nomor</span><strong>{{ $parent?->phone ?? '-' }}</strong></div>
                </div>
            </div>
        </div>
        <div class="col-xl-4">
            <div class="sg-card p-4 h-100">
                <h5 class="fw-bold mb-3">Pengukuran Terakhir</h5>
                <div class="vstack gap-3">
                    <div class="d-flex justify-content-between"><span class="text-muted">Tanggal</span><strong>{{ $summary['date'] }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Umur saat ukur</span><strong>{{ $latest?->umur_bulan ? (int) $latest->umur_bulan.' bulan' : '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Berat</span><strong>{{ $summary['weight'] }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Tinggi</span><strong>{{ $summary['height'] }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Posisi</span><strong>{{ $latest?->cara_ukur ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Validasi</span><span class="badge-soft {{ $riskClass($summary['validation']) }}">{{ $summary['validation'] }}</span></div>
                </div>
            </div>
        </div>
        <div class="col-xl-4">
            <div class="sg-card p-4 h-100">
                <h5 class="fw-bold mb-3">Z-score WHO</h5>
                <div class="vstack gap-3">
                    <div><span class="text-muted">BB/U</span><strong class="d-block">{{ $latest ? number_format((float) $latest->z_bbu, 2) : '-' }} | {{ $summary['bbu'] }}</strong></div>
                    <div><span class="text-muted">TB/U</span><strong class="d-block">{{ $latest ? number_format((float) $latest->z_tbu, 2) : '-' }} | {{ $summary['tbu'] }}</strong></div>
                    <div><span class="text-muted">BB/TB</span><strong class="d-block">{{ $latest ? number_format((float) $latest->z_bbtb, 2) : '-' }} | {{ $summary['bbtb'] }}</strong></div>
                    <div class="d-flex justify-content-between align-items-center"><span class="text-muted">Status Risiko</span><span class="badge-soft {{ $riskClass($summary['risk']) }}">{{ $summary['risk'] }}</span></div>
                </div>
            </div>
        </div>
    </div>

    <div class="sg-card p-4 mt-4">
        <h5 class="fw-bold mb-2">Interpretasi Sistem</h5>
        <p class="text-muted mb-0">Anak memiliki status {{ $summary['status'] }} dengan kategori risiko {{ $summary['risk'] }}. Gunakan riwayat dan grafik pertumbuhan sebagai dasar saran pola makan, pengukuran ulang, atau konsultasi lanjutan.</p>
    </div>

    <div class="row g-4 mt-1">
        <div class="col-xl-7">
            <div class="sg-card p-4" id="measurement-history">
                <h5 class="fw-bold mb-3">Riwayat Pengukuran</h5>
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead><tr><th>Tanggal</th><th>Umur</th><th>BB</th><th>TB</th><th>BB/U</th><th>TB/U</th><th>BB/TB</th><th>Risiko</th><th>Validasi</th></tr></thead>
                        <tbody>
                        @forelse ($measurements as $m)
                            @php($risk = \App\Helpers\NutritionStatusHelper::riskLabel(\App\Helpers\NutritionStatusHelper::getStatus($m)))
                            <tr>
                                <td>{{ $m->tanggal_ukur?->format('d/m/Y') ?? '-' }}</td>
                                <td>{{ $m->umur_bulan ? (int) $m->umur_bulan.' bln' : '-' }}</td>
                                <td>{{ number_format((float) $m->berat, 1) }}</td>
                                <td>{{ number_format((float) $m->tinggi, 1) }}</td>
                                <td>{{ \App\Helpers\NutritionStatusHelper::bbuStatus($m) }}</td>
                                <td>{{ \App\Helpers\NutritionStatusHelper::tbuStatus($m) }}</td>
                                <td>{{ \App\Helpers\NutritionStatusHelper::bbtbStatus($m) }}</td>
                                <td><span class="badge-soft {{ $riskClass($risk) }}">{{ $risk }}</span></td>
                                <td>{{ $m->validation_status ?: ($m->is_anomaly ? 'Perlu Ukur Ulang' : 'Valid') }}</td>
                            </tr>
                        @empty
                            <tr><td colspan="9" class="text-center text-muted py-4">Belum ada riwayat pengukuran.</td></tr>
                        @endforelse
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="col-xl-5">
            <div class="sg-card p-4" id="growth-chart-section">
                <h5 class="fw-bold mb-3">Grafik Pertumbuhan</h5>
                <select class="form-select mb-3" id="chartRange"><option value="3">3 bulan terakhir</option><option value="6">6 bulan terakhir</option><option value="all" selected>Semua data</option></select>
                <canvas id="growthChart" height="230"></canvas>
            </div>
        </div>
    </div>

    <div class="sg-card p-4 mt-4" id="nutritionist-notes">
        <h5 class="fw-bold mb-3">Catatan Ahli Gizi</h5>
        <form method="post" action="{{ route('nutritionist.consultations.notes.store', $room) }}" class="row g-3 mb-4">
            @csrf
            <div class="col-md-4"><select class="form-select" name="category" required><option>Saran pola makan</option><option>Saran pengukuran ulang</option><option>Saran konsultasi lanjutan</option><option>Catatan umum</option></select></div>
            <div class="col-md-8"><textarea class="form-control" name="note" rows="3" placeholder="Tulis catatan..." required></textarea></div>
            <div class="col-12 text-end"><button class="btn btn-primary rounded-pill px-4">Simpan Catatan</button></div>
        </form>
        <div class="vstack gap-2">
            @forelse ($notes as $note)
                <div class="border rounded-4 p-3"><strong>{{ $note->category }}</strong><div class="text-muted">{{ $note->note }}</div><div class="small text-muted">{{ $note->created_at?->format('d/m/Y H:i') }}</div></div>
            @empty
                <div class="text-muted">Belum ada catatan.</div>
            @endforelse
        </div>
    </div>

    <x-slot:scripts>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <script>
            const rows = @json($chartRows);
            const ctx = document.getElementById('growthChart');
            const range = document.getElementById('chartRange');
            const filterRows = () => {
                if (!range || range.value === 'all') return rows;
                const months = Number(range.value);
                const latest = rows.reduce((max, row) => row.raw_date && new Date(row.raw_date) > max ? new Date(row.raw_date) : max, new Date(0));
                const start = new Date(latest);
                start.setMonth(start.getMonth() - months);
                return rows.filter(row => row.raw_date && new Date(row.raw_date) >= start);
            };
            const dataset = (items) => ({
                labels: items.map(r => r.date),
                datasets: [
                    { label:'Berat', data: items.map(r => r.weight), borderColor:'#0F8B8D', tension:.35 },
                    { label:'Tinggi', data: items.map(r => r.height), borderColor:'#2E7D32', tension:.35 },
                    { label:'Z BB/U', data: items.map(r => r.z_bbu), borderColor:'#EF6C00', tension:.35 },
                    { label:'Z TB/U', data: items.map(r => r.z_tbu), borderColor:'#C62828', tension:.35 },
                    { label:'Z BB/TB', data: items.map(r => r.z_bbtb), borderColor:'#6B7280', tension:.35 },
                ]
            });
            if (ctx) {
                const chart = new Chart(ctx, {
                    type: 'line',
                    data: dataset(filterRows()),
                    options: { responsive:true, plugins:{ legend:{ position:'bottom' } } }
                });
                range?.addEventListener('change', () => {
                    chart.data = dataset(filterRows());
                    chart.update();
                });
            }
        </script>
    </x-slot:scripts>
</x-nutritionist-layout>
