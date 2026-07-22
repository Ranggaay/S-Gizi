<x-admin-layout :title="'Monitoring Anak'">
    @php
        $statuses = ['Semua', 'Gizi Baik', 'Gizi Kurang', 'Gizi Lebih', 'Obesitas', 'Pendek', 'Sangat Pendek', 'Belum Diukur'];
        $times = ['Hari Ini', '7 Hari', '30 Hari', 'Semua'];
        $sorts = ['Terbaru diukur', 'Risiko tertinggi', 'Belum diukur', 'Nama anak'];

        $formatAge = function ($child, $measurement) {
            $months = $measurement?->umur_bulan;
            if ($months === null && $child?->tanggal_lahir) {
                $months = (int) $child->tanggal_lahir->diffInMonths(now());
            }
            if ($months === null) {
                return '-';
            }
            $months = (int) round((float) $months);
            $years = intdiv($months, 12);
            $remaining = $months % 12;

            return $years > 0 ? "{$years} Tahun {$remaining} Bulan" : "{$months} Bulan";
        };

        $zText = fn ($value) => $value === null || $value === '' ? '-' : sprintf('%+.2f SD', (float) $value);
        $trendText = function ($latest, $previous) {
            if (!$latest || !$previous) {
                return ['icon' => 'bi-dash-circle', 'label' => 'Trend belum tersedia', 'class' => 'sg-status-gray'];
            }
            $weightDelta = (float) $latest->berat - (float) $previous->berat;
            $heightDelta = (float) $latest->tinggi - (float) $previous->tinggi;
            if ($heightDelta <= 0) {
                return ['icon' => 'bi-exclamation-triangle', 'label' => 'Tinggi stagnan', 'class' => 'sg-status-yellow'];
            }
            if ($weightDelta < 0) {
                return ['icon' => 'bi-arrow-down', 'label' => 'Berat turun', 'class' => 'sg-status-orange'];
            }
            if ($heightDelta > 0) {
                return ['icon' => 'bi-arrow-up', 'label' => 'Tinggi naik baik', 'class' => 'sg-status-green'];
            }

            return ['icon' => 'bi-arrow-up', 'label' => 'Berat naik stabil', 'class' => 'sg-status-green'];
        };
    @endphp

    <div id="monitoringSkeleton" class="row g-3 mb-3">
        @for ($i = 0; $i < 6; $i++)
            <div class="col-md-6 col-xxl-4"><div class="sg-skeleton"></div></div>
        @endfor
    </div>

    <div id="monitoringError" class="alert alert-danger rounded-4 border-0 d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
            <strong>Data monitoring gagal dimuat</strong>
            <button class="btn btn-sm btn-danger rounded-pill" onclick="window.location.reload()">Coba Lagi</button>
        </div>
    </div>

    <div id="monitoringContent" class="d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-3">
            <div>
                <h1 class="sg-page-title">Monitoring Anak</h1>
                <p class="sg-page-subtitle">Pemantauan status gizi dan pertumbuhan anak berdasarkan standar WHO.</p>
            </div>
        </div>

        <section class="row g-2 mb-3">
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Total Anak</div>
                    <div class="fs-4 fw-semibold">{{ number_format($summary['totalChildren']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Risiko Tinggi</div>
                    <div class="fs-4 fw-semibold text-danger">{{ number_format($summary['highRiskCount']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Belum Diukur</div>
                    <div class="fs-4 fw-semibold text-warning">{{ number_format($summary['unmeasuredCount']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Pengukuran Hari Ini</div>
                    <div class="fs-4 fw-semibold text-success">{{ number_format($summary['todayMeasurements']) }}</div>
                </div>
            </div>
        </section>

        <form id="monitoringFilterForm" class="sg-card p-3 mb-3" method="get">
            <div class="row g-3 align-items-end">
                <div class="col-lg-4">
                    <label class="form-label small fw-semibold text-muted">Search realtime</label>
                    <div class="sg-search d-flex align-items-center gap-2 w-100" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input id="monitoringSearch" name="q" value="{{ $q }}" placeholder="Cari nama anak atau orang tua...">
                    </div>
                </div>
                <div class="col-lg-3">
                    <label class="form-label small fw-semibold text-muted">Filter waktu</label>
                    <select class="form-select" name="time" onchange="this.form.submit()">
                        @foreach ($times as $time)
                            <option value="{{ $time }}" @selected($timeFilter === $time)>{{ $time }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-lg-3">
                    <label class="form-label small fw-semibold text-muted">Sorting data</label>
                    <select class="form-select" name="sort" onchange="this.form.submit()">
                        @foreach ($sorts as $option)
                            <option value="{{ $option }}" @selected($sort === $option)>{{ $option }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-lg-2">
                    <button class="btn btn-primary rounded-4 w-100">Terapkan</button>
                </div>
            </div>

            <div class="mt-3">
                <div class="small fw-semibold text-muted mb-2">Filter status</div>
                <div class="sg-filter-scroll">
                    @foreach ($statuses as $status)
                        <button class="btn btn-sm rounded-pill {{ $statusFilter === $status ? 'btn-primary' : 'btn-outline-primary' }}" name="status" value="{{ $status }}" type="submit">
                            {{ $status }}
                        </button>
                    @endforeach
                </div>
            </div>
        </form>

        <section class="row g-3">
            @forelse ($rows as $row)
                @php
                    $child = $row['child'];
                    $latest = $row['latest'];
                    $previous = $row['previous'];
                    $status = $row['status'];
                    $risk = $row['risk'];
                    $trend = $trendText($latest, $previous);
                    $bbuStatus = \App\Helpers\NutritionStatusHelper::bbuStatus($latest);
                    $tbuStatus = \App\Helpers\NutritionStatusHelper::tbuStatus($latest);
                    $bbtbStatus = \App\Helpers\NutritionStatusHelper::bbtbStatus($latest);
                @endphp
                <div class="col-md-6 col-xxl-4">
                    <article class="sg-card sg-monitor-card p-3">
                        <div class="d-flex align-items-start gap-2 mb-3">
                            <span class="sg-letter-avatar">{{ strtoupper(substr($child?->nama ?? 'A', 0, 1)) }}</span>
                            <div class="min-w-0 flex-grow-1">
                                <div class="fw-semibold text-truncate">{{ $child?->nama ?? 'Data anak' }}</div>
                                <div class="small text-muted text-truncate">{{ $child?->user?->name ?? 'Orang tua belum terhubung' }}</div>
                            </div>
                            <div class="text-end flex-shrink-0">
                                <span class="sg-status sg-status-blue">{{ $formatAge($child, $latest) }}</span>
                                <div class="small text-muted mt-1">{{ $latest?->tanggal_ukur?->format('d M Y') ?? 'Belum diukur' }}</div>
                            </div>
                        </div>

                        <div class="d-flex flex-wrap gap-2 mb-3">
                            <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($status) }}">{{ $status }}</span>
                            <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($status) }}">{{ $risk }}</span>
                            <span class="sg-status {{ $trend['class'] }}"><i class="bi {{ $trend['icon'] }}"></i>{{ $trend['label'] }}</span>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-6">
                                <div class="border rounded-4 p-2">
                                    <div class="small text-muted">BB</div>
                                    <div class="fw-semibold">{{ $latest ? number_format((float) $latest->berat, 1) : '-' }} kg</div>
                                </div>
                            </div>
                            <div class="col-6">
                                <div class="border rounded-4 p-2">
                                    <div class="small text-muted">TB</div>
                                    <div class="fw-semibold">{{ $latest ? number_format((float) $latest->tinggi, 1) : '-' }} cm</div>
                                </div>
                            </div>
                        </div>

                        <div class="border rounded-4 px-3 py-2 mb-3">
                            <div class="sg-who-row">
                                <span class="small text-muted">TB/U</span>
                                <span class="small fw-semibold text-truncate">{{ $zText($latest?->z_tbu) }} - {{ $tbuStatus }}</span>
                            </div>
                            <div class="sg-who-row">
                                <span class="small text-muted">BB/U</span>
                                <span class="small fw-semibold text-truncate">{{ $zText($latest?->z_bbu) }} - {{ $bbuStatus }}</span>
                            </div>
                            <div class="sg-who-row">
                                <span class="small text-muted">BB/TB</span>
                                <span class="small fw-semibold text-truncate">{{ $zText($latest?->z_bbtb) }} - {{ $bbtbStatus }}</span>
                            </div>
                        </div>

                        <div class="sg-action-grid">
                            <a href="{{ route('admin.children.show', $child) }}#childDetail" class="btn btn-outline-primary rounded-pill">Detail</a>
                            <a href="{{ route('admin.children.show', $child) }}#growthChart" class="btn btn-outline-primary rounded-pill">Grafik</a>
                            <a href="{{ route('admin.measurements.index', ['q' => $child?->nama]) }}" class="btn btn-outline-primary rounded-pill">Riwayat</a>
                            <a href="{{ route('admin.consultations.child', $child) }}" class="btn btn-primary rounded-pill">Konsultasi</a>
                        </div>
                    </article>
                </div>
            @empty
                <div class="col-12">
                    <div class="sg-card p-5 text-center text-muted">Belum ada data anak.</div>
                </div>
            @endforelse
        </section>

        @if ($rows->hasPages())
            <div class="sg-card p-3 mt-3 d-flex flex-wrap justify-content-between align-items-center gap-2">
                <div class="small text-muted">
                    Menampilkan {{ $rows->firstItem() }}-{{ $rows->lastItem() }} dari {{ $rows->total() }} data
                </div>
                <div>
                    {{ $rows->links('pagination::bootstrap-5') }}
                </div>
            </div>
        @endif
    </div>

    <x-slot:scripts>
        <script>
            try {
                const skeleton = document.getElementById('monitoringSkeleton');
                const content = document.getElementById('monitoringContent');
                skeleton?.classList.add('d-none');
                content?.classList.remove('d-none');

                let timer;
                document.getElementById('monitoringSearch')?.addEventListener('input', (event) => {
                    clearTimeout(timer);
                    timer = setTimeout(() => event.target.form.submit(), 500);
                });
            } catch (error) {
                document.getElementById('monitoringSkeleton')?.classList.add('d-none');
                document.getElementById('monitoringError')?.classList.remove('d-none');
            }
        </script>
    </x-slot:scripts>
</x-admin-layout>
