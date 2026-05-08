<x-admin-layout :title="'Edit Data Anak'">
    <div class="mb-3">
        <h4 class="mb-1">Edit Data Anak</h4>
        <div class="text-muted">Perbarui data balita.</div>
    </div>

    <div class="card shadow-sm">
        <div class="card-body">
            <form method="post" action="{{ route('admin.children.update', $child) }}">
                @csrf
                @method('PUT')
                <div class="mb-3">
                    <label class="form-label">Nama</label>
                    <input class="form-control" name="nama" value="{{ old('nama', $child->nama) }}" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Tanggal Lahir</label>
                    <input type="date" class="form-control" name="tanggal_lahir" value="{{ old('tanggal_lahir', $child->tanggal_lahir?->format('Y-m-d')) }}" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Jenis Kelamin</label>
                    <select class="form-select" name="jenis_kelamin" required>
                        <option value="L" @selected(old('jenis_kelamin', $child->jenis_kelamin) === 'L')>Laki-laki (L)</option>
                        <option value="P" @selected(old('jenis_kelamin', $child->jenis_kelamin) === 'P')>Perempuan (P)</option>
                    </select>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-primary">Simpan</button>
                    <a class="btn btn-outline-secondary" href="{{ route('admin.children.index') }}">Kembali</a>
                </div>
            </form>
        </div>
    </div>
</x-admin-layout>

