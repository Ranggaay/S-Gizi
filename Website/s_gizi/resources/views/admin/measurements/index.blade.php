<x-admin-layout :title="'Riwayat Pengukuran'">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h4 class="mb-1">Riwayat Pengukuran</h4>
            <div class="text-muted">Daftar pengukuran (urut terbaru).</div>
        </div>
        <a href="{{ route('admin.measurements.export') }}" class="btn btn-primary">Export CSV</a>
    </div>

    <form class="row g-2 mb-3" method="get">
        <div class="col-md-6">
            <input class="form-control" name="q" value="{{ $q }}" placeholder="Cari nama anak...">
        </div>
        <div class="col-md-auto">
            <button class="btn btn-outline-secondary">Cari</button>
        </div>
    </form>

    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-striped mb-0">
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
                    <tr>
                        <td>{{ $m->child?->nama }}</td>
                        <td>{{ $m->tanggal_ukur?->format('Y-m-d') }}</td>
                        <td>{{ number_format((float) $m->berat, 2) }}</td>
                        <td>{{ number_format((float) $m->tinggi, 2) }}</td>
                        <td><span class="badge text-bg-primary">{{ $m->status_gabungan }}</span></td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="text-center text-muted py-4">Belum ada data.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-body">
            {{ $measurements->links('pagination::bootstrap-5') }}
        </div>
    </div>
</x-admin-layout>

