<x-nutritionist-layout title="Konsultasi">
    @php
        $riskClass = fn ($risk) => match ($risk) {
            'Risiko Tinggi' => 'risk-high',
            'Perlu Dipantau' => 'risk-watch',
            'Perlu Ukur Ulang' => 'risk-repeat',
            'Stabil', 'Normal' => 'risk-normal',
            default => 'risk-neutral',
        };
        $statusLabel = fn ($status) => match ($status) {
            'closed' => 'Selesai',
            'waiting_reply' => 'Belum Dibalas',
            default => 'Aktif',
        };
        $statusClass = fn ($status) => $status === 'closed' ? 'status-closed' : 'status-active';
        $chatTime = fn ($date) => $date
            ? $date->copy()->timezone(config('app.timezone', 'Asia/Jakarta'))->locale('id')->translatedFormat('d M Y, H:i').' WIB'
            : '-';
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div>
            <h1 class="page-title">Konsultasi</h1>
            <p class="page-subtitle">Balas chat orang tua dan pantau ringkasan anak dari room yang ditugaskan.</p>
        </div>
    </div>

    <div class="chat-grid {{ $selected ? 'has-selected' : '' }}">
        <aside class="sg-card chat-list p-3">
            <h5 class="fw-bold mb-3">Daftar Konsultasi</h5>
            <form method="get" class="mb-3">
                <input class="form-control mb-2" name="q" value="{{ $q }}" placeholder="Cari orang tua atau anak">
                <div class="d-flex flex-wrap gap-2">
                    @foreach ($filters as $item)
                        <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">{{ $item }}</button>
                    @endforeach
                </div>
            </form>

            <div class="consultation-list-scroll">
                @forelse ($rooms as $row)
                    <a class="consultation-card {{ $selected?->id === $row['room']->id ? 'active' : '' }}" href="{{ route('nutritionist.consultations', ['room' => $row['room']->id, 'filter' => $filter, 'q' => $q]) }}">
                        <div class="d-flex justify-content-between gap-2 align-items-start">
                            <div class="min-w-0">
                                <strong class="text-dark d-block text-truncate">{{ $row['parent_name'] }}</strong>
                                <span class="small text-muted d-block text-truncate">{{ $row['child_name'] }}</span>
                            </div>
                            @if ($row['unread_count'] > 0)
                                <span class="badge-soft risk-neutral">{{ $row['unread_count'] }}</span>
                            @endif
                        </div>
                        <div class="small text-muted mt-2">{{ \Illuminate\Support\Str::limit($row['last_message'], 78) }}</div>
                        <div class="small text-muted mt-2">{{ $chatTime($row['last_message_at']) }}</div>
                        <div class="d-flex flex-wrap gap-2 mt-3">
                            <span class="badge-soft {{ $riskClass($row['risk']) }}">{{ $row['risk'] }}</span>
                            <span class="badge-soft {{ $statusClass($row['status']) }}">{{ $statusLabel($row['status']) }}</span>
                        </div>
                    </a>
                @empty
                    <div class="text-muted text-center py-5">Tidak ada konsultasi.</div>
                @endforelse
            </div>
        </aside>

        <section class="sg-card chat-panel">
            @if ($selected)
                <div class="chat-header d-flex justify-content-between align-items-center gap-2">
                    <div>
                        <h5 class="fw-bold mb-1">{{ $selected->user?->name }}</h5>
                        <div class="text-muted small">{{ $selected->child?->nama ?? '-' }} &bull; {{ $statusLabel($selectedRow['status']) }}</div>
                    </div>
                    <div class="d-flex flex-wrap gap-2 justify-content-end">
                        <a class="btn btn-outline-primary rounded-pill mobile-chat-list-button" href="{{ route('nutritionist.consultations', ['filter' => $filter, 'q' => $q]) }}"><i class="bi bi-list"></i> Daftar Chat</a>
                        <form method="post" action="{{ route('nutritionist.consultations.close', $selected) }}">
                            @csrf
                            <button class="btn btn-outline-primary rounded-pill" @disabled($selectedRow['status'] === 'closed')>Tandai Selesai</button>
                        </form>
                    </div>
                </div>

                <div class="chat-messages">
                    @forelse ($selected->messages->sortBy('created_at') as $message)
                        <div class="message {{ $message->sender_type === 'expert' ? 'expert' : 'parent' }}">
                            <div>{{ $message->message }}</div>
                            <div class="small opacity-75 mt-1">{{ $chatTime($message->created_at) }}</div>
                        </div>
                    @empty
                        <div class="text-muted text-center py-5">Belum ada pesan.</div>
                    @endforelse
                </div>

                <form class="chat-input" method="post" action="{{ route('nutritionist.consultations.messages.store', $selected) }}">
                    @csrf
                    <div class="d-flex gap-2">
                        <textarea class="form-control fs-6" name="message" rows="3" placeholder="Tulis balasan untuk orang tua..." @disabled($selectedRow['status'] === 'closed') required></textarea>
                        <button class="btn btn-primary rounded-4 px-4" @disabled($selectedRow['status'] === 'closed')><i class="bi bi-send"></i></button>
                    </div>
                </form>
            @else
                <div class="m-auto text-center text-muted p-5">Pilih konsultasi untuk membuka chat.</div>
            @endif
        </section>

        <aside class="sg-card child-panel p-4">
            @if ($selected)
                @php
                    $latest = $selected->child?->measurements?->sortByDesc('tanggal_ukur')->first();
                    $risk = \App\Helpers\NutritionStatusHelper::riskLabel(\App\Helpers\NutritionStatusHelper::getStatus($latest));
                    $validation = $latest?->validation_status ?: ($latest?->is_anomaly ? 'Perlu Ukur Ulang' : 'Valid');
                @endphp
                <h5 class="fw-bold mb-3">Ringkasan Anak</h5>

                <div class="mb-4">
                    <div class="fw-bold mb-2">Profil Anak</div>
                    <div class="vstack gap-2">
                        <div><div class="text-muted small">Nama Anak</div><strong>{{ $selected->child?->nama ?? '-' }}</strong></div>
                        <div><div class="text-muted small">Umur</div><strong>{{ $selectedRow['age'] ?? '-' }}</strong></div>
                        <div><div class="text-muted small">Jenis Kelamin</div><strong>{{ $selected->child?->jenis_kelamin === 'P' ? 'Perempuan' : 'Laki-laki' }}</strong></div>
                        <div><div class="text-muted small">Orang Tua</div><strong>{{ $selected->user?->name ?? '-' }}</strong></div>
                    </div>
                </div>

                <div class="mb-4">
                    <div class="fw-bold mb-2">Pengukuran Terakhir</div>
                    <div class="vstack gap-2">
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">BB</span><strong>{{ $latest ? number_format((float) $latest->berat, 1).' kg' : '-' }}</strong></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">TB</span><strong>{{ $latest ? number_format((float) $latest->tinggi, 1).' cm' : '-' }}</strong></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">Tanggal</span><strong>{{ $latest?->tanggal_ukur?->translatedFormat('d M Y') ?? '-' }}</strong></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">Posisi</span><strong>{{ $latest?->cara_ukur ?? '-' }}</strong></div>
                    </div>
                </div>

                <div class="mb-4">
                    <div class="fw-bold mb-2">Status Gizi</div>
                    <div class="vstack gap-2">
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">BB/U</span><strong class="text-end">{{ \App\Helpers\NutritionStatusHelper::bbuStatus($latest) }}</strong></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">TB/U</span><strong class="text-end">{{ \App\Helpers\NutritionStatusHelper::tbuStatus($latest) }}</strong></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">BB/TB</span><strong class="text-end">{{ \App\Helpers\NutritionStatusHelper::bbtbStatus($latest) }}</strong></div>
                        <div class="d-flex justify-content-between gap-3 align-items-center"><span class="text-muted">Status</span><span class="badge-soft {{ $riskClass($risk) }}">{{ $risk }}</span></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">Pemantauan</span><strong class="text-end">{{ $latest?->monitoring_status ?? $selectedRow['validation'] ?? '-' }}</strong></div>
                        <div class="d-flex justify-content-between gap-3"><span class="text-muted">Validasi</span><strong class="text-end">{{ $validation }}</strong></div>
                    </div>
                </div>

                <div class="d-grid gap-2">
                    <a class="btn btn-primary rounded-4" href="{{ route('nutritionist.consultations.child', $selected) }}#child-detail">Lihat Detail Anak</a>
                    <a class="btn btn-outline-primary rounded-4" href="{{ route('nutritionist.consultations.child', $selected) }}#measurement-history">Riwayat Pengukuran</a>
                    <a class="btn btn-outline-primary rounded-4" href="{{ route('nutritionist.consultations.child', $selected) }}#growth-chart-section">Grafik Pertumbuhan</a>
                    <a class="btn btn-outline-primary rounded-4" href="{{ route('nutritionist.consultations.child', $selected) }}#nutritionist-notes">Tambah Catatan</a>
                </div>
            @else
                <div class="text-muted text-center py-5">Ringkasan anak muncul setelah chat dipilih.</div>
            @endif
        </aside>
    </div>
</x-nutritionist-layout>
