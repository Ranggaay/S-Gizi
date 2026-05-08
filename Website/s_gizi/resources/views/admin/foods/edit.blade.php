<x-admin-layout :title="'Edit Makanan'">
    <div class="mb-3">
        <h4 class="mb-1">Edit Makanan</h4>
        <div class="text-muted">Perbarui data makanan.</div>
    </div>

    <div class="card shadow-sm">
        <div class="card-body">
            <form method="post" action="{{ route('admin.foods.update', $food) }}">
                @csrf
                @method('PUT')
                <div class="mb-3">
                    <label class="form-label">Nama</label>
                    <input class="form-control" name="nama" value="{{ old('nama', $food->nama) }}" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Kategori</label>
                    <input class="form-control" name="kategori" value="{{ old('kategori', $food->kategori) }}" required>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-primary">Simpan</button>
                    <a class="btn btn-outline-secondary" href="{{ route('admin.foods.index') }}">Kembali</a>
                </div>
            </form>
        </div>
    </div>
</x-admin-layout>

