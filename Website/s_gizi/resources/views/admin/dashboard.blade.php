<x-admin-layout :title="'Dashboard'">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h4 class="mb-1 fw-bold">Dashboard S-Gizi</h4>
            <div class="text-muted">Ringkasan pengguna, anak, pengukuran, dan distribusi status gizi</div>
        </div>
    </div>

    <div class="row g-3">
        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body">
                    <div class="text-muted">Total Users</div>
                    <div class="fs-2 fw-bold text-sgizi">{{ $countUsers }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body">
                    <div class="text-muted">Total Children</div>
                    <div class="fs-2 fw-bold text-sgizi">{{ $countChildren }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body">
                    <div class="text-muted">Riwayat Gizi</div>
                    <div class="fs-2 fw-bold text-sgizi">{{ $countMeasurements }}</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card shadow-sm">
                <div class="card-body">
                    <div class="text-muted">Menu Makanan</div>
                    <div class="fs-2 fw-bold text-sgizi">{{ $countFoods }}</div>
                </div>
            </div>
        </div>
    </div>

    <div class="card shadow-sm mt-4">
        <div class="card-body">
            <h5 class="fw-bold mb-3">Status Distribution</h5>
            @forelse ($statusDistribution as $row)
                @php($percent = $countMeasurements > 0 ? round(($row->total / $countMeasurements) * 100) : 0)
                <div class="mb-3">
                    <div class="d-flex justify-content-between small mb-1">
                        <span>{{ $row->status_gabungan }}</span>
                        <span>{{ $row->total }} data</span>
                    </div>
                    <div class="progress" style="height: 10px">
                        <div class="progress-bar" style="width: {{ $percent }}%; background:#4B8E96"></div>
                    </div>
                </div>
            @empty
                <div class="text-muted">Belum ada data pengukuran.</div>
            @endforelse
        </div>
    </div>
</x-admin-layout>

