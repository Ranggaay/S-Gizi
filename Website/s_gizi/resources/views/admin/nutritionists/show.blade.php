<x-admin-layout :title="'Detail Ahli Gizi'">
    @php
        $nutritionist = $row['nutritionist'];
        $presenceClass = $row['presence'] === 'Online' ? 'sg-status-green' : 'sg-status-gray';
        $capacityClass = match ($row['capacity']) {
            'Penuh' => 'sg-status-red',
            'Sedang' => 'sg-status-orange',
            default => 'sg-status-green',
        };
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-3">
        <div>
            <h1 class="sg-page-title">Detail Ahli Gizi</h1>
            <p class="sg-page-subtitle">Profil, aktivitas konsultasi, beban kerja, dan keluarga yang ditangani.</p>
        </div>
        <div class="d-flex gap-2">
            <a class="btn btn-primary rounded-4 px-3" href="{{ route('admin.consultations.nutritionist', $nutritionist) }}"><i class="bi bi-clock-history me-1"></i>Riwayat Konsultasi</a>
            <a class="btn btn-outline-primary rounded-4 px-3" href="{{ route('admin.nutritionists') }}"><i class="bi bi-arrow-left me-1"></i>Kembali</a>
        </div>
    </div>

    <div class="row g-3">
        <div class="col-xl-4">
            <div class="sg-card p-3 h-100">
                <div class="d-flex align-items-center gap-3 mb-3">
                    @if ($row['avatar'])
                        <img src="{{ asset($row['avatar']) }}" alt="Foto {{ $row['name'] }}" style="width:58px;height:58px;border-radius:18px;object-fit:cover;border:1px solid rgba(75,142,150,.18)">
                    @else
                        <span class="sg-letter-avatar" style="width:58px;height:58px;border-radius:18px;background:#4B8E96;font-size:22px">{{ strtoupper(substr($row['name'], 0, 1)) }}</span>
                    @endif
                    <div class="min-w-0">
                        <h5 class="fw-semibold mb-1 text-truncate">{{ $row['name'] }}</h5>
                        <span class="sg-status {{ $presenceClass }}">{{ $row['presence'] }}</span>
                    </div>
                </div>
                <div class="vstack gap-2">
                    <div class="d-flex justify-content-between gap-2"><span class="text-muted">Expert ID</span><strong>{{ $row['expert_id'] }}</strong></div>
                    <div class="d-flex justify-content-between gap-2"><span class="text-muted">Pengalaman</span><strong class="text-end">{{ $row['experience'] }}</strong></div>
                    <div class="d-flex justify-content-between gap-2"><span class="text-muted">STR/SIP</span><strong>{{ $nutritionist->str_sip ?: '-' }}</strong></div>
                    <div class="d-flex justify-content-between gap-2"><span class="text-muted">Status Akun</span><strong>{{ $row['account_status'] }}</strong></div>
                    <div class="d-flex justify-content-between gap-2"><span class="text-muted">Ketersediaan</span><strong>{{ $row['is_available'] ? 'Menerima konsultasi' : 'Tidak menerima konsultasi' }}</strong></div>
                    <div class="d-flex justify-content-between gap-2"><span class="text-muted">Terakhir Online</span><strong class="text-end">{{ $row['last_online_label'] }}</strong></div>
                </div>
                @if ($row['bio'])
                    <div class="border rounded-4 p-3 mt-3 small text-muted">{{ $row['bio'] }}</div>
                @endif
                <div class="d-flex flex-wrap gap-1 mt-3">
                    @foreach ($row['specializations'] as $chip)
                        <span class="sg-chip">{{ $chip }}</span>
                    @endforeach
                </div>
            </div>
        </div>

        <div class="col-xl-8">
            <div class="row g-2 mb-3">
                <div class="col-sm-6 col-lg-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Anak Dipantau</div><div class="fs-4 fw-semibold">{{ $row['monitored_children'] }}</div></div></div>
                <div class="col-sm-6 col-lg-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Keluarga</div><div class="fs-4 fw-semibold">{{ $row['monitored_families'] }}</div></div></div>
                <div class="col-sm-6 col-lg-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Konsultasi Aktif</div><div class="fs-4 fw-semibold text-warning">{{ $row['active_consultations'] }}</div></div></div>
                <div class="col-sm-6 col-lg-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Risiko Tinggi</div><div class="fs-4 fw-semibold text-danger">{{ $row['high_risk_children'] }}</div></div></div>
            </div>

            <div class="sg-card p-3">
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                    <h6 class="fw-semibold mb-0">Aktivitas</h6>
                    <span class="sg-status {{ $capacityClass }}">Kapasitas {{ $row['capacity'] }}</span>
                </div>
                <div class="row g-2">
                    <div class="col-md-4"><div class="border rounded-4 p-3"><div class="small text-muted">Konsultasi Selesai</div><strong>{{ $row['completed_consultations'] }}</strong></div></div>
                    <div class="col-md-4"><div class="border rounded-4 p-3"><div class="small text-muted">Response Rate</div><strong>{{ $row['response_rate'] }}%</strong></div></div>
                    <div class="col-md-4"><div class="border rounded-4 p-3"><div class="small text-muted">Rata-rata Respon</div><strong>{{ $row['avg_response'] }}</strong></div></div>
                </div>
            </div>
        </div>
    </div>

    <div class="sg-card p-3 mt-3">
        <h6 class="fw-semibold mb-3">Konsultasi yang Ditangani</h6>
        <div class="vstack gap-2">
            @forelse ($row['rooms']->take(8) as $room)
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 border rounded-4 px-3 py-2">
                    <div>
                        <div class="fw-semibold">{{ $room->user?->name ?? 'Orang Tua' }} <span class="text-muted fw-normal">- {{ $room->child?->nama ?? 'Anak' }}</span></div>
                        <div class="small text-muted">{{ $room->last_message ?: 'Belum ada pesan terbaru' }}</div>
                    </div>
                    <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.consultations', ['room' => $room->id, 'expert_id' => $row['expert_id'], 'expert_name' => $row['user']?->name ?? $row['name']]) }}">Buka Chat</a>
                </div>
            @empty
                <div class="text-center text-muted py-4">Belum ada konsultasi yang ditangani.</div>
            @endforelse
        </div>
    </div>

    <x-slot:styles>
        <style>
            .sg-chip { display: inline-flex; align-items: center; min-height: 25px; padding: 4px 9px; border-radius: 999px; background: #EAF6F4; color: #2f7580; font-size: 11.5px; font-weight: 700; }
            .sg-mini-metric { min-height: 74px; padding: 12px 14px; border-radius: 16px; }
        </style>
    </x-slot:styles>
</x-admin-layout>
