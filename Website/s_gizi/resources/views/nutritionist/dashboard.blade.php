<x-nutritionist-layout title="Dashboard">
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
        <div>
            <h1 class="page-title">Dashboard Ahli Gizi</h1>
            <p class="page-subtitle">Ringkasan konsultasi yang ditugaskan kepada akun Anda.</p>
        </div>
        <a class="btn btn-primary rounded-pill px-4" href="{{ route('nutritionist.consultations') }}"><i class="bi bi-chat-dots me-1"></i>Buka Konsultasi</a>
    </div>

    <section class="row g-3 mb-4">
        <div class="col-sm-6 col-xl"><div class="sg-card mini-card"><span>Konsultasi Aktif</span><strong>{{ $stats['active'] }}</strong></div></div>
        <div class="col-sm-6 col-xl"><div class="sg-card mini-card"><span>Belum Dibalas</span><strong class="text-warning">{{ $stats['unreplied'] }}</strong></div></div>
        <div class="col-sm-6 col-xl"><div class="sg-card mini-card"><span>Risiko Tinggi</span><strong class="text-danger">{{ $stats['high_risk'] }}</strong></div></div>
        <div class="col-sm-6 col-xl"><div class="sg-card mini-card"><span>Perlu Dipantau</span><strong class="text-warning">{{ $stats['watch'] }}</strong></div></div>
        <div class="col-sm-6 col-xl"><div class="sg-card mini-card"><span>Perlu Ukur Ulang</span><strong class="text-warning">{{ $stats['remeasure'] }}</strong></div></div>
    </section>

    <div class="row g-4">
        <div class="col-xl-8">
            <div class="sg-card p-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="fw-bold mb-0">Konsultasi Terbaru</h5>
                    <a href="{{ route('nutritionist.consultations') }}" class="btn btn-sm btn-outline-primary rounded-pill">Lihat semua</a>
                </div>
                <div class="vstack gap-3">
                    @forelse ($rooms as $row)
                        <div class="border rounded-4 p-3">
                            <div class="d-flex flex-wrap justify-content-between gap-2">
                                <div>
                                    <div class="fw-bold">{{ $row['parent_name'] }}</div>
                                    <div class="text-muted small">{{ $row['child_name'] }} • {{ $row['age'] }}</div>
                                </div>
                                <span class="badge-soft {{ $riskClass($row['risk']) }}">{{ $row['risk'] }}</span>
                            </div>
                            <div class="text-muted mt-2">{{ \Illuminate\Support\Str::limit($row['last_message'], 110) }}</div>
                            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mt-3">
                                <span class="small text-muted">{{ $row['last_message_at']?->diffForHumans() ?? '-' }} • {{ $row['unread_count'] }} belum dibaca</span>
                                <a class="btn btn-sm btn-primary rounded-pill" href="{{ route('nutritionist.consultations', ['room' => $row['room']->id]) }}">Buka Chat</a>
                            </div>
                        </div>
                    @empty
                        <div class="text-muted text-center py-5">Belum ada konsultasi yang ditugaskan.</div>
                    @endforelse
                </div>
            </div>
        </div>
        <div class="col-xl-4">
            <div class="sg-card p-4">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 class="fw-bold mb-0">Notifikasi Terbaru</h5>
                    <a href="{{ route('nutritionist.notifications') }}" class="btn btn-sm btn-outline-primary rounded-pill">Buka</a>
                </div>
                <div class="vstack gap-3">
                    @forelse ($notifications as $notification)
                        <div class="border rounded-4 p-3">
                            <div class="d-flex justify-content-between gap-2"><strong>{{ $notification->title }}</strong><span class="badge-soft {{ $notification->is_read ? 'risk-neutral' : 'risk-watch' }}">{{ $notification->is_read ? 'Dibaca' : 'Baru' }}</span></div>
                            <div class="text-muted small">{{ $notification->description }}</div>
                            <div class="small mt-2">{{ $notification->child?->nama ?? '-' }} • {{ $notification->created_at?->diffForHumans() }}</div>
                        </div>
                    @empty
                        <div class="text-muted text-center py-5">Belum ada notifikasi.</div>
                    @endforelse
                </div>
            </div>
        </div>
    </div>
</x-nutritionist-layout>
