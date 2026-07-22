<x-admin-layout :title="'Riwayat Pengukuran'">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h1 class="sg-page-title">Riwayat Pengukuran</h1>
            <p class="sg-page-subtitle">Daftar pengukuran terbaru dengan status gizi Indonesia.</p>
        </div>
    </div>

    <form class="row g-2 mb-3" method="get">
        <div class="col-md-6">
            <input class="form-control" name="q" value="{{ $q }}" placeholder="Cari nama anak...">
        </div>
        <div class="col-md-auto">
            <button class="btn btn-outline-primary rounded-4">Cari</button>
        </div>
    </form>

    <div class="sg-card overflow-hidden">
        <div class="table-responsive">
            <table class="table sg-table mb-0">
                <thead>
                <tr>
                    <th>Nama Anak</th>
                    <th>Tanggal</th>
                    <th>Berat (kg)</th>
                    <th>Tinggi (cm)</th>
                    <th>Status</th>
                </tr>
                </thead>
                <tbody>
                @forelse ($measurements as $m)
                    @php
                        $status = \App\Helpers\NutritionStatusHelper::getStatus($m);
                        $z = \App\Helpers\NutritionStatusHelper::primaryZScore($m);
                    @endphp
                    <tr>
                        <td>{{ $m->child?->nama }}</td>
                        <td>{{ $m->tanggal_ukur?->format('Y-m-d') }}</td>
                        <td>{{ number_format((float) $m->berat, 2) }}</td>
                        <td>{{ number_format((float) $m->tinggi, 2) }}</td>
                        <td>
                            <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($status) }}">{{ $status }}</span>
                            <span class="small text-muted ms-1">{{ $z['label'] }} {{ $z['value'] !== null ? sprintf('%+.2f SD', $z['value']) : '-' }}</span>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="text-center text-muted py-4">Belum ada data.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        <div class="p-3 border-top">
            {{ $measurements->links('pagination::bootstrap-5') }}
        </div>
    </div>
</x-admin-layout>
