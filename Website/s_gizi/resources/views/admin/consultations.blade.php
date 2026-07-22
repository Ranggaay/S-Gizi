<x-admin-layout :title="'Monitoring Konsultasi'">
    @php
        $filters = ['Semua', 'Belum Dibalas', 'Aktif', 'Risiko Tinggi', 'Hari Ini', 'Selesai'];
        $isNutritionistHistory = trim((string) ($expertId ?? '')) !== '';
        $selectedChild = $selectedRoom?->child;
        $measurements = $selectedChild?->measurements ?? collect();
        $latest = $measurements->first();
        $status = \App\Helpers\NutritionStatusHelper::getStatus($latest);
        $formatAge = function ($child, $measurement) {
            $months = $measurement?->umur_bulan;
            if ($months === null && $child?->tanggal_lahir) {
                $months = (int) $child->tanggal_lahir->diffInMonths(now());
            }
            if ($months === null) return '-';
            $months = (int) round((float) $months);
            $years = intdiv($months, 12);
            $remaining = $months % 12;
            return $years > 0 ? "{$years} Tahun {$remaining} Bulan" : "{$months} Bulan";
        };
        $zText = fn ($value) => $value === null || $value === '' ? '-' : sprintf('%+.2f SD', (float) $value);
        $idTime = fn ($date, string $format = 'H:i') => $date ? $date->copy()->timezone('Asia/Bangkok')->format($format) : '-';
        $idHuman = fn ($date) => $date ? $date->copy()->timezone('Asia/Bangkok')->diffForHumans() : '-';
        $roomStatusLabel = function ($room) {
            if (!$room) return 'Selesai';
            if ((int) $room->unread_count > 0) return 'Belum Dibalas';
            return in_array($room->status, ['selesai', 'closed', 'resolved'], true) ? 'Selesai' : 'Aktif';
        };
        $roomStatusClass = fn ($label) => match ($label) {
            'Belum Dibalas' => 'sg-status-orange',
            'Aktif' => 'sg-status-green',
            default => 'sg-status-gray',
        };
    @endphp

    <div id="consultSkeleton" class="row g-3 mb-3">
        <div class="col-lg-3"><div class="sg-skeleton"></div></div>
        <div class="col-lg-6"><div class="sg-skeleton" style="min-height:180px"></div></div>
        <div class="col-lg-3"><div class="sg-skeleton"></div></div>
    </div>

    <div id="consultError" class="alert alert-danger rounded-4 border-0 d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
            <strong>Data konsultasi gagal dimuat</strong>
            <button class="btn btn-sm btn-danger rounded-pill" onclick="window.location.reload()">Coba Lagi</button>
        </div>
    </div>

    <div id="consultContent" class="d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-3">
            <div>
                <h1 class="sg-page-title">{{ $isNutritionistHistory ? 'Riwayat Konsultasi Ahli Gizi' : 'Monitoring Konsultasi' }}</h1>
                <p class="sg-page-subtitle">
                    {{ $isNutritionistHistory
                        ? 'Riwayat konsultasi yang ditangani oleh '.(($expertName ?? '') ?: ($selectedRoom?->expert_name ?? 'ahli gizi')).'.'
                        : 'Pemantauan aktivitas konsultasi antara orang tua dan ahli gizi.' }}
                </p>
            </div>
            @if ($isNutritionistHistory)
                <a class="btn btn-outline-primary rounded-4 px-3" href="{{ route('admin.nutritionists') }}"><i class="bi bi-arrow-left me-1"></i>Kembali ke Ahli Gizi</a>
            @endif
        </div>

        <div class="sg-readonly-banner d-flex align-items-center gap-3 mb-3">
            <span class="sg-letter-avatar" style="background:#4B8E96"><i class="bi bi-eye"></i></span>
            <div>
                <div class="fw-semibold">Mode Monitoring Admin</div>
                <div class="small text-muted">Admin hanya dapat melihat percakapan konsultasi.</div>
            </div>
        </div>

        <section class="sg-consult-grid">
            <aside class="sg-card p-3 min-w-0 sg-consult-panel overflow-hidden">
                <form method="get" class="mb-3">
                    @if ($isNutritionistHistory)
                        <input type="hidden" name="expert_id" value="{{ $expertId }}">
                        <input type="hidden" name="expert_name" value="{{ $expertName }}">
                    @endif
                    <div class="sg-search d-flex align-items-center gap-2 w-100 mb-3" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input name="q" value="{{ $q }}" placeholder="Cari konsultasi...">
                    </div>
                    <div class="sg-filter-scroll">
                        @foreach ($filters as $item)
                            <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">
                                {{ $item }}
                            </button>
                        @endforeach
                    </div>
                </form>

                <div class="sg-consult-list vstack gap-2">
                    @forelse ($rooms as $room)
                        @php
                            $roomLabel = $roomStatusLabel($room);
                            $isActive = $selectedRoom?->id === $room->id;
                        @endphp
                        <a class="sg-consult-room {{ $isActive ? 'active' : '' }}" href="{{ route('admin.consultations', array_filter(['room' => $room->id, 'q' => $q, 'filter' => $filter, 'expert_id' => $expertId ?? null, 'expert_name' => $expertName ?? null], fn ($value) => $value !== null && $value !== '')) }}">
                            <div class="d-flex gap-2 align-items-start">
                                <span class="sg-letter-avatar">{{ strtoupper(substr($room->user?->name ?? 'O', 0, 1)) }}</span>
                                <div class="min-w-0 flex-grow-1">
                                    <div class="d-flex justify-content-between gap-2">
                                        <div class="fw-semibold text-truncate">{{ $room->user?->name ?? 'Orang tua' }}</div>
                                        <small class="text-muted flex-shrink-0">{{ $idTime($room->last_message_at) }}</small>
                                    </div>
                                    <div class="small text-muted text-truncate">Anak: {{ $room->child?->nama ?? '-' }}</div>
                                    <div class="small text-truncate">{{ $room->last_message ?? 'Belum ada pesan' }}</div>
                                    <div class="d-flex flex-wrap gap-1 mt-2">
                                        <span class="sg-status {{ $roomStatusClass($roomLabel) }}">{{ $roomLabel }}</span>
                                        @if ($room->monitoring_status !== \App\Helpers\NutritionStatusHelper::BELUM_DIUKUR)
                                            <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($room->monitoring_status) }}">{{ $room->monitoring_risk }}</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </a>
                    @empty
                        <div class="text-center text-muted py-5">Belum ada aktivitas konsultasi.</div>
                    @endforelse
                </div>
            </aside>

            <main class="sg-card p-0 min-w-0 overflow-hidden sg-consult-panel">
                @if ($selectedRoom)
                    @php($selectedLabel = $roomStatusLabel($selectedRoom))
                    <div class="p-3 border-bottom d-flex flex-wrap justify-content-between align-items-center gap-2">
                        <div class="d-flex align-items-center gap-2 min-w-0">
                            <span class="sg-letter-avatar" style="background:#77C6AC">{{ strtoupper(substr($selectedRoom->user?->name ?? 'O', 0, 1)) }}</span>
                            <div class="min-w-0">
                                <h6 class="fw-semibold mb-1 text-truncate">{{ $selectedRoom->user?->name ?? 'Orang tua' }}</h6>
                                <div class="small text-muted text-truncate">
                                    Anak: {{ $selectedRoom->child?->nama ?? '-' }} - Terakhir aktif {{ $idHuman($selectedRoom->last_message_at) }}
                                </div>
                            </div>
                        </div>
                        <span class="sg-status {{ $roomStatusClass($selectedLabel) }}">{{ $selectedLabel }}</span>
                    </div>

                    <div class="sg-monitor-chat p-3">
                        @if ($latest)
                            <div class="sg-update-card">
                                <div class="fw-semibold mb-2"><i class="bi bi-activity me-1"></i>Update Perkembangan Anak</div>
                                <div class="row g-2 align-items-center">
                                    <div class="col-sm-3 col-6"><div class="small text-muted">BB</div><div class="fw-semibold">{{ number_format((float) $latest->berat, 1) }} kg</div></div>
                                    <div class="col-sm-3 col-6"><div class="small text-muted">TB</div><div class="fw-semibold">{{ number_format((float) $latest->tinggi, 1) }} cm</div></div>
                                    <div class="col-sm-4 col-8"><div class="small text-muted">Status</div><span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($status) }}">{{ $status }}</span></div>
                                    <div class="col-sm-2 col-4 text-sm-end"><div class="small text-muted">{{ $latest->tanggal_ukur?->format('d M') ?? '-' }}</div></div>
                                </div>
                            </div>
                        @endif

                        @forelse ($selectedRoom->messages as $message)
                            @php($isExpert = in_array($message->sender_type, ['expert', 'nutritionist', 'ahli_gizi'], true))
                            <div class="sg-message-row {{ $isExpert ? 'expert' : 'parent' }}">
                                <div class="sg-message-bubble">
                                    <div class="sg-message-meta">
                                        {{ $isExpert ? ($selectedRoom->expert_name ?? 'Ahli Gizi') : ($selectedRoom->user?->name ?? 'Orang Tua') }}
                                        - {{ $idTime($message->created_at, 'd M Y H:i') }}
                                    </div>
                                    {{ $message->message }}
                                </div>
                            </div>
                        @empty
                            <div class="text-center text-muted py-5">Belum ada pesan pada konsultasi ini.</div>
                        @endforelse
                    </div>
                @else
                    <div class="text-center text-muted py-5">Belum ada aktivitas konsultasi.</div>
                @endif
            </main>

            <aside class="sg-card p-3 sg-consult-detail min-w-0 sg-consult-panel overflow-auto">
                @if ($selectedRoom && $selectedChild)
                    <div class="d-flex align-items-center gap-2 mb-3">
                        <span class="sg-letter-avatar">{{ strtoupper(substr($selectedChild->nama ?? 'A', 0, 1)) }}</span>
                        <div class="min-w-0">
                            <div class="fw-semibold text-truncate">{{ $selectedChild->nama }}</div>
                            <div class="small text-muted">Detail anak</div>
                        </div>
                    </div>

                    <div class="vstack gap-2 mb-3">
                        <div class="d-flex justify-content-between gap-2"><span class="text-muted small">Umur</span><strong class="small">{{ $formatAge($selectedChild, $latest) }}</strong></div>
                        <div class="d-flex justify-content-between gap-2"><span class="text-muted small">Jenis Kelamin</span><strong class="small">{{ $selectedChild->jenis_kelamin === 'P' ? 'Perempuan' : 'Laki-laki' }}</strong></div>
                        <div class="d-flex justify-content-between gap-2"><span class="text-muted small">Orang Tua</span><strong class="small text-end">{{ $selectedRoom->user?->name ?? '-' }}</strong></div>
                        <div class="d-flex justify-content-between gap-2"><span class="text-muted small">Ahli Gizi</span><strong class="small text-end">{{ $selectedRoom->expert_name ?? '-' }}</strong></div>
                    </div>

                    <div class="border rounded-4 px-3 py-2 mb-3">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <span class="fw-semibold small">Status WHO</span>
                            <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($status) }}">{{ \App\Helpers\NutritionStatusHelper::riskLabel($status) }}</span>
                        </div>
                        <div class="sg-who-row"><span class="small text-muted">BB/U</span><span class="small fw-semibold">{{ $zText($latest?->z_bbu) }} - {{ \App\Helpers\NutritionStatusHelper::bbuStatus($latest) }}</span></div>
                        <div class="sg-who-row"><span class="small text-muted">TB/U</span><span class="small fw-semibold">{{ $zText($latest?->z_tbu) }} - {{ \App\Helpers\NutritionStatusHelper::tbuStatus($latest) }}</span></div>
                        <div class="sg-who-row"><span class="small text-muted">BB/TB</span><span class="small fw-semibold">{{ $zText($latest?->z_bbtb) }} - {{ \App\Helpers\NutritionStatusHelper::bbtbStatus($latest) }}</span></div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6"><div class="border rounded-4 p-2"><div class="small text-muted">BB</div><div class="fw-semibold">{{ $latest ? number_format((float) $latest->berat, 1) : '-' }} kg</div></div></div>
                        <div class="col-6"><div class="border rounded-4 p-2"><div class="small text-muted">TB</div><div class="fw-semibold">{{ $latest ? number_format((float) $latest->tinggi, 1) : '-' }} cm</div></div></div>
                        <div class="col-12"><div class="small text-muted">Terakhir diukur: {{ $latest?->tanggal_ukur?->format('d M Y') ?? '-' }}</div></div>
                    </div>

                    @if ($measurements->count() >= 2)
                        <canvas id="consultMiniChart" class="sg-mini-chart mb-3"></canvas>
                    @else
                        <div class="border rounded-4 p-3 text-center text-muted small mb-3">
                            Mini grafik tersedia setelah minimal 2 pengukuran.
                        </div>
                    @endif

                    <div class="mb-3">
                        <div class="fw-semibold small mb-2">Riwayat Singkat</div>
                        @forelse ($measurements->take(4) as $item)
                            @php($itemStatus = \App\Helpers\NutritionStatusHelper::getStatus($item))
                            <div class="sg-history-line">
                                <span>{{ $item->tanggal_ukur?->format('d M') ?? '-' }}</span>
                                <span class="text-truncate">{{ $itemStatus }}</span>
                            </div>
                        @empty
                            <div class="small text-muted">Belum ada riwayat pengukuran.</div>
                        @endforelse
                    </div>

                    <div class="sg-action-grid">
                        <a class="btn btn-outline-primary rounded-pill" href="{{ route('admin.children.show', $selectedChild) }}">Detail</a>
                        <a class="btn btn-outline-primary rounded-pill" href="{{ route('admin.children.show', $selectedChild) }}#growthChart">Grafik</a>
                        <a class="btn btn-primary rounded-pill" href="{{ route('admin.measurements.index', ['q' => $selectedChild->nama]) }}">Riwayat</a>
                    </div>
                @else
                    <div class="text-center text-muted py-5">Pilih konsultasi untuk melihat detail anak.</div>
                @endif
            </aside>
        </section>
    </div>

    <x-slot:scripts>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
        <script>
            try {
                document.getElementById('consultSkeleton')?.classList.add('d-none');
                document.getElementById('consultContent')?.classList.remove('d-none');

                const chartEl = document.getElementById('consultMiniChart');
                if (chartEl) {
                    const rows = @json($measurements->reverse()->values());
                    if (rows.length >= 2) {
                        new Chart(chartEl, {
                            type: 'line',
                            data: {
                                labels: rows.map(row => row.tanggal_ukur || ''),
                                datasets: [
                                    { label: 'BB', data: rows.map(row => row.berat), borderColor: '#4B8E96', tension: .35, pointRadius: 0 },
                                    { label: 'TB', data: rows.map(row => row.tinggi), borderColor: '#38B87C', tension: .35, pointRadius: 0 }
                                ]
                            },
                            options: {
                                responsive: true,
                                maintainAspectRatio: false,
                                plugins: { legend: { display: false } },
                                scales: { x: { display: false }, y: { display: false } }
                            }
                        });
                    }
                }
            } catch (error) {
                document.getElementById('consultSkeleton')?.classList.add('d-none');
                document.getElementById('consultError')?.classList.remove('d-none');
            }
        </script>
    </x-slot:scripts>
</x-admin-layout>
