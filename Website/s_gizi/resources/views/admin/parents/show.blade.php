<x-admin-layout :title="'Detail Orang Tua'">
    @php
        $formatPhone = function (?string $phone) {
            $digits = preg_replace('/\D+/', '', (string) $phone);
            if ($digits === '') return '-';
            if (str_starts_with($digits, '0')) $digits = '62'.substr($digits, 1);
            if (!str_starts_with($digits, '62')) $digits = '62'.$digits;
            $national = substr($digits, 2);
            return '+62 '.implode('-', array_filter([substr($national, 0, 3), substr($national, 3, 4), substr($national, 7, 4), substr($national, 11)]));
        };
        $formatAge = function ($child, $measurement) {
            $months = $measurement?->umur_bulan;
            if ($months === null && $child?->tanggal_lahir) $months = (int) $child->tanggal_lahir->diffInMonths(now());
            if ($months === null) return '-';
            $months = (int) round((float) $months);
            $years = intdiv($months, 12);
            $remaining = $months % 12;
            return $years > 0 ? "{$years} Tahun {$remaining} Bulan" : "{$months} Bulan";
        };
        $accountStatus = $parent->account_status ?: 'Aktif';
        $accountStatusClass = match ($accountStatus) {
            'Aktif' => 'sg-status-green',
            'Diblokir' => 'sg-status-red',
            default => 'sg-status-gray',
        };
        $isSuperAdmin = auth()->user()?->role === 'super_admin';
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-3">
        <div>
            <h1 class="sg-page-title">Detail Orang Tua</h1>
            <p class="sg-page-subtitle">Biodata keluarga, data anak, aktivitas pengukuran, dan konsultasi.</p>
        </div>
        <a class="btn btn-outline-primary rounded-4 px-3" href="{{ route('admin.parents') }}"><i class="bi bi-arrow-left me-1"></i>Kembali</a>
    </div>

    <div class="row g-3">
        <div class="col-xl-4">
            <div class="sg-card p-3 mb-3">
                <div class="d-flex align-items-center gap-3 mb-3">
                    <span class="sg-letter-avatar" style="width:56px;height:56px;border-radius:18px;font-size:22px">{{ strtoupper(substr($parent->name ?? 'O', 0, 1)) }}</span>
                    <div>
                        <h5 class="fw-semibold mb-1">{{ $parent->name ?? 'Orang Tua' }}</h5>
                        <div class="text-muted">{{ $formatPhone($parent->phone) }}</div>
                        <div class="small text-muted">{{ $parent->email ?: 'Email belum diisi' }}</div>
                    </div>
                </div>
                <div class="vstack gap-2">
                    <div class="d-flex justify-content-between"><span class="text-muted">Tanggal Daftar</span><strong>{{ $parent->created_at?->format('d M Y') ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Email</span><strong class="text-end">{{ $parent->email ?: '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Status Akun</span><span class="sg-status {{ $accountStatusClass }}">{{ $accountStatus }}</span></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Jumlah Anak</span><strong>{{ $parent->children->count() }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Konsultasi</span><strong>{{ $consultationsCount }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Terakhir Aktif</span><strong>{{ $lastActive?->format('d M Y H:i') ?? '-' }}</strong></div>
                    <div class="d-flex justify-content-between"><span class="text-muted">Pengukuran Terakhir</span><strong>{{ $lastMeasurement?->tanggal_ukur?->format('d M Y') ?? '-' }}</strong></div>
                </div>
            </div>

            <div id="edit" class="sg-card p-3">
                <h6 class="fw-semibold mb-3">Edit Data</h6>
                <form class="row g-2" method="post" action="{{ route('admin.parents.update', $parent) }}" data-confirm="Simpan perubahan data orang tua ini?">
                    @csrf
                    @method('PATCH')
                    <div class="col-12">
                        <label class="form-label small text-muted">Nama</label>
                        <input class="form-control @error('name') is-invalid @enderror" name="name" value="{{ old('name', $parent->name) }}" required>
                    </div>
                    <div class="col-12">
                        <label class="form-label small text-muted">Email</label>
                        <input class="form-control @error('email') is-invalid @enderror" type="email" name="email" value="{{ old('email', $parent->email) }}" placeholder="nama@email.com">
                    </div>
                    <div class="col-12">
                        <label class="form-label small text-muted">Nomor HP</label>
                        <input class="form-control @error('phone') is-invalid @enderror" name="phone" value="{{ old('phone', $parent->phone) }}" required>
                    </div>
                    <div class="col-12">
                        <label class="form-label small text-muted">Status Akun</label>
                        <select class="form-select @error('account_status') is-invalid @enderror" name="account_status">
                            @foreach (['Aktif', 'Nonaktif', 'Diblokir'] as $statusOption)
                                <option value="{{ $statusOption }}" @selected(old('account_status', $accountStatus) === $statusOption)>{{ $statusOption }}</option>
                            @endforeach
                        </select>
                    </div>
                    @if ($isSuperAdmin)
                        <div class="col-12 pt-2 mt-1 border-top">
                            <div class="fw-semibold small mb-1">Reset Password</div>
                            <div class="small text-muted mb-2">Kosongkan jika password orang tua tidak ingin diubah.</div>
                        </div>
                        <div class="col-12">
                            <label class="form-label small text-muted">Password Baru</label>
                            <div class="input-group">
                                <input class="form-control @error('password') is-invalid @enderror" type="password" name="password" autocomplete="new-password" minlength="8" placeholder="Minimal 8 karakter">
                                <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password baru">
                                    <i class="bi bi-eye"></i>
                                </button>
                            </div>
                        </div>
                        <div class="col-12">
                            <label class="form-label small text-muted">Konfirmasi Password</label>
                            <div class="input-group">
                                <input class="form-control @error('password_confirmation') is-invalid @enderror" type="password" name="password_confirmation" autocomplete="new-password" minlength="8" placeholder="Ulangi password baru">
                                <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
                                    <i class="bi bi-eye"></i>
                                </button>
                            </div>
                        </div>
                    @endif
                    <div class="col-12"><button class="btn btn-primary rounded-4 w-100" type="submit">Simpan Perubahan</button></div>
                </form>
            </div>
        </div>

        <div class="col-xl-8">
            <div class="row g-3">
                @forelse ($parent->children as $child)
                    @php
                        $latest = $child->measurements->first();
                        $status = \App\Helpers\NutritionStatusHelper::getStatus($latest);
                    @endphp
                    <div class="col-lg-6">
                        <div class="sg-card p-3 h-100">
                            <div class="d-flex justify-content-between align-items-start gap-2 mb-3">
                                <div>
                                    <h6 class="fw-semibold mb-1">{{ $child->nama }}</h6>
                                    <div class="small text-muted">{{ $formatAge($child, $latest) }} - {{ $child->jenis_kelamin === 'P' ? 'Perempuan' : 'Laki-laki' }}</div>
                                </div>
                                <span class="sg-status {{ \App\Helpers\NutritionStatusHelper::badgeClass($status) }}">{{ $status }}</span>
                            </div>

                            <div class="row g-2 mb-3">
                                <div class="col-6"><div class="border rounded-4 p-2"><div class="small text-muted">BB</div><div class="fw-semibold">{{ $latest ? number_format((float) $latest->berat, 1) : '-' }} kg</div></div></div>
                                <div class="col-6"><div class="border rounded-4 p-2"><div class="small text-muted">TB</div><div class="fw-semibold">{{ $latest ? number_format((float) $latest->tinggi, 1) : '-' }} cm</div></div></div>
                            </div>

                            <div class="border rounded-4 px-3 py-2 mb-3">
                                @forelse ($child->measurements->take(4) as $measurement)
                                    @php($historyStatus = \App\Helpers\NutritionStatusHelper::getStatus($measurement))
                                    <div class="sg-history-line">
                                        <span>{{ $measurement->tanggal_ukur?->format('d M') ?? '-' }}</span>
                                        <span>{{ $historyStatus }}</span>
                                    </div>
                                @empty
                                    <div class="small text-muted py-2">Belum ada riwayat pengukuran.</div>
                                @endforelse
                            </div>

                            <div class="sg-action-grid">
                                <a class="btn btn-outline-primary rounded-pill" href="{{ route('admin.children.show', $child) }}">Detail</a>
                                <a class="btn btn-outline-primary rounded-pill" href="{{ route('admin.children.show', $child) }}#growthChart">Grafik</a>
                                <a class="btn btn-primary rounded-pill" href="{{ route('admin.measurements.index', ['q' => $child->nama]) }}">Riwayat</a>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="col-12"><div class="sg-card p-5 text-center text-muted">Belum ada data anak.</div></div>
                @endforelse
            </div>
        </div>
    </div>
</x-admin-layout>
