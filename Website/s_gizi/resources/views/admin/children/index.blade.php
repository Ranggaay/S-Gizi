<x-admin-layout :title="'Data Anak'">
    @php
        $filters = ['Semua', 'Gizi Buruk', 'Gizi Kurang', 'Gizi Baik', 'Gizi Lebih', 'Obesitas', 'Stunting', 'Risiko Tinggi', 'Belum Diukur', 'Belum Ukur > 30 Hari'];
        $times = ['Hari Ini', '7 Hari', '30 Hari', 'Semua'];
        $archives = ['aktif' => 'Aktif', 'arsip' => 'Diarsipkan', 'semua' => 'Semua'];
        $sorts = [
            'terbaru' => 'Terbaru diukur',
            'risiko' => 'Risiko tertinggi',
            'nama' => 'Nama A-Z',
            'umur' => 'Umur',
        ];
        $genderLabel = fn ($value) => $value === 'P' ? 'Perempuan' : 'Laki-laki';
        $ageLabel = function (?int $months) {
            if ($months === null) return '-';
            if ($months < 12) return $months.' bulan';
            $years = intdiv($months, 12);
            $remaining = $months % 12;
            return $remaining > 0 ? "{$years} tahun {$remaining} bulan" : "{$months} bulan";
        };
        $statusClass = fn ($status) => $status === 'Di luar batas WHO balita'
            ? 'sg-status-yellow'
            : \App\Helpers\NutritionStatusHelper::badgeClass($status);
        $riskClass = fn ($risk) => match ($risk) {
            'Risiko Tinggi' => 'sg-status-red',
            'Perlu Pantau' => 'sg-status-orange',
            'Stabil' => 'sg-status-green',
            default => 'sg-status-gray',
        };
        $zScore = function ($label, $value) {
            return $value !== null ? $label.' '.sprintf('%+.2f SD', (float) $value) : $label.' -';
        };
        $measurementDate = function ($measurement) {
            $rawDate = $measurement?->getRawOriginal('tanggal_ukur');
            if (!$rawDate) return '-';

            return \Illuminate\Support\Carbon::parse($rawDate)->locale('id')->translatedFormat('d M Y');
        };
        $isSuperAdmin = auth()->user()?->role === 'super_admin';
    @endphp

    <div id="childrenSkeleton" class="row g-3 mb-3">
        @for ($i = 0; $i < 4; $i++)
            <div class="col-md-6 col-xl-3"><div class="sg-skeleton"></div></div>
        @endfor
    </div>

    <div id="childrenError" class="alert alert-danger rounded-4 border-0 d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
            <strong>Data anak gagal dimuat</strong>
            <button class="btn btn-sm btn-danger rounded-pill" onclick="window.location.reload()">Coba Lagi</button>
        </div>
    </div>

    <div id="childrenContent" class="d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-2">
            <div>
                <h1 class="sg-page-title">Data Anak</h1>
                <p class="sg-page-subtitle">Monitoring data kesehatan anak, status gizi WHO, risiko pertumbuhan, dan aktivitas keluarga.</p>
            </div>
            <a class="btn btn-primary rounded-4 px-3 py-2" href="{{ route('admin.children.create') }}">
                <i class="bi bi-plus-lg me-1"></i>Tambah Anak
            </a>
        </div>

        <section class="row g-2 mb-2 sg-child-summary">
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
                    <div class="fs-4 fw-semibold text-secondary">{{ number_format($summary['unmeasuredCount']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Pengukuran Hari Ini</div>
                    <div class="fs-4 fw-semibold text-success">{{ number_format($summary['todayMeasurements']) }}</div>
                </div>
            </div>
        </section>

        <form class="sg-card p-2 p-lg-3 mb-3 sg-child-filter" method="get">
            <input type="hidden" name="filter" value="{{ $filter }}">
            <div class="row g-2 align-items-end">
                <div class="col-lg-6">
                    <label class="form-label small fw-semibold text-muted">Search realtime</label>
                    <div class="sg-search d-flex align-items-center gap-2 w-100" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input id="childSearch" name="q" value="{{ $q }}" placeholder="Cari nama anak atau orang tua...">
                    </div>
                </div>
                <div class="col-lg-2">
                    <label class="form-label small fw-semibold text-muted">Waktu</label>
                    <select class="form-select" name="time" onchange="this.form.submit()">
                        @foreach ($times as $option)
                            <option value="{{ $option }}" @selected($time === $option)>{{ $option }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-lg-2">
                    <label class="form-label small fw-semibold text-muted">Arsip</label>
                    <select class="form-select" name="archive" onchange="this.form.submit()">
                        @foreach ($archives as $value => $label)
                            <option value="{{ $value }}" @selected($archive === $value)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-lg-2">
                    <label class="form-label small fw-semibold text-muted">Sorting</label>
                    <select class="form-select" name="sort" onchange="this.form.submit()">
                        @foreach ($sorts as $value => $label)
                            <option value="{{ $value }}" @selected($sort === $value)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-lg-2 col-xl-2">
                    <button class="btn btn-primary rounded-4 w-100">Terapkan</button>
                </div>
            </div>

            <div class="mt-2">
                <div class="small fw-semibold text-muted mb-2">Filter status WHO</div>
                <div class="sg-filter-scroll">
                    @foreach ($filters as $item)
                        <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">
                            {{ $item }}
                        </button>
                    @endforeach
                </div>
            </div>
        </form>

        <section class="sg-card p-2 p-lg-3 sg-child-table-card">
            <div class="d-none d-xl-grid px-2 pb-2 text-muted small fw-semibold sg-child-head">
                <div>Anak & Keluarga</div>
                <div>Status Terakhir</div>
                <div>Status WHO</div>
                <div>Pengukuran</div>
                <div>Monitoring</div>
                <div></div>
            </div>

            <div class="vstack gap-2 sg-child-list">
                @forelse ($children as $row)
                    @php
                        $child = $row['child'];
                        $latest = $row['latest'];
                        $status = $row['status'];
                        $risk = $row['risk'];
                        $outsideWho = $status === 'Di luar batas WHO balita';
                        $bbu = $outsideWho ? 'Di luar batas WHO balita' : \App\Helpers\NutritionStatusHelper::bbuStatus($latest);
                        $tbu = $outsideWho ? 'Di luar batas WHO balita' : \App\Helpers\NutritionStatusHelper::tbuStatus($latest);
                        $bbtb = $outsideWho ? 'Di luar batas WHO balita' : \App\Helpers\NutritionStatusHelper::bbtbStatus($latest);
                        $primary = $latest ? \App\Helpers\NutritionStatusHelper::primaryZScore($latest) : ['label' => 'BB/TB', 'value' => null];
                    @endphp
                    <article class="sg-child-row">
                        <div class="d-flex align-items-start gap-2 min-w-0">
                            <span class="sg-letter-avatar">{{ strtoupper(substr($child->nama ?? 'A', 0, 1)) }}</span>
                            <div class="min-w-0">
                                <div class="fw-semibold text-truncate">
                                    {{ $child->nama }}
                                    @if ($child->trashed())
                                        <span class="sg-status sg-status-gray ms-1">Diarsipkan</span>
                                    @endif
                                </div>
                                <div class="small text-muted sg-child-meta">{{ $genderLabel($child->jenis_kelamin) }} &bull; {{ $ageLabel($row['age_months']) }}</div>
                                <div class="small text-muted text-truncate">Orang Tua: {{ $child->user?->name ?? '-' }}</div>
                            </div>
                        </div>

                        <div>
                            <span class="sg-family-label">Status</span>
                            <div class="d-flex flex-wrap gap-1 align-items-center">
                                <span class="sg-status {{ $statusClass($status) }}">{{ $status }}</span>
                            </div>
                            <div class="small fw-semibold mt-1 sg-zscore">{{ $zScore($primary['label'], $primary['value']) }}</div>
                        </div>

                        <div class="sg-who-list">
                            <div><span>BB/U</span><strong>{{ $bbu }}</strong></div>
                            <div><span>TB/U</span><strong>{{ $tbu }}</strong></div>
                            <div><span>BB/TB</span><strong>{{ $bbtb }}</strong></div>
                        </div>

                        <div>
                            <span class="sg-family-label">Pengukuran</span>
                            <div class="fw-semibold sg-count">{{ $child->measurements_count }}x</div>
                            <div class="small text-muted sg-date">Terakhir: {{ $measurementDate($latest) }}</div>
                        </div>

                        <div>
                            <span class="sg-family-label">Monitoring</span>
                            <span class="sg-status {{ $riskClass($risk) }}">{{ $risk }}</span>
                            @if ($latest === null)
                                <div class="small text-muted mt-1"><i class="bi bi-activity me-1"></i>Belum ada data WHO</div>
                            @elseif ($latest->tanggal_ukur?->lt(now()->subDays(30)))
                                <div class="small text-warning mt-1 sg-warning-line">Belum ukur &gt; 30 hari</div>
                            @endif
                        </div>

                        <div class="dropdown text-end sg-row-action">
                            <button class="btn btn-sm btn-outline-primary rounded-4" data-bs-toggle="dropdown" type="button" title="Aksi data anak">
                                <i class="bi bi-three-dots-vertical"></i>
                            </button>
                            <div class="dropdown-menu dropdown-menu-end p-2">
                                <a class="dropdown-item rounded-3" href="{{ route('admin.children.show', $child) }}"><i class="bi bi-eye me-2"></i>Detail</a>
                                @if (!$child->trashed())
                                    <a class="dropdown-item rounded-3" href="{{ route('admin.children.edit', $child) }}"><i class="bi bi-pencil me-2"></i>Edit</a>
                                    @if ($isSuperAdmin)
                                        <form method="post" action="{{ route('admin.children.destroy', $child) }}" data-confirm="Arsipkan data {{ $child->nama }}? Riwayat tetap aman dan tidak dihapus permanen.">
                                            @csrf
                                            @method('DELETE')
                                            <button class="dropdown-item rounded-3 text-warning" type="submit"><i class="bi bi-archive me-2"></i>Arsipkan</button>
                                        </form>
                                    @endif
                                @else
                                    <form method="post" action="{{ route('admin.children.restore', $child) }}" data-confirm="Aktifkan kembali data {{ $child->nama }}?">
                                        @csrf
                                        @method('PATCH')
                                        <button class="dropdown-item rounded-3 text-success" type="submit"><i class="bi bi-arrow-counterclockwise me-2"></i>Aktifkan</button>
                                    </form>
                                @endif
                            </div>
                        </div>
                    </article>
                @empty
                    <div class="text-center text-muted py-5">Belum ada data anak.</div>
                @endforelse
            </div>

            @if ($children->hasPages())
                <div class="pt-3 mt-3 border-top d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <div class="small text-muted">Menampilkan {{ $children->firstItem() }}-{{ $children->lastItem() }} dari {{ $children->total() }} data</div>
                    {{ $children->links('pagination::bootstrap-5') }}
                </div>
            @endif
        </section>
    </div>

    <x-slot:styles>
        <style>
            .sg-child-summary .sg-mini-metric {
                min-height: 72px;
                padding: 12px 14px;
                border-radius: 16px;
            }
            .sg-child-summary .fs-4 {
                font-size: 1.28rem !important;
                line-height: 1.15;
            }
            .sg-child-filter .form-label {
                margin-bottom: 4px;
            }
            .sg-child-filter .sg-search,
            .sg-child-filter .form-select,
            .sg-child-filter .btn {
                min-height: 38px;
                height: 38px;
                font-size: 14px;
            }
            .sg-child-filter .sg-search {
                padding: 0 12px;
            }
            .sg-child-filter .sg-filter-scroll {
                gap: 6px;
            }
            .sg-child-filter .sg-filter-scroll .btn {
                min-height: 34px;
                height: 34px;
                padding: 5px 12px;
                font-size: 13px;
            }
            .sg-child-table-card {
                overflow: visible;
            }
            .sg-child-head {
                grid-template-columns: minmax(210px,1.22fr) minmax(140px,.72fr) minmax(185px,.92fr) minmax(112px,.55fr) minmax(120px,.58fr) 40px;
                gap: 10px;
                font-size: 12px;
            }
            .sg-child-list {
                max-width: 100%;
                overflow: visible;
            }
            .sg-child-row {
                display: grid;
                grid-template-columns: minmax(210px, 1.22fr) minmax(140px, .72fr) minmax(185px, .92fr) minmax(112px, .55fr) minmax(120px, .58fr) 40px;
                gap: 10px;
                align-items: center;
                padding: 9px 10px;
                border: 1px solid rgba(75, 142, 150, .14);
                border-radius: 16px;
                background: #fff;
                box-shadow: 0 8px 18px rgba(23, 65, 73, .045);
                transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
                max-width: 100%;
                min-width: 0;
                font-size: 13px;
            }
            .sg-child-row:hover {
                transform: translateY(-1px);
                border-color: rgba(75, 142, 150, .28);
                box-shadow: 0 12px 24px rgba(23, 65, 73, .07);
            }
            .sg-child-row .sg-letter-avatar {
                width: 42px;
                height: 42px;
                border-radius: 14px;
                font-size: 17px;
                flex: 0 0 42px;
            }
            .sg-child-row .fw-semibold {
                line-height: 1.2;
            }
            .sg-child-meta,
            .sg-child-row .small {
                line-height: 1.25;
            }
            .sg-child-row .sg-status {
                padding: 5px 10px;
                max-width: 100%;
                font-size: 11px;
            }
            .sg-zscore {
                font-size: 12.5px;
                white-space: nowrap;
            }
            .sg-who-list {
                display: grid;
                gap: 3px;
                font-size: 12.5px;
            }
            .sg-who-list div {
                display: flex;
                justify-content: space-between;
                gap: 8px;
                min-width: 0;
                border-bottom: 1px solid rgba(15, 23, 42, .06);
                padding-bottom: 3px;
            }
            .sg-who-list div:last-child {
                border-bottom: 0;
                padding-bottom: 0;
            }
            .sg-who-list span {
                color: #64748b;
                white-space: nowrap;
            }
            .sg-who-list strong {
                font-weight: 600;
                text-align: right;
                overflow-wrap: anywhere;
                line-height: 1.15;
            }
            .sg-count {
                font-size: 17px;
                line-height: 1.1;
            }
            .sg-date,
            .sg-warning-line {
                line-height: 1.25;
            }
            .sg-warning-line {
                max-width: 100px;
            }
            .sg-row-action {
                min-width: 40px;
            }
            .sg-row-action .btn {
                width: 34px;
                height: 34px;
                padding: 0;
                display: inline-flex;
                align-items: center;
                justify-content: center;
            }
            @media (max-width: 1199.98px) {
                .sg-child-row {
                    grid-template-columns: minmax(0, 1fr) minmax(170px, .72fr);
                    align-items: start;
                }
                .sg-child-row > .sg-row-action {
                    grid-column: 2;
                    grid-row: 1;
                }
            }
            @media (max-width: 767.98px) {
                .sg-child-row {
                    grid-template-columns: minmax(0, 1fr);
                }
                .sg-child-row > .sg-row-action {
                    grid-column: auto;
                    grid-row: auto;
                    text-align: left !important;
                }
            }
        </style>
    </x-slot:styles>

    <x-slot:scripts>
        <script>
            try {
                document.getElementById('childrenSkeleton')?.classList.add('d-none');
                document.getElementById('childrenContent')?.classList.remove('d-none');

                let timer;
                document.getElementById('childSearch')?.addEventListener('input', (event) => {
                    clearTimeout(timer);
                    timer = setTimeout(() => event.target.form.submit(), 500);
                });
            } catch (error) {
                document.getElementById('childrenSkeleton')?.classList.add('d-none');
                document.getElementById('childrenError')?.classList.remove('d-none');
            }
        </script>
    </x-slot:scripts>
</x-admin-layout>
