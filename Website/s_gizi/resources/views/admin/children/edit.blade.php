<x-admin-layout :title="'Edit Data Anak'">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
        <div>
            <h1 class="sg-page-title">Edit Data Anak</h1>
            <p class="sg-page-subtitle">Perbarui biodata anak dan hubungan orang tua untuk monitoring WHO.</p>
        </div>
        <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.children.index') }}">Kembali</a>
    </div>

    <section class="sg-card p-3 p-lg-4">
        <form class="row g-3" method="post" action="{{ route('admin.children.update', $child) }}" data-confirm="Simpan perubahan data anak ini?">
            @csrf
            @method('PUT')
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Nama Anak</label>
                <input class="form-control" name="nama" value="{{ old('nama', $child->nama) }}" required>
            </div>
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Orang Tua</label>
                <select class="form-select" name="user_id">
                    <option value="">Belum terhubung</option>
                    @foreach ($parents as $parent)
                        <option value="{{ $parent->id }}" @selected((string) old('user_id', $child->user_id) === (string) $parent->id)>
                            {{ $parent->name }}{{ $parent->phone ? ' - '.$parent->phone : '' }}
                        </option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Tanggal Lahir</label>
                <input type="date" class="form-control" name="tanggal_lahir" value="{{ old('tanggal_lahir', $child->tanggal_lahir?->format('Y-m-d')) }}" required>
            </div>
            <div class="col-md-6">
                <label class="form-label small fw-semibold text-muted">Jenis Kelamin</label>
                <select class="form-select" name="jenis_kelamin" required>
                    <option value="L" @selected(old('jenis_kelamin', $child->jenis_kelamin) === 'L')>Laki-laki</option>
                    <option value="P" @selected(old('jenis_kelamin', $child->jenis_kelamin) === 'P')>Perempuan</option>
                </select>
            </div>
            <div class="col-12 d-flex flex-wrap gap-2">
                <button class="btn btn-primary rounded-4 px-4" type="submit"><i class="bi bi-check2-circle me-1"></i>Simpan Perubahan</button>
                <a class="btn btn-outline-primary rounded-4 px-4" href="{{ route('admin.children.show', $child) }}">Lihat Detail</a>
                <a class="btn btn-outline-secondary rounded-4 px-4" href="{{ route('admin.children.index') }}">Batal</a>
            </div>
        </form>
    </section>
</x-admin-layout>
