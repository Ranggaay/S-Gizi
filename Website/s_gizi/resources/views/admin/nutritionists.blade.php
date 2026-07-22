<x-admin-layout :title="'Ahli Gizi'">
    @php
        $filters = ['Semua', 'Aktif', 'Nonaktif', 'Online', 'Offline'];
        $presenceClass = fn ($presence) => $presence === 'Online' ? 'sg-status-green' : 'sg-status-gray';
        $capacityClass = fn ($capacity) => match ($capacity) {
            'Penuh' => 'sg-status-red',
            'Sedang' => 'sg-status-orange',
            default => 'sg-status-green',
        };
    @endphp

    <div id="nutritionistSkeleton" class="row g-3 mb-3">
        @for ($i = 0; $i < 3; $i++)
            <div class="col-md-6 col-xl-4"><div class="sg-skeleton"></div></div>
        @endfor
    </div>

    <div id="nutritionistContent" class="d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-2">
            <div>
                <h1 class="sg-page-title">Ahli Gizi</h1>
                <p class="sg-page-subtitle">Monitoring tenaga gizi, konsultasi aktif, beban kerja, dan status layanan.</p>
            </div>
            <a class="btn btn-primary rounded-4 px-3 py-2" href="{{ route('admin.nutritionists.create') }}">
                <i class="bi bi-plus-lg me-1"></i>Tambah Ahli Gizi
            </a>
        </div>

        <section class="row g-2 mb-3 sg-nutri-summary">
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Total Ahli Gizi</div><div class="fs-4 fw-semibold">{{ number_format($summary['totalNutritionists']) }}</div></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Sedang Aktif</div><div class="fs-4 fw-semibold text-success">{{ number_format($summary['onlineToday']) }}</div></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Konsultasi Aktif</div><div class="fs-4 fw-semibold text-warning">{{ number_format($summary['activeConsultations']) }}</div></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Ahli Tersedia</div><div class="fs-4 fw-semibold text-primary">{{ number_format($summary['availableNutritionists']) }}</div></div></div>
        </section>

        <form class="sg-card p-2 p-lg-3 mb-3 sg-nutri-filter" method="get">
            <input type="hidden" name="filter" value="{{ $filter }}">
            <div class="row g-2 align-items-end">
                <div class="col-lg-6">
                    <label class="form-label small fw-semibold text-muted">Search realtime</label>
                    <div class="sg-search d-flex align-items-center gap-2 w-100" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input id="nutritionistSearch" name="q" value="{{ $q }}" placeholder="Cari nama ahli gizi atau spesialisasi...">
                    </div>
                </div>
                <div class="col-lg-2">
                    <button class="btn btn-primary rounded-4 w-100">Terapkan</button>
                </div>
            </div>
            <div class="mt-2">
                <div class="small fw-semibold text-muted mb-2">Filter monitoring</div>
                <div class="sg-filter-scroll">
                    @foreach ($filters as $item)
                        <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">{{ $item }}</button>
                    @endforeach
                </div>
            </div>
        </form>

        <section class="row g-3">
            @forelse ($rows as $row)
                @php($nutritionist = $row['nutritionist'])
                <div class="col-md-6 col-xl-4">
                    <article class="sg-card sg-nutri-card h-100">
                        <div class="d-flex align-items-start gap-2">
                            @if ($row['avatar'])
                                <img class="sg-nutri-photo" src="{{ asset($row['avatar']) }}" alt="Foto {{ $row['name'] }}">
                            @else
                                <span class="sg-letter-avatar sg-nutri-avatar">{{ strtoupper(substr($row['name'], 0, 1)) }}</span>
                            @endif
                            <div class="min-w-0 flex-grow-1">
                                <div class="d-flex justify-content-between gap-2">
                                    <div class="min-w-0">
                                        <h6 class="fw-semibold mb-1 text-truncate">{{ $row['name'] }}</h6>
                                        <div class="small text-muted text-truncate">{{ $row['experience'] }}</div>
                                        <div class="small text-muted text-truncate">Terakhir online: {{ $row['last_online_label'] }}</div>
                                    </div>
                                    <span class="sg-status {{ $presenceClass($row['presence']) }}">{{ $row['presence'] }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex flex-wrap gap-1 mt-3">
                            @foreach ($row['specializations'] as $chip)
                                <span class="sg-chip">{{ $chip }}</span>
                            @endforeach
                        </div>

                        <div class="sg-nutri-metrics mt-3">
                            <div><span>Konsultasi Aktif</span><strong>{{ $row['active_consultations'] }}</strong></div>
                            <div><span>Selesai</span><strong>{{ $row['completed_consultations'] }}</strong></div>
                            <div><span>Anak Dipantau</span><strong>{{ $row['monitored_children'] }}</strong></div>
                            <div><span>Keluarga</span><strong>{{ $row['monitored_families'] }}</strong></div>
                        </div>

                        <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mt-3">
                            <span class="sg-status {{ $capacityClass($row['capacity']) }}">Kapasitas {{ $row['capacity'] }}</span>
                            <span class="sg-status {{ $row['account_status'] === 'Aktif' ? 'sg-status-green' : 'sg-status-gray' }}">{{ $row['account_status'] }}</span>
                            <span class="small text-muted">Respon {{ $row['avg_response'] }}</span>
                        </div>

                        <div class="sg-nutri-actions mt-3">
                            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.nutritionists.edit', $nutritionist) }}"><i class="bi bi-pencil me-1"></i>Edit</a>
                            <a class="btn btn-sm btn-primary rounded-pill" href="{{ route('admin.nutritionists.show', $nutritionist) }}"><i class="bi bi-eye me-1"></i>Detail</a>
                            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.consultations.nutritionist', $nutritionist) }}"><i class="bi bi-clock-history me-1"></i>Riwayat</a>
                            <form method="post" action="{{ $row['account_status'] === 'Aktif' ? route('admin.nutritionists.deactivate', $nutritionist) : route('admin.nutritionists.activate', $nutritionist) }}" data-confirm="{{ $row['account_status'] === 'Aktif' ? 'Nonaktifkan' : 'Aktifkan' }} {{ $row['name'] }}?">
                                @csrf
                                @method('PATCH')
                                <button class="btn btn-sm btn-outline-warning rounded-pill" type="submit"><i class="bi bi-exclamation-triangle me-1"></i>{{ $row['account_status'] === 'Aktif' ? 'Nonaktifkan' : 'Aktifkan' }}</button>
                            </form>
                        </div>
                    </article>
                </div>
            @empty
                <div class="col-12"><div class="sg-card p-5 text-center text-muted">Belum ada tenaga ahli gizi.</div></div>
            @endforelse
        </section>

        @if ($rows->hasPages())
            <div class="mt-3">{{ $rows->links('pagination::bootstrap-5') }}</div>
        @endif
    </div>

    <x-slot:styles>
        <style>
            .sg-nutri-summary .sg-mini-metric { min-height: 72px; padding: 12px 14px; border-radius: 16px; }
            .sg-nutri-summary .fs-4 { font-size: 1.28rem !important; line-height: 1.15; }
            .sg-nutri-filter .form-label { margin-bottom: 4px; }
            .sg-nutri-filter .sg-search,
            .sg-nutri-filter .btn { min-height: 38px; height: 38px; font-size: 14px; }
            .sg-nutri-filter .sg-search { padding: 0 12px; }
            .sg-nutri-filter .sg-filter-scroll { gap: 6px; }
            .sg-nutri-filter .sg-filter-scroll .btn { min-height: 34px; height: 34px; padding: 5px 12px; font-size: 13px; }
            .sg-nutri-card { padding: 14px; border-radius: 18px; transition: transform .18s ease, box-shadow .18s ease; }
            .sg-nutri-card:hover { transform: translateY(-2px); box-shadow: 0 16px 34px rgba(22, 71, 80, .09); }
            .sg-nutri-avatar { width: 46px; height: 46px; border-radius: 15px; flex: 0 0 46px; background: #4B8E96; }
            .sg-nutri-photo { width: 46px; height: 46px; border-radius: 15px; flex: 0 0 46px; object-fit: cover; border: 1px solid rgba(75,142,150,.18); }
            .sg-chip { display: inline-flex; align-items: center; min-height: 25px; padding: 4px 9px; border-radius: 999px; background: #EAF6F4; color: #2f7580; font-size: 11.5px; font-weight: 700; }
            .sg-nutri-metrics { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
            .sg-nutri-metrics div { border: 1px solid rgba(75,142,150,.14); border-radius: 14px; padding: 8px 10px; background: #FBFEFE; }
            .sg-nutri-metrics span { display: block; color: #64748b; font-size: 11.5px; line-height: 1.15; }
            .sg-nutri-metrics strong { font-size: 18px; line-height: 1.1; }
            .sg-nutri-actions { display: flex; flex-wrap: wrap; gap: 6px; }
            .sg-nutri-actions .btn { min-height: 32px; padding: 5px 10px; font-size: 12px; }
        </style>
    </x-slot:styles>

    <x-slot:scripts>
        <script>
            document.getElementById('nutritionistSkeleton')?.classList.add('d-none');
            document.getElementById('nutritionistContent')?.classList.remove('d-none');

            let nutritionistTimer;
            document.getElementById('nutritionistSearch')?.addEventListener('input', (event) => {
                clearTimeout(nutritionistTimer);
                nutritionistTimer = setTimeout(() => event.target.form.submit(), 500);
            });
        </script>
    </x-slot:scripts>
</x-admin-layout>
