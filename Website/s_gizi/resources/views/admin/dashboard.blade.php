<x-admin-layout :title="'Dashboard'">
    @php
        $stats = [
            ['label' => 'Total Orang Tua', 'value' => $countUsers, 'subtitle' => 'Akun keluarga', 'trend' => '+12%', 'trendClass' => 'text-success', 'icon' => 'bi-people', 'color' => '#4B8E96', 'bg' => '#E5F4F6'],
            ['label' => 'Total Anak', 'value' => $countChildren, 'subtitle' => 'Profil dipantau', 'trend' => '+8%', 'trendClass' => 'text-success', 'icon' => 'bi-person-hearts', 'color' => '#38B87C', 'bg' => '#DCF6E9'],
            ['label' => 'Anak Risiko Tinggi', 'value' => $countHighRisk, 'subtitle' => 'Prioritas tindak lanjut', 'trend' => '-2%', 'trendClass' => 'text-danger', 'icon' => 'bi-exclamation-triangle', 'color' => '#EB6B6B', 'bg' => '#FFE5E5'],
            ['label' => 'Konsultasi Aktif', 'value' => $countConsultations, 'subtitle' => 'Perlu dipantau', 'trend' => '+5%', 'trendClass' => 'text-success', 'icon' => 'bi-chat-dots', 'color' => '#F6A95B', 'bg' => '#FFF0DE'],
            ['label' => 'Ahli Gizi Aktif', 'value' => $countNutritionists, 'subtitle' => 'Sedang online', 'trend' => '+3%', 'trendClass' => 'text-success', 'icon' => 'bi-person-vcard', 'color' => '#5B7CFA', 'bg' => '#E8ECFF'],
            ['label' => 'Artikel Dipublikasikan', 'value' => $countArticles, 'subtitle' => 'Konten edukasi', 'trend' => '+10%', 'trendClass' => 'text-success', 'icon' => 'bi-newspaper', 'color' => '#A66DD4', 'bg' => '#F2E8FA'],
        ];

        $statusOrder = [
            \App\Helpers\NutritionStatusHelper::GIZI_BAIK,
            \App\Helpers\NutritionStatusHelper::GIZI_KURANG,
            \App\Helpers\NutritionStatusHelper::GIZI_LEBIH,
            \App\Helpers\NutritionStatusHelper::OBESITAS,
            \App\Helpers\NutritionStatusHelper::PENDEK,
            \App\Helpers\NutritionStatusHelper::SANGAT_PENDEK,
        ];
        $statusLabels = collect($statusOrder);
        $statusTotals = $statusLabels->map(fn ($label) => (int) ($statusDistribution[$label] ?? 0));
    @endphp

    <div id="dashboardSkeleton" class="row g-3 mb-3">
        @for ($i = 0; $i < 6; $i++)
            <div class="col-md-6 col-xl-4"><div class="sg-skeleton"></div></div>
        @endfor
    </div>

    <div id="dashboardError" class="alert alert-danger rounded-4 border-0 d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
            <strong>Dashboard gagal dimuat</strong>
            <button class="btn btn-sm btn-danger rounded-pill" onclick="window.location.reload()">Coba Lagi</button>
        </div>
    </div>

    <div id="dashboardContent" class="d-none">
        <section class="sg-card p-3 mb-3">
            <div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
                <div>
                    <h1 class="sg-page-title">Selamat Datang, Admin</h1>
                    <p class="sg-page-subtitle">Pantau perkembangan gizi dan pertumbuhan anak secara realtime.</p>
                </div>
                <button class="btn btn-primary rounded-4 px-3 py-2" type="button"><i class="bi bi-arrow-clockwise me-1"></i>Refresh</button>
            </div>
        </section>

        <section class="row g-3 mb-3">
            @foreach ($stats as $stat)
                <div class="col-md-6 col-xl-4">
                    <div class="sg-card sg-stat-card p-3 h-100">
                        <div class="d-flex justify-content-between align-items-start gap-3">
                            <div>
                                <div class="sg-stat-label mb-2">{{ $stat['label'] }}</div>
                                <div class="sg-stat-value">{{ number_format($stat['value']) }}</div>
                            </div>
                            <div class="sg-stat-icon" style="background: {{ $stat['bg'] }}; color: {{ $stat['color'] }}">
                                <i class="bi {{ $stat['icon'] }}"></i>
                            </div>
                        </div>
                        <div class="d-flex justify-content-between align-items-center mt-3">
                            <span class="small text-muted">{{ $stat['subtitle'] }}</span>
                            <span class="sg-trend {{ $stat['trendClass'] }}">{{ $stat['trend'] }} bulan ini</span>
                        </div>
                    </div>
                </div>
            @endforeach
        </section>

        <section class="row g-3 mb-3">
            <div class="col-lg-4">
                <div class="sg-card p-3 h-100">
                    <h6 class="fw-semibold mb-1">Status Gizi Anak</h6>
                    <div class="small text-muted mb-2">Ringkasan indikator utama</div>
                    <div class="sg-chart-box-sm"><canvas id="nutritionStatusChart"></canvas></div>
                </div>
            </div>
            <div class="col-lg-5">
                <div class="sg-card p-3 h-100">
                    <h6 class="fw-semibold mb-1">Pengukuran Bulanan</h6>
                    <div class="small text-muted mb-2">Jumlah input 6 bulan terakhir</div>
                    <div class="sg-chart-box"><canvas id="monthlyChart"></canvas></div>
                </div>
            </div>
            <div class="col-lg-3">
                <div class="sg-card p-3 h-100">
                    <h6 class="fw-semibold mb-1">Konsultasi</h6>
                    <div class="small text-muted mb-2">Selesai dan belum dibalas</div>
                    <div class="sg-chart-box-sm"><canvas id="consultationChart"></canvas></div>
                </div>
            </div>
        </section>

        <section class="row g-3">
            <div class="col-xl-5">
                <div class="sg-card p-3 h-100">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <h6 class="fw-semibold mb-0">Quick Action</h6>
                    </div>
                    <div class="row g-2">
                        <div class="col-6"><a class="btn btn-outline-primary rounded-4 w-100 text-start py-2" href="{{ route('admin.articles.index') }}"><i class="bi bi-plus-square me-2"></i>Tambah Artikel</a></div>
                        <div class="col-6"><a class="btn btn-outline-primary rounded-4 w-100 text-start py-2" href="{{ route('admin.consultations') }}"><i class="bi bi-chat-dots me-2"></i>Lihat Konsultasi</a></div>
                        <div class="col-6"><a class="btn btn-outline-primary rounded-4 w-100 text-start py-2" href="{{ route('admin.foods.index', ['filter' => 'Menunggu Verifikasi']) }}"><i class="bi bi-shield-check me-2"></i>Verifikasi Menu</a></div>
                        <div class="col-6"><a class="btn btn-outline-primary rounded-4 w-100 text-start py-2" href="{{ route('admin.nutritionists') }}"><i class="bi bi-person-plus me-2"></i>Tambah Ahli Gizi</a></div>
                    </div>
                </div>
            </div>

            <div class="col-xl-7">
                <div class="sg-card p-3 h-100">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <div>
                            <h6 class="fw-semibold mb-0">Anak Risiko Tinggi</h6>
                            <div class="small text-muted">Pengukuran terakhir</div>
                        </div>
                        <a href="{{ route('admin.children.index') }}" class="btn btn-sm btn-outline-primary rounded-pill">Semua</a>
                    </div>

                    <div class="vstack gap-2">
                        @forelse ($highRiskChildren as $row)
                            @php
                                $child = $row->child;
                                $label = \App\Helpers\NutritionStatusHelper::getStatus($row);
                                $z = \App\Helpers\NutritionStatusHelper::primaryZScore($row);
                            @endphp
                            <div class="sg-compact-item border rounded-4 p-2">
                                <div class="d-flex align-items-center gap-2">
                                    <span class="sg-letter-avatar">{{ strtoupper(substr($child?->nama ?? 'A', 0, 1)) }}</span>
                                    <div class="min-w-0 flex-grow-1">
                                        <div class="fw-semibold text-truncate">{{ $child?->nama ?? 'Data anak' }}</div>
                                        <div class="small text-muted text-truncate">{{ $row->umur_bulan ?? '-' }} bulan - {{ $child?->user?->name ?? '-' }}</div>
                                    </div>
                                    <div class="text-end">
                                        <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($label) }}">{{ $label }}</span>
                                        <div class="small text-muted mt-1">{{ $z['label'] }} : {{ $z['value'] !== null ? sprintf('%+.2f SD', $z['value']) : '-' }}</div>
                                    </div>
                                </div>
                            </div>
                        @empty
                            <div class="text-center text-muted py-3">Belum ada anak risiko tinggi.</div>
                        @endforelse
                    </div>
                </div>
            </div>

            <div class="col-xl-12">
                <div class="sg-card p-3">
                    <div class="d-flex justify-content-between align-items-start gap-2 mb-2">
                        <div>
                            <h6 class="fw-semibold mb-0">Konsultasi Terbaru</h6>
                            <div class="small text-muted">Inbox orang tua</div>
                        </div>
                        <a href="{{ route('admin.consultations') }}" class="btn btn-sm btn-outline-primary rounded-pill sg-inbox-action">Buka</a>
                    </div>

                    <div class="row g-2">
                        @forelse ($latestConsultations as $room)
                            <div class="col-md-6 col-xl-3">
                                <div class="sg-inbox-item">
                                    <div class="d-flex gap-2 align-items-start h-100">
                                        <span class="sg-letter-avatar" style="background:#77C6AC">{{ strtoupper(substr($room->user?->name ?? 'O', 0, 1)) }}</span>
                                        <div class="min-w-0 flex-grow-1 overflow-hidden">
                                            <div class="d-flex justify-content-between align-items-start gap-2">
                                                <div class="sg-inbox-title fw-semibold">{{ $room->user?->name ?? 'Orang tua' }}</div>
                                                <div class="text-end flex-shrink-0">
                                                    <small class="text-muted d-block lh-1">{{ $room->last_message_at?->format('H:i') ?? '-' }}</small>
                                                    <span class="sg-status sg-inbox-status {{ ($room->unread_count ?? 0) > 0 ? 'sg-status-red' : 'sg-status-green' }} mt-1">
                                                        {{ ($room->unread_count ?? 0) > 0 ? 'Belum' : 'Selesai' }}
                                                    </span>
                                                </div>
                                            </div>
                                            <div class="sg-inbox-meta text-muted">{{ $room->child?->nama ?? '-' }}</div>
                                            <div class="sg-inbox-message">{{ $room->last_message ?? 'Belum ada pesan.' }}</div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        @empty
                            <div class="col-12 text-center text-muted py-3">Belum ada konsultasi terbaru.</div>
                        @endforelse
                    </div>
                </div>
            </div>
        </section>
    </div>

    <x-slot:scripts>
        <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
        <script>
            try {
                const commonOptions = {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: { boxWidth: 9, usePointStyle: true, font: { family: 'Inter', size: 10, weight: 500 } }
                        }
                    }
                };

                new Chart(document.getElementById('nutritionStatusChart'), {
                    type: 'doughnut',
                    data: {
                        labels: @json($statusLabels),
                        datasets: [{ data: @json($statusTotals), backgroundColor: ['#38B87C', '#F6A95B', '#7CC9A4', '#EB6B6B', '#F4C95D', '#C94D4D'], borderWidth: 0 }]
                    },
                    options: { ...commonOptions, cutout: '64%' }
                });

                new Chart(document.getElementById('monthlyChart'), {
                    type: 'line',
                    data: {
                        labels: @json($monthlyMeasurements->pluck('label')),
                        datasets: [{ label: 'Pengukuran', data: @json($monthlyMeasurements->pluck('total')), borderColor: '#4B8E96', backgroundColor: 'rgba(75,142,150,.12)', fill: true, tension: .38, pointRadius: 3 }]
                    },
                    options: { ...commonOptions, plugins: { legend: { display: false } }, scales: { x: { ticks: { font: { size: 10 } } }, y: { beginAtZero: true, ticks: { precision: 0, font: { size: 10 } } } } }
                });

                new Chart(document.getElementById('consultationChart'), {
                    type: 'bar',
                    data: { labels: ['Selesai', 'Belum'], datasets: [{ data: [{{ $consultationStats['selesai'] }}, {{ $consultationStats['belum'] }}], backgroundColor: ['#38B87C', '#EB6B6B'], borderRadius: 10 }] },
                    options: { ...commonOptions, plugins: { legend: { display: false } }, scales: { x: { ticks: { font: { size: 10 } } }, y: { beginAtZero: true, ticks: { precision: 0, font: { size: 10 } } } } }
                });

                document.getElementById('dashboardSkeleton')?.classList.add('d-none');
                document.getElementById('dashboardContent')?.classList.remove('d-none');
            } catch (error) {
                document.getElementById('dashboardSkeleton')?.classList.add('d-none');
                document.getElementById('dashboardError')?.classList.remove('d-none');
            }
        </script>
    </x-slot:scripts>
</x-admin-layout>
