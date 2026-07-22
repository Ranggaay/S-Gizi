<x-admin-layout :title="'Rekomendasi Makanan'">
    @php
        $filters = ['Semua', 'Menunggu Verifikasi', 'Dari Ahli Gizi', 'Published', 'Draft', 'Ditolak', 'Gizi Kurang', 'Stunting', 'Obesitas', 'Gizi Baik', 'MPASI', 'Tinggi Protein', 'Rendah Gula'];
        $archives = ['aktif' => 'Aktif', 'arsip' => 'Diarsipkan', 'semua' => 'Semua'];
        $statusClass = fn ($status) => match ($status) {
            'Gizi Buruk', 'Obesitas', 'Stunting' => 'sg-status-red',
            'Gizi Kurang', 'Gizi Lebih' => 'sg-status-orange',
            'Risiko Berat Badan Lebih' => 'sg-status-yellow',
            'Gizi Baik', 'Published' => 'sg-status-green',
            'Menunggu Verifikasi', 'Draft' => 'sg-status-orange',
            'Ditolak' => 'sg-status-red',
            'Archived' => 'sg-status-gray',
            default => 'sg-status-blue',
        };
    @endphp

    <div id="foodSkeleton" class="row g-3 mb-3">
        @for ($i = 0; $i < 4; $i++)
            <div class="col-sm-6 col-xl-3"><div class="sg-skeleton" style="min-height:82px"></div></div>
        @endfor
    </div>

    <div id="foodContent" class="d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
            <div>
                <h1 class="sg-page-title">Rekomendasi Makanan</h1>
                <p class="sg-page-subtitle">Sistem rekomendasi gizi anak berbasis WHO, usia, dan kondisi pertumbuhan.</p>
            </div>
            <a class="btn btn-sm btn-primary rounded-pill px-3" href="{{ route('admin.foods.create') }}">
                <i class="bi bi-plus-lg me-1"></i>Tambah Menu
            </a>
        </div>

        <section class="row g-2 mb-3">
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-food-mini"><span>Total Menu</span><strong>{{ number_format($summary['total']) }}</strong></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-food-mini"><span>Menunggu Verifikasi</span><strong class="text-warning">{{ number_format($summary['pending']) }}</strong></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-food-mini"><span>Menu Obesitas</span><strong class="text-danger">{{ number_format($summary['obesitas']) }}</strong></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-food-mini"><span>Draft Menu</span><strong class="text-primary">{{ number_format($summary['draft']) }}</strong></div></div>
        </section>

        <form class="sg-card p-3 mb-3" method="get">
            <div class="row g-2 align-items-end">
                <div class="col-lg-6">
                    <label class="form-label small fw-semibold text-muted">Search realtime</label>
                    <div class="sg-search d-flex align-items-center gap-2 w-100" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input id="foodSearch" name="q" value="{{ $q }}" placeholder="Cari nama makanan, status WHO, kategori, atau nutrisi...">
                    </div>
                </div>
                <div class="col-lg-2">
                    <label class="form-label small fw-semibold text-muted">Arsip</label>
                    <select class="form-select rounded-4" name="archive">
                        @foreach ($archives as $value => $label)
                            <option value="{{ $value }}" @selected($archive === $value)>{{ $label }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-lg-2">
                    <button class="btn btn-primary rounded-4 w-100">Terapkan</button>
                </div>
                <div class="col-12">
                    <div class="sg-filter-scroll">
                        @foreach ($filters as $item)
                            <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">
                                {{ $item }}
                            </button>
                        @endforeach
                    </div>
                </div>
            </div>
        </form>

        <section class="sg-food-grid">
            @forelse ($foods as $food)
                @php
                    $targetStatus = \App\Helpers\NutritionStatusHelper::localize($food->kategori_status);
                    if (in_array($food->kategori_status, ['Gizi Buruk', 'Gizi Kurang', 'Gizi Baik', 'Risiko Berat Badan Lebih', 'Gizi Lebih', 'Obesitas', 'Stunting'], true)) {
                        $targetStatus = $food->kategori_status;
                    }
                    $badges = $food->badges ?: [$food->prioritas_menu ?? 'Menu Utama'];
                    $thumbnail = $food->thumbnail ? asset($food->thumbnail) : null;
                    $ageLabel = $food->usia_kategori ?: "{$food->usia_min}-{$food->usia_max} bulan";
                    $isArchived = ($food->status_menu ?? 'Published') === 'Archived';
                    $creatorName = $food->creator?->name ?: 'Admin S-Gizi';
                    $creatorRole = $food->creator?->role === 'nutritionist' ? 'Dari Ahli Gizi' : 'Dibuat Admin';
                @endphp
                <article class="sg-card sg-food-card">
                    <a class="sg-food-photo" href="{{ route('admin.foods.show', $food) }}">
                        @if ($thumbnail)
                            <img src="{{ $thumbnail }}" alt="{{ $food->nama }}">
                        @else
                            <span><i class="bi bi-egg-fried"></i></span>
                        @endif
                    </a>
                    <div class="sg-food-body">
                        <div class="d-flex justify-content-between align-items-start gap-2 mb-2">
                            <div class="min-w-0">
                                <h6 class="fw-semibold mb-1 text-truncate">{{ $food->nama }}</h6>
                                <div class="d-flex flex-wrap gap-1">
                                    <span class="sg-status {{ $statusClass($targetStatus) }}">{{ $targetStatus }}</span>
                                    <span class="sg-status sg-status-blue">{{ $ageLabel }}</span>
                                    <span class="sg-status {{ $statusClass($food->status_menu ?? 'Published') }}">{{ $food->status_menu ?? 'Published' }}</span>
                                </div>
                            </div>
                        </div>

                        <div class="sg-food-nutrition">
                            <div><span>Kalori</span><strong>{{ $food->kalori }} kkal</strong></div>
                            <div><span>Protein</span><strong>{{ $food->protein }} g</strong></div>
                            <div><span>Karbo</span><strong>{{ $food->karbohidrat }} g</strong></div>
                            <div><span>Lemak</span><strong>{{ $food->lemak }} g</strong></div>
                            <div><span>Serat</span><strong>{{ $food->serat ?? 0 }} g</strong></div>
                            <div><span>Gula</span><strong>{{ $food->gula ?? 0 }} g</strong></div>
                        </div>

                        <div class="d-flex flex-wrap gap-1 my-2">
                            <span class="sg-status {{ $creatorRole === 'Dari Ahli Gizi' ? 'sg-status-blue' : 'sg-status-gray' }}">{{ $creatorRole }}</span>
                            <span class="sg-status sg-status-gray">{{ $creatorName }}</span>
                            @foreach ($badges as $badge)
                                <span class="sg-chip">{{ $badge }}</span>
                            @endforeach
                        </div>
                        @if (($food->status_menu ?? null) === 'Ditolak' && $food->rejection_reason)
                            <div class="small text-danger mb-2"><strong>Alasan ditolak:</strong> {{ $food->rejection_reason }}</div>
                        @endif

                        <div class="sg-food-reason">
                            <strong>Mengapa cocok?</strong>
                            <p>{{ Str::limit($food->alasan, 118) }}</p>
                        </div>

                        <div class="d-flex flex-wrap gap-1 mt-3">
                            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.foods.edit', $food) }}"><i class="bi bi-pencil"></i> Edit</a>
                            <a class="btn btn-sm btn-outline-secondary rounded-pill" href="{{ route('admin.foods.show', $food) }}"><i class="bi bi-eye"></i> Preview</a>
                            @if (($food->status_menu ?? null) === 'Menunggu Verifikasi')
                                <form method="post" action="{{ route('admin.foods.approve', $food) }}" data-confirm="Setujui dan publish rekomendasi ini?">
                                    @csrf @method('PATCH')
                                    <button class="btn btn-sm btn-success rounded-pill"><i class="bi bi-check2-circle"></i> Setujui</button>
                                </form>
                                <form method="post" action="{{ route('admin.foods.reject', $food) }}" class="sg-reject-form">
                                    @csrf @method('PATCH')
                                    <input type="hidden" name="rejection_reason">
                                    <button class="btn btn-sm btn-outline-danger rounded-pill"><i class="bi bi-x-circle"></i> Tolak</button>
                                </form>
                            @endif
                            @unless ($isArchived)
                                <form method="post" action="{{ route('admin.foods.archive', $food) }}" data-confirm="Arsipkan menu ini?">
                                    @csrf @method('PATCH')
                                    <button class="btn btn-sm btn-outline-warning rounded-pill"><i class="bi bi-archive"></i> Arsipkan</button>
                                </form>
                            @endunless
                            <form method="post" action="{{ route('admin.foods.destroy', $food) }}" data-confirm="Hapus menu ini?">
                                @csrf @method('DELETE')
                                <button class="btn btn-sm btn-outline-danger rounded-pill"><i class="bi bi-trash"></i> Hapus</button>
                            </form>
                        </div>
                    </div>
                </article>
            @empty
                <div class="sg-card p-5 text-center text-muted">
                    Belum ada rekomendasi makanan{{ $recommendationStatus && $recommendationStatus !== 'Semua' ? ' untuk status '.$recommendationStatus : '' }}.
                </div>
            @endforelse
        </section>

        @if ($foods->hasPages())
            <div class="pt-3 mt-3">{{ $foods->links('pagination::bootstrap-5') }}</div>
        @endif
    </div>

    <x-slot:styles>
        <style>
            .sg-food-mini { min-height: 76px; padding: 12px 14px; display: flex; align-items: center; justify-content: space-between; gap: 10px; }
            .sg-food-mini span { color: var(--sgizi-muted); font-size: 12px; font-weight: 650; }
            .sg-food-mini strong { font-size: 24px; line-height: 1; }
            .sg-food-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; }
            .sg-food-card { overflow: hidden; min-width: 0; transition: .18s ease; }
            .sg-food-card:hover { transform: translateY(-3px); box-shadow: 0 18px 38px rgba(35, 76, 82, .12); }
            .sg-food-photo { display: block; height: 132px; background: #EAF6F4; color: var(--sgizi); overflow: hidden; }
            .sg-food-photo img { width: 100%; height: 100%; object-fit: cover; }
            .sg-food-photo span { height: 100%; display: grid; place-items: center; font-size: 36px; }
            .sg-food-body { padding: 12px; }
            .sg-food-nutrition { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px; }
            .sg-food-nutrition div { border: 1px solid rgba(75,142,150,.14); border-radius: 12px; padding: 7px 8px; background: #FAFDFD; min-width: 0; }
            .sg-food-nutrition span { display: block; color: var(--sgizi-muted); font-size: 10.5px; font-weight: 650; }
            .sg-food-nutrition strong { display: block; font-size: 12.5px; white-space: nowrap; }
            .sg-food-reason { border-radius: 14px; padding: 9px 10px; background: #F7FBFB; border: 1px solid rgba(75,142,150,.12); }
            .sg-food-reason strong { display: block; font-size: 12px; margin-bottom: 3px; }
            .sg-food-reason p { color: var(--sgizi-muted); font-size: 12px; margin: 0; line-height: 1.45; }
            @media (max-width: 1399.98px) { .sg-food-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
            @media (max-width: 767.98px) {
                .sg-food-grid { grid-template-columns: minmax(0, 1fr); }
                .sg-food-nutrition { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            }
        </style>
    </x-slot:styles>

    <x-slot:scripts>
        <script>
            document.getElementById('foodSkeleton')?.classList.add('d-none');
            document.getElementById('foodContent')?.classList.remove('d-none');
            document.getElementById('foodSearch')?.addEventListener('input', (event) => {
                clearTimeout(window.foodSearchTimer);
                window.foodSearchTimer = setTimeout(() => event.target.form.submit(), 500);
            });
        </script>
    </x-slot:scripts>
</x-admin-layout>
