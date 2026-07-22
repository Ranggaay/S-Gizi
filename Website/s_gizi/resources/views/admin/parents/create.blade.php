<x-admin-layout :title="'Tambah Orang Tua'">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-3">
        <div>
            <h1 class="sg-page-title">Tambah Orang Tua</h1>
            <p class="sg-page-subtitle">Buat akun orang tua agar bisa login di aplikasi mobile dan terhubung dengan data anak.</p>
        </div>
        <a class="btn btn-outline-primary rounded-4 px-3" href="{{ route('admin.parents') }}">
            <i class="bi bi-arrow-left me-1"></i>Kembali
        </a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger rounded-4 border-0">
            <strong>Data belum bisa disimpan.</strong>
            <div class="small mt-1">{{ $errors->first() }}</div>
        </div>
    @endif

    <section class="sg-card p-3 p-lg-4">
        <form class="row g-3" method="post" action="{{ route('admin.parents.store') }}">
            @csrf

            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Nama lengkap</label>
                <input class="form-control @error('name') is-invalid @enderror" name="name" value="{{ old('name') }}" required>
            </div>

            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Nomor HP</label>
                <input class="form-control @error('phone') is-invalid @enderror" name="phone" value="{{ old('phone') }}" placeholder="08xxxxxxxxxx" required>
                <div class="small text-muted mt-1">Nomor ini digunakan untuk login aplikasi mobile.</div>
            </div>

            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Email</label>
                <input class="form-control @error('email') is-invalid @enderror" type="email" name="email" value="{{ old('email') }}" placeholder="nama@email.com">
            </div>

            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Sebagai</label>
                <select class="form-select @error('parent_gender') is-invalid @enderror" name="parent_gender" required>
                    <option value="">Pilih</option>
                    <option value="ayah" @selected(old('parent_gender') === 'ayah')>Ayah</option>
                    <option value="bunda" @selected(old('parent_gender') === 'bunda')>Bunda</option>
                </select>
            </div>

            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Password</label>
                <div class="input-group">
                    <input class="form-control @error('password') is-invalid @enderror" type="password" name="password" autocomplete="new-password" minlength="8" required>
                    <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
            </div>

            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Konfirmasi password</label>
                <div class="input-group">
                    <input class="form-control" type="password" name="password_confirmation" autocomplete="new-password" minlength="8" required>
                    <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
                        <i class="bi bi-eye"></i>
                    </button>
                </div>
            </div>

            <div class="col-md-4">
                <label class="form-label small fw-semibold text-muted">Status akun</label>
                <select class="form-select @error('account_status') is-invalid @enderror" name="account_status" required>
                    <option value="Aktif" @selected(old('account_status', 'Aktif') === 'Aktif')>Aktif</option>
                    <option value="Nonaktif" @selected(old('account_status') === 'Nonaktif')>Nonaktif</option>
                </select>
            </div>

            <div class="col-12 d-flex flex-wrap gap-2">
                <button class="btn btn-primary rounded-4 px-4" type="submit">
                    <i class="bi bi-plus-lg me-1"></i>Simpan Orang Tua
                </button>
                <a class="btn btn-outline-secondary rounded-4 px-4" href="{{ route('admin.parents') }}">Batal</a>
            </div>
        </form>
    </section>
</x-admin-layout>
