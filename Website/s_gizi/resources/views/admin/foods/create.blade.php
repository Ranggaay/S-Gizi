<x-admin-layout :title="'Tambah Makanan'">
    <div class="mb-3">
        <h4 class="mb-1">Tambah Makanan</h4>
        <div class="text-muted">Isi nama dan kategori (protein, karbo, vitamin, dll).</div>
    </div>

    <div class="card shadow-sm">
        <div class="card-body">
            <form method="post" action="{{ route('admin.foods.store') }}">
                @csrf
                <div class="mb-3">
                    <label class="form-label">Nama</label>
                    <input class="form-control" name="nama" value="{{ old('nama') }}" required>
                </div>
                <div class="mb-3">
                    <label class="form-label">Kategori</label>
                    <input class="form-control" name="kategori" value="{{ old('kategori') }}" required>
                    <div class="form-text">Untuk snack, gunakan kategori <b>vitamin</b> (huruf kecil) agar dipilih otomatis.</div>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-primary">Simpan</button>
                    <a class="btn btn-outline-secondary" href="{{ route('admin.foods.index') }}">Kembali</a>
                </div>
            </form>
        </div>
    </div>
</x-admin-layout>

