<x-admin-layout :title="'Tambah Data Anak'">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
        <div>
            <h1 class="sg-page-title">Tambah Data Anak</h1>
            <p class="sg-page-subtitle">Tambahkan anak dan hubungkan dengan akun orang tua untuk monitoring pertumbuhan.</p>
        </div>
        <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.children.index') }}">Kembali</a>
    </div>

    <section class="sg-card p-3 p-lg-4">
        <form class="row g-3" method="post" action="{{ route('admin.children.store') }}">
            @csrf
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Nama Anak</label>
                <input class="form-control" name="nama" value="{{ old('nama') }}" required>
            </div>
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Orang Tua</label>
                <select class="form-select" name="user_id">
                    <option value="">Belum terhubung</option>
                    @foreach ($parents as $parent)
                        <option value="{{ $parent->id }}" @selected((string) old('user_id') === (string) $parent->id)>
                            {{ $parent->name }}{{ $parent->phone ? ' - '.$parent->phone : '' }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Tanggal Lahir</label>
                <input type="date" class="form-control" name="tanggal_lahir" value="{{ old('tanggal_lahir') }}" required>
            </div>
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Jenis Kelamin</label>
                <select class="form-select" name="jenis_kelamin" required>
                    <option value="">Pilih jenis kelamin</option>
                    <option value="L" @selected(old('jenis_kelamin') === 'L')>Laki-laki</option>
                    <option value="P" @selected(old('jenis_kelamin') === 'P')>Perempuan</option>
                </select>
            </div>
            <div class="col-12 d-flex flex-wrap gap-2">
                <button class="btn btn-primary rounded-4 px-4" type="submit"><i class="bi bi-plus-lg me-1"></i>Simpan Anak</button>
                <a class="btn btn-outline-secondary rounded-4 px-4" href="{{ route('admin.children.index') }}">Batal</a>
            </div>
        </form>
    </section>
</x-admin-layout>
