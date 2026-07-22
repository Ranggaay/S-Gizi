<x-admin-layout :title="'Tambah Menu Rekomendasi'">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
        <div>
            <h1 class="sg-page-title">Tambah Menu Rekomendasi</h1>
            <p class="sg-page-subtitle">Hubungkan makanan dengan status WHO, usia, nutrisi, dan alasan rekomendasi.</p>
        </div>
        <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.foods.index') }}">Kembali</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger rounded-4 border-0">
            <strong>Menu belum bisa disimpan.</strong>
            <div class="small mt-1">{{ $errors->first() }}</div>
        </div>
    @endif

    <div class="sg-card p-3 p-lg-4">
        <form method="post" action="{{ route('admin.foods.store') }}" enctype="multipart/form-data">
            @csrf
            @include('admin.foods._form')
            <div class="d-flex flex-wrap gap-2 mt-4">
                <button class="btn btn-primary rounded-4 px-4" type="submit"><i class="bi bi-cloud-arrow-up me-1"></i>Simpan Menu</button>
                <a class="btn btn-outline-primary rounded-4 px-4" href="{{ route('admin.foods.index') }}">Batal</a>
            </div>
        </form>
    </div>
</x-admin-layout>
