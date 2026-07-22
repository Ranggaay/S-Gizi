<x-admin-layout :title="'Pengaturan'">
    @php
        $roleLabel = match ($admin?->role) {
            'super_admin' => 'Super Admin',
            'admin_operasional' => 'Admin Operasional',
            default => 'Admin',
        };
        $roleBadge = $admin?->role === 'super_admin' ? 'sg-status-green' : 'sg-status-blue';
        $initial = collect(explode(' ', trim((string) ($admin?->name ?? 'Admin S-Gizi'))))->filter()->take(2)->map(fn ($part) => mb_substr($part, 0, 1))->implode('') ?: 'AD';
        $formatDateTime = fn ($date) => $date ? $date->copy()->timezone('Asia/Bangkok')->locale('id')->translatedFormat('d M Y H:i') : '-';
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
        <div>
            <h1 class="sg-page-title">Pengaturan Sistem</h1>
            <p class="sg-page-subtitle">Kelola profil, keamanan, akun admin, dan aktivitas login website admin S-Gizi.</p>
        </div>
        @if ($isSuperAdmin)
            <button class="btn btn-sm btn-primary rounded-pill px-3" data-bs-toggle="modal" data-bs-target="#addAdminModal">
                <i class="bi bi-plus-lg me-1"></i>Tambah Admin
            </button>
        @endif
    </div>

    <div class="sg-settings-grid">
        <section class="sg-card p-3">
            <div class="d-flex align-items-center gap-3">
                <span class="sg-settings-avatar">{{ $initial }}</span>
                <div class="min-w-0">
                    <h5 class="fw-semibold mb-1">{{ $admin?->name ?? 'Admin S-Gizi' }}</h5>
                    <div class="d-flex flex-wrap gap-1">
                        <span class="sg-status {{ $roleBadge }}">{{ $roleLabel }}</span>
                        <span class="sg-status sg-status-green">{{ $admin?->account_status ?? 'Aktif' }}</span>
                    </div>
                </div>
            </div>
            <div class="sg-settings-lines mt-3">
                <div><span>Email</span><strong>{{ $admin?->email ?? 'admin@sgizi.local' }}</strong></div>
                <div><span>Nomor Telepon</span><strong>{{ $admin?->phone ?? '-' }}</strong></div>
                <div><span>Last Login</span><strong>{{ $formatDateTime($admin?->last_login_at) }}</strong></div>
                <div><span>Role</span><strong>{{ $roleLabel }}</strong></div>
            </div>
            <div class="d-flex flex-wrap gap-2 mt-3">
                <button class="btn btn-sm btn-outline-primary rounded-pill" data-bs-toggle="modal" data-bs-target="#editProfileModal" type="button"><i class="bi bi-pencil me-1"></i>Edit Profil</button>
                <button class="btn btn-sm btn-outline-secondary rounded-pill" data-bs-toggle="modal" data-bs-target="#changePasswordModal" type="button"><i class="bi bi-key me-1"></i>Ubah Password</button>
            </div>
        </section>

        <section class="sg-card p-3">
            <h6 class="fw-semibold mb-3"><i class="bi bi-shield-lock me-1 text-primary"></i>Keamanan</h6>
            <div class="row g-2">
                <div class="col-sm-6"><div class="sg-setting-tile"><span>Session Timeout</span><strong>30 menit idle</strong></div></div>
                <div class="col-sm-6"><div class="sg-setting-tile"><span>Login Attempt</span><strong>5x / lock 5 menit</strong></div></div>
                <div class="col-sm-6"><div class="sg-setting-tile"><span>IP Login</span><strong>{{ $admin?->last_login_ip ?? '-' }}</strong></div></div>
                <div class="col-sm-6"><div class="sg-setting-tile"><span>Password</span><strong>Bcrypt aktif</strong></div></div>
            </div>
            <div class="d-flex flex-wrap gap-2 mt-3">
                <button class="btn btn-sm btn-outline-primary rounded-pill" data-bs-toggle="modal" data-bs-target="#changePasswordModal" type="button">Ubah Password</button>
                <button class="btn btn-sm btn-outline-danger rounded-pill" data-bs-toggle="modal" data-bs-target="#logoutDevicesModal">Logout Semua Perangkat</button>
            </div>
        </section>

        <section class="sg-card p-3 sg-admin-section">
            <div class="d-flex justify-content-between align-items-center gap-2 mb-3">
                <h6 class="fw-semibold mb-0"><i class="bi bi-people me-1 text-primary"></i>Manajemen Admin</h6>
                <span class="sg-status sg-status-blue">{{ $admins->count() }} admin</span>
            </div>
            <div class="vstack gap-2">
                @forelse ($admins as $row)
                    @php
                        $rowRole = $row->role === 'super_admin' ? 'Super Admin' : 'Admin Operasional';
                        $rowInitial = collect(explode(' ', trim((string) $row->name)))->filter()->take(2)->map(fn ($part) => mb_substr($part, 0, 1))->implode('') ?: 'AD';
                    @endphp
                    <div class="sg-admin-row">
                        <span class="sg-letter-avatar">{{ $rowInitial }}</span>
                        <div class="min-w-0">
                            <div class="fw-semibold text-truncate">{{ $row->name }}</div>
                            <div class="small text-muted text-truncate">{{ $row->email }}</div>
                        </div>
                        <span class="sg-status {{ $row->role === 'super_admin' ? 'sg-status-green' : 'sg-status-blue' }}">{{ $rowRole }}</span>
                        <span class="sg-status {{ ($row->account_status ?? 'Aktif') === 'Aktif' ? 'sg-status-green' : 'sg-status-red' }}">{{ $row->account_status ?? 'Aktif' }}</span>
                        <div class="small text-muted">{{ $formatDateTime($row->last_login_at) }}</div>
                        <div class="d-flex flex-wrap gap-1 sg-admin-actions">
                            @if ($isSuperAdmin && $row->id !== $admin?->id)
                                <button class="btn btn-sm btn-outline-secondary rounded-pill" data-bs-toggle="modal" data-bs-target="#profileAdminModal{{ $row->id }}" type="button">
                                    <i class="bi bi-eye"></i> Profil
                                </button>
                                <button class="btn btn-sm btn-outline-primary rounded-pill" data-bs-toggle="modal" data-bs-target="#editAdminModal{{ $row->id }}" type="button">
                                    <i class="bi bi-pencil"></i> Edit
                                </button>
                                <form method="post" action="{{ route('admin.settings.admin.deactivate', $row) }}" data-confirm="Nonaktifkan admin ini?">
                                    @csrf @method('PATCH')
                                    <button class="btn btn-sm btn-outline-warning rounded-pill">Nonaktifkan</button>
                                </form>
                            @else
                                <span class="small text-muted">Akun aktif saat ini</span>
                            @endif
                        </div>
                    </div>
                @empty
                    <div class="text-center text-muted py-4">Tetap aman dengan menambahkan admin operasional.</div>
                @endforelse
            </div>
        </section>

        <section class="sg-card p-3">
            <h6 class="fw-semibold mb-3"><i class="bi bi-clock-history me-1 text-primary"></i>Aktivitas Admin Terakhir</h6>
            <div class="vstack gap-2">
                @foreach ($activities as $activity)
                    <div class="sg-activity-line">
                        <span></span>
                        <div>
                            <div class="fw-semibold">{{ $activity['admin'] }}</div>
                            <div class="small text-muted">{{ $activity['action'] }}</div>
                        </div>
                        <div class="small text-muted ms-auto">{{ $formatDateTime($activity['time']) }}</div>
                    </div>
                @endforeach
            </div>
        </section>
    </div>

    <div class="modal fade" id="editProfileModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <form class="modal-content rounded-4 border-0" method="post" action="{{ route('admin.settings.profile.update') }}" data-confirm="Simpan perubahan profil admin?">
                @csrf
                @method('PATCH')
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-semibold">Edit Profil Admin</h5>
                    <button class="btn-close" data-bs-dismiss="modal" type="button" aria-label="Close"></button>
                </div>
                <div class="modal-body row g-2">
                    <div class="col-12">
                        <label class="form-label small fw-semibold text-muted">Nama Lengkap</label>
                        <input class="form-control" name="name" value="{{ $admin?->name }}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Email</label>
                        <input class="form-control" type="email" name="email" value="{{ $admin?->email }}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Nomor Telepon</label>
                        <input class="form-control" name="phone" value="{{ $admin?->phone }}" required>
                    </div>
                    <div class="col-12">
                        <label class="form-label small fw-semibold text-muted">Role</label>
                        <input class="form-control" value="{{ $roleLabel }}" disabled>
                        <div class="small text-muted mt-1">Role akun sendiri diubah melalui Manajemen Admin oleh Super Admin lain.</div>
                    </div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button class="btn btn-outline-secondary rounded-pill" data-bs-dismiss="modal" type="button">Batal</button>
                    <button class="btn btn-primary rounded-pill" type="submit">Simpan Profil</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal fade" id="changePasswordModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <form class="modal-content rounded-4 border-0" method="post" action="{{ route('admin.settings.password.update') }}" data-confirm="Ubah password akun admin ini?">
                @csrf
                @method('PATCH')
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-semibold">Ubah Password</h5>
                    <button class="btn-close" data-bs-dismiss="modal" type="button" aria-label="Close"></button>
                </div>
                <div class="modal-body row g-2">
                    <div class="col-12">
                        <label class="form-label small fw-semibold text-muted">Password Lama</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="current_password" autocomplete="current-password" required>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password lama">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Password Baru</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="password" autocomplete="new-password" minlength="8" required>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password baru">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Konfirmasi Password</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="password_confirmation" autocomplete="new-password" minlength="8" required>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="col-12 small text-muted">Gunakan minimal 8 karakter. Setelah password diubah, gunakan password baru untuk login berikutnya.</div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button class="btn btn-outline-secondary rounded-pill" data-bs-dismiss="modal" type="button">Batal</button>
                    <button class="btn btn-primary rounded-pill" type="submit">Simpan Password</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal fade" id="addAdminModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <form class="modal-content rounded-4 border-0" method="post" action="{{ route('admin.settings.admin.store') }}">
                @csrf
                <div class="modal-header border-0 pb-0">
                    <h5 class="modal-title fw-semibold">Tambah Admin</h5>
                    <button class="btn-close" data-bs-dismiss="modal" type="button" aria-label="Close"></button>
                </div>
                <div class="modal-body row g-2">
                    <div class="col-12"><label class="form-label small fw-semibold text-muted">Nama Lengkap</label><input class="form-control" name="name" required></div>
                    <div class="col-md-6"><label class="form-label small fw-semibold text-muted">Email</label><input class="form-control" type="email" name="email" required></div>
                    <div class="col-md-6"><label class="form-label small fw-semibold text-muted">Nomor Telepon</label><input class="form-control" name="phone" required></div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Password</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="password" autocomplete="new-password" required>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Konfirmasi</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="password_confirmation" autocomplete="new-password" required>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="col-md-6"><label class="form-label small fw-semibold text-muted">Role</label><select class="form-select" name="role"><option value="admin_operasional">Admin Operasional</option><option value="super_admin">Super Admin</option></select></div>
                    <div class="col-md-6"><label class="form-label small fw-semibold text-muted">Status</label><select class="form-select" name="account_status"><option>Aktif</option><option>Nonaktif</option></select></div>
                </div>
                <div class="modal-footer border-0 pt-0">
                    <button class="btn btn-outline-secondary rounded-pill" data-bs-dismiss="modal" type="button">Batal</button>
                    <button class="btn btn-primary rounded-pill" type="submit">Simpan Admin</button>
                </div>
            </form>
        </div>
    </div>

    @foreach ($admins as $row)
        @continue($row->id === $admin?->id)
        @php
            $rowRole = $row->role === 'super_admin' ? 'Super Admin' : 'Admin Operasional';
            $rowInitial = collect(explode(' ', trim((string) $row->name)))->filter()->take(2)->map(fn ($part) => mb_substr($part, 0, 1))->implode('') ?: 'AD';
        @endphp
        <div class="modal fade" id="profileAdminModal{{ $row->id }}" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content rounded-4 border-0">
                    <div class="modal-header border-0 pb-0">
                        <h5 class="modal-title fw-semibold">Profil Admin</h5>
                        <button class="btn-close" data-bs-dismiss="modal" type="button" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="d-flex align-items-center gap-3 mb-3">
                            <span class="sg-settings-avatar">{{ $rowInitial }}</span>
                            <div>
                                <h5 class="fw-semibold mb-1">{{ $row->name }}</h5>
                                <div class="d-flex flex-wrap gap-1">
                                    <span class="sg-status {{ $row->role === 'super_admin' ? 'sg-status-green' : 'sg-status-blue' }}">{{ $rowRole }}</span>
                                    <span class="sg-status {{ ($row->account_status ?? 'Aktif') === 'Aktif' ? 'sg-status-green' : 'sg-status-red' }}">{{ $row->account_status ?? 'Aktif' }}</span>
                                </div>
                            </div>
                        </div>
                        <div class="sg-settings-lines">
                            <div><span>Email</span><strong>{{ $row->email }}</strong></div>
                            <div><span>Nomor Telepon</span><strong>{{ $row->phone }}</strong></div>
                            <div><span>Role</span><strong>{{ $rowRole }}</strong></div>
                            <div><span>Last Login</span><strong>{{ $formatDateTime($row->last_login_at) }}</strong></div>
                            <div><span>Dibuat</span><strong>{{ $formatDateTime($row->created_at) }}</strong></div>
                        </div>
                    </div>
                    <div class="modal-footer border-0 pt-0">
                        <button class="btn btn-outline-secondary rounded-pill" data-bs-dismiss="modal" type="button">Tutup</button>
                        <button class="btn btn-primary rounded-pill" data-bs-target="#editAdminModal{{ $row->id }}" data-bs-toggle="modal" type="button">Edit Admin</button>
                    </div>
                </div>
            </div>
        </div>

        <div class="modal fade" id="editAdminModal{{ $row->id }}" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <form class="modal-content rounded-4 border-0" method="post" action="{{ route('admin.settings.admin.update', $row) }}" data-confirm="Simpan perubahan admin {{ $row->name }}?">
                    @csrf
                    @method('PATCH')
                    <div class="modal-header border-0 pb-0">
                        <h5 class="modal-title fw-semibold">Edit Admin</h5>
                        <button class="btn-close" data-bs-dismiss="modal" type="button" aria-label="Close"></button>
                    </div>
                    <div class="modal-body row g-2">
                        <div class="col-12"><label class="form-label small fw-semibold text-muted">Nama Lengkap</label><input class="form-control" name="name" value="{{ $row->name }}" required></div>
                        <div class="col-md-6"><label class="form-label small fw-semibold text-muted">Email</label><input class="form-control" type="email" name="email" value="{{ $row->email }}" required></div>
                        <div class="col-md-6"><label class="form-label small fw-semibold text-muted">Nomor Telepon</label><input class="form-control" name="phone" value="{{ $row->phone }}" required></div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold text-muted">Role</label>
                            <select class="form-select" name="role" required>
                                <option value="admin_operasional" @selected($row->role === 'admin_operasional')>Admin Operasional</option>
                                <option value="super_admin" @selected($row->role === 'super_admin')>Super Admin</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold text-muted">Status</label>
                            <select class="form-select" name="account_status" required>
                                <option @selected(($row->account_status ?? 'Aktif') === 'Aktif')>Aktif</option>
                                <option @selected(($row->account_status ?? 'Aktif') === 'Nonaktif')>Nonaktif</option>
                            </select>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold text-muted">Password Baru</label>
                            <div class="input-group">
                                <input class="form-control" type="password" name="password" autocomplete="new-password">
                                <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password baru">
                                    <i class="bi bi-eye"></i>
                                </button>
                            </div>
                            <div class="small text-muted mt-1">Kosongkan jika tidak diganti.</div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label small fw-semibold text-muted">Konfirmasi Password</label>
                            <div class="input-group">
                                <input class="form-control" type="password" name="password_confirmation" autocomplete="new-password">
                                <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
                                    <i class="bi bi-eye"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer border-0 pt-0">
                        <button class="btn btn-outline-secondary rounded-pill" data-bs-dismiss="modal" type="button">Batal</button>
                        <button class="btn btn-primary rounded-pill" type="submit">Simpan Perubahan</button>
                    </div>
                </form>
            </div>
        </div>
    @endforeach

    @foreach ([['logoutDevicesModal', 'Logout semua perangkat?', 'Sesi aktif admin akan diminta login ulang.']] as [$id, $title, $body])
        <div class="modal fade" id="{{ $id }}" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-dialog-centered">
                <div class="modal-content rounded-4 border-0">
                    <div class="modal-header border-0"><h5 class="modal-title fw-semibold">{{ $title }}</h5><button class="btn-close" data-bs-dismiss="modal" type="button"></button></div>
                    <div class="modal-body text-muted">{{ $body }}</div>
                    <div class="modal-footer border-0"><button class="btn btn-outline-secondary rounded-pill" data-bs-dismiss="modal">Batal</button><button class="btn btn-primary rounded-pill" data-bs-dismiss="modal">Konfirmasi</button></div>
                </div>
            </div>
        </div>
    @endforeach

    <x-slot:styles>
        <style>
            .sg-settings-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; align-items: start; }
            .sg-settings-avatar { width: 58px; height: 58px; border-radius: 18px; display: grid; place-items: center; background: linear-gradient(135deg, #4B8E96, #77C6AC); color: #fff; font-size: 22px; font-weight: 800; }
            .sg-settings-lines { display: grid; gap: 8px; }
            .sg-settings-lines > div { display: flex; justify-content: space-between; gap: 12px; padding: 9px 0; border-bottom: 1px solid #EDF3F3; }
            .sg-settings-lines > div:last-child { border-bottom: 0; }
            .sg-settings-lines span, .sg-setting-tile span { color: var(--sgizi-muted); font-size: 12px; font-weight: 650; }
            .sg-settings-lines strong, .sg-setting-tile strong { font-size: 13px; text-align: right; }
            .sg-setting-tile { border: 1px solid rgba(75,142,150,.14); border-radius: 14px; padding: 10px; background: #FAFDFD; display: grid; gap: 4px; min-height: 66px; }
            .sg-toggle-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; border: 1px solid rgba(75,142,150,.13); border-radius: 14px; padding: 9px 10px; background: #fff; font-size: 13px; font-weight: 650; }
            .sg-switch { width: 42px; height: 22px; margin: 0; }
            .sg-readonly-setting { background: #F7FBFB; }
            .sg-backup-actions { display: flex; flex-wrap: wrap; gap: 8px; }
            .sg-admin-section { grid-column: 1 / -1; }
            .sg-admin-row { display: grid; grid-template-columns: 38px minmax(180px, 1fr) 140px 100px 120px minmax(230px, auto); align-items: center; gap: 10px; padding: 9px; border: 1px solid rgba(75,142,150,.13); border-radius: 16px; background: #fff; }
            .sg-admin-actions { justify-content: flex-end; }
            .sg-activity-line { display: flex; align-items: flex-start; gap: 10px; padding: 8px 0; border-bottom: 1px solid #EDF3F3; }
            .sg-activity-line:last-child { border-bottom: 0; }
            .sg-activity-line > span { width: 10px; height: 10px; border-radius: 999px; background: var(--sgizi); margin-top: 6px; box-shadow: 0 0 0 4px #E5F4F6; flex: 0 0 auto; }
            @media (max-width: 1199.98px) { .sg-admin-row { grid-template-columns: 38px minmax(0, 1fr) repeat(2, auto); } .sg-admin-row > .small, .sg-admin-actions { grid-column: 2 / -1; justify-content: flex-start; } }
            @media (max-width: 991.98px) { .sg-settings-grid { grid-template-columns: minmax(0, 1fr); } }
            @media (max-width: 767.98px) { .sg-admin-row { grid-template-columns: 38px minmax(0, 1fr); } .sg-admin-row > *:not(.sg-letter-avatar):not(.min-w-0) { grid-column: 2; justify-self: start; } }
        </style>
    </x-slot:styles>
</x-admin-layout>
