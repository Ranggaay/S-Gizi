<x-admin-layout :title="'Manajemen Makanan'">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h4 class="mb-1">Manajemen Makanan</h4>
            <div class="text-muted">Kelola data makanan yang akan dipakai rekomendasi.</div>
        </div>
        <a class="btn btn-primary" href="{{ route('admin.foods.create') }}">Tambah</a>
    </div>

    <form class="row g-2 mb-3" method="get">
        <div class="col-md-6">
            <input class="form-control" name="q" value="{{ $q }}" placeholder="Cari nama/kategori...">
        </div>
        <div class="col-md-auto">
            <button class="btn btn-outline-secondary">Cari</button>
        </div>
    </form>

    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-striped mb-0">
                <thead>
                <tr>
                    <th>#</th>
                    <th>Nama</th>
                    <th>Kategori</th>
                    <th class="text-end">Aksi</th>
                </tr>
                </thead>
                <tbody>
                @forelse ($foods as $food)
                    <tr>
                        <td>{{ $food->id }}</td>
                        <td>{{ $food->nama }}</td>
                        <td><span class="badge text-bg-secondary">{{ $food->kategori }}</span></td>
                        <td class="text-end">
                            <a class="btn btn-sm btn-outline-primary" href="{{ route('admin.foods.edit', $food) }}">Edit</a>
                            <form class="d-inline" method="post" action="{{ route('admin.foods.destroy', $food) }}" onsubmit="return confirm('Hapus makanan ini?')">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-outline-danger">Hapus</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="text-center text-muted py-4">Belum ada data.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-body">
            {{ $foods->links('pagination::bootstrap-5') }}
        </div>
    </div>
</x-admin-layout>

