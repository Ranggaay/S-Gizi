<x-admin-layout :title="'Orang Tua'">
    @php
        $filters = ['Semua', 'Aktif', 'Nonaktif', 'Risiko Tinggi', 'Belum Ukur', 'Konsultasi Aktif'];
        $sorts = ['Terbaru daftar', 'Nama', 'Jumlah anak terbanyak', 'Risiko tertinggi'];
        $formatPhone = function (?string $phone) {
            $digits = preg_replace('/\D+/', '', (string) $phone);
            if ($digits === '') return '-';
            if (str_starts_with($digits, '0')) {
                $digits = '62'.substr($digits, 1);
            }
            if (!str_starts_with($digits, '62')) {
                $digits = '62'.$digits;
            }
            $national = substr($digits, 2);
            $parts = array_filter([
                substr($national, 0, 3),
                substr($national, 3, 4),
                substr($national, 7, 4),
                substr($national, 11),
            ]);

            return '+62 '.implode('-', $parts);
        };
        $statusClass = fn ($status) => match ($status) {
            'Risiko Tinggi' => 'sg-status-red',
            'Perlu Pantau' => 'sg-status-orange',
            'Stabil' => 'sg-status-green',
            default => 'sg-status-gray',
        };
        $accountStatusClass = fn ($status) => match ($status) {
            'Aktif' => 'sg-status-green',
            'Diblokir' => 'sg-status-red',
            default => 'sg-status-gray',
        };
        $isSuperAdmin = auth()->user()?->role === 'super_admin';
    @endphp

    <div id="parentsSkeleton" class="row g-3 mb-3">
        @for ($i = 0; $i < 4; $i++)
            <div class="col-md-6 col-xl-3"><div class="sg-skeleton"></div></div>
        @endfor
    </div>

    <div id="parentsError" class="alert alert-danger rounded-4 border-0 d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-center gap-2">
            <strong>Data orang tua gagal dimuat</strong>
            <button class="btn btn-sm btn-danger rounded-pill" onclick="window.location.reload()">Coba Lagi</button>
        </div>
    </div>

    <div id="parentsContent" class="d-none">
        <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
            <div>
                <h1 class="sg-page-title">Orang Tua</h1>
                <p class="sg-page-subtitle">Monitoring akun keluarga yang terhubung dengan data anak dan konsultasi.</p>
            </div>
            <a class="btn btn-primary rounded-4 px-3" href="{{ route('admin.parents.create') }}">
                <i class="bi bi-plus-lg me-1"></i>Tambah Orang Tua
            </a>
        </div>

        <section class="row g-2 mb-3">
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Total Orang Tua</div>
                    <div class="fs-4 fw-semibold">{{ number_format($summary['totalParents']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Konsultasi Aktif</div>
                    <div class="fs-4 fw-semibold text-success">{{ number_format($summary['activeConsultations']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Keluarga Risiko Tinggi</div>
                    <div class="fs-4 fw-semibold text-danger">{{ number_format($summary['highRiskFamilies']) }}</div>
                </div>
            </div>
            <div class="col-sm-6 col-xl-3">
                <div class="sg-card sg-mini-metric">
                    <div class="small text-muted">Belum Ukur</div>
                    <div class="fs-4 fw-semibold text-warning">{{ number_format($summary['unmeasuredFamilies']) }}</div>
                </div>
            </div>
        </section>

        <form class="sg-card p-3 mb-3" method="get">
            <div class="row g-3 align-items-end">
                <div class="col-lg-5">
                    <label class="form-label small fw-semibold text-muted">Search realtime</label>
                    <div class="sg-search d-flex align-items-center gap-2 w-100" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input id="parentSearch" name="q" value="{{ $q }}" placeholder="Cari nama, email, nomor HP, atau nama anak...">
                    </div>
                </div>
                <div class="col-lg-3">
                    <label class="form-label small fw-semibold text-muted">Sorting</label>
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
                <div class="small fw-semibold text-muted mb-2">Filter keluarga</div>
                <div class="sg-filter-scroll">
                    @foreach ($filters as $item)
                        <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">
                            {{ $item }}
                        </button>
                    @endforeach
                </div>
            </div>
        </form>

        <section class="sg-card p-3">
            <div class="d-none d-lg-grid px-2 pb-2 text-muted small fw-semibold" style="grid-template-columns:minmax(220px,1.4fr) minmax(120px,.7fr) minmax(130px,.8fr) minmax(130px,.8fr) minmax(120px,.7fr) 44px;gap:12px">
                <div>Keluarga</div>
                <div>Anak</div>
                <div>Status Keluarga</div>
                <div>Konsultasi</div>
                <div>Terakhir Aktif</div>
                <div></div>
            </div>

            <div class="vstack gap-2">
                @forelse ($rows as $row)
                    @php($parent = $row['parent'])
                    <article class="sg-family-row">
                        <div class="d-flex align-items-center gap-2 min-w-0">
                            <span class="sg-letter-avatar">{{ strtoupper(substr($parent->name ?? 'O', 0, 1)) }}</span>
                            <div class="min-w-0">
                                <div class="fw-semibold text-truncate">{{ $parent->name ?? 'Orang Tua' }}</div>
                                <div class="small text-muted text-truncate">{{ $formatPhone($parent->phone) }}</div>
                                <div class="small text-muted text-truncate">{{ $parent->email ?: 'Email belum diisi' }}</div>
                                <span class="sg-status {{ $accountStatusClass($row['account_status']) }} mt-1">{{ $row['account_status'] }}</span>
                            </div>
                        </div>

                        <div>
                            <span class="sg-family-label">Jumlah Anak</span>
                            <div class="fw-semibold">{{ $parent->children_count }} anak</div>
                            <div class="small text-muted text-truncate">
                                {{ $row['children']->pluck('child.nama')->filter()->take(2)->join(', ') ?: 'Belum ada anak' }}
                            </div>
                        </div>

                        <div>
                            <span class="sg-family-label">Status Keluarga</span>
                            <span class="sg-status {{ $statusClass($row['family_status']) }}">{{ $row['family_status'] }}</span>
                        </div>

                        <div>
                            <span class="sg-family-label">Konsultasi</span>
                            <div class="fw-semibold">{{ $row['consultations_count'] }} konsultasi</div>
                            <div class="small text-muted">{{ $row['active_consultations_count'] }} aktif</div>
                        </div>

                        <div>
                            <span class="sg-family-label">Terakhir Aktif</span>
                            <div class="small fw-semibold">{{ $row['last_active']?->format('d M Y') ?? '-' }}</div>
                            <div class="small text-muted">{{ $row['last_active']?->diffForHumans() ?? '-' }}</div>
                        </div>

                        <div class="dropdown sg-family-actions text-end">
                            <button class="btn btn-sm btn-outline-primary rounded-4" data-bs-toggle="dropdown" type="button">
                                <i class="bi bi-three-dots-vertical"></i>
                            </button>
                            <div class="dropdown-menu dropdown-menu-end p-2">
                                <a class="dropdown-item rounded-3" href="{{ route('admin.parents.show', $parent) }}">Lihat Detail</a>
                                <a class="dropdown-item rounded-3" href="{{ route('admin.parents.show', $parent) }}#edit">Edit Data</a>
                                <a class="dropdown-item rounded-3" href="{{ $parent->children->first() ? route('admin.children.show', $parent->children->first()) : route('admin.children.index', ['q' => $parent->name]) }}">Lihat Anak</a>
                                <a class="dropdown-item rounded-3" href="{{ route('admin.consultations.parent', $parent) }}">Lihat Konsultasi</a>
                                @if ($isSuperAdmin)
                                    <form method="post" action="{{ route('admin.parents.deactivate', $parent) }}" data-confirm="Nonaktifkan akun {{ $parent->name }}?">
                                        @csrf
                                        @method('PATCH')
                                        <button class="dropdown-item rounded-3 text-warning" type="submit">Nonaktifkan Akun</button>
                                    </form>
                                    <form method="post" action="{{ route('admin.parents.destroy', $parent) }}" data-confirm="Hapus akun {{ $parent->name }}? Data anak/konsultasi terkait tidak ikut dihapus.">
                                        @csrf
                                        @method('DELETE')
                                        <button class="dropdown-item rounded-3 text-danger" type="submit">Hapus</button>
                                    </form>
                                @endif
                            </div>
                        </div>
                    </article>
                @empty
                    <div class="text-center text-muted py-5">Belum ada akun keluarga.</div>
                @endforelse
            </div>

            @if ($rows->hasPages())
                <div class="pt-3 mt-3 border-top d-flex flex-wrap justify-content-between align-items-center gap-2">
                    <div class="small text-muted">Menampilkan {{ $rows->firstItem() }}-{{ $rows->lastItem() }} dari {{ $rows->total() }} data</div>
                    {{ $rows->links('pagination::bootstrap-5') }}
                </div>
            @endif
        </section>
    </div>

    <x-slot:scripts>
        <script>
            try {
                document.getElementById('parentsSkeleton')?.classList.add('d-none');
                document.getElementById('parentsContent')?.classList.remove('d-none');

                let timer;
                document.getElementById('parentSearch')?.addEventListener('input', (event) => {
                    clearTimeout(timer);
                    timer = setTimeout(() => event.target.form.submit(), 500);
                });
            } catch (error) {
                document.getElementById('parentsSkeleton')?.classList.add('d-none');
                document.getElementById('parentsError')?.classList.remove('d-none');
            }
        </script>
    </x-slot:scripts>
</x-admin-layout>
