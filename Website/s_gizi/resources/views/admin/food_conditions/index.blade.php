<x-admin-layout :title="'Mapping Status Gizi'">
    <div class="mb-3">
        <h4 class="mb-1">Mapping Status Gizi</h4>
        <div class="text-muted">Hubungkan makanan ke status gabungan (dipakai API untuk rekomendasi).</div>
    </div>

    <div class="card shadow-sm mb-3">
        <div class="card-body">
            <form class="row g-2 align-items-end" method="post" action="{{ route('admin.food_conditions.store') }}">
                @csrf
                <div class="col-md-6">
                    <label class="form-label">Makanan</label>
                    <select class="form-select" name="food_id" required>
                        <option value="">Pilih...</option>
                        @foreach ($foods as $food)
                            <option value="{{ $food->id }}">{{ $food->nama }} ({{ $food->kategori }})</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Status Gizi</label>
                    <input class="form-control" name="status_gizi" value="{{ old('status_gizi') }}" placeholder="Contoh: Stunting" required>
                    <div class="form-text">Harus sama persis dengan output `status_gabungan` API.</div>
                </div>
                <div class="col-md-2 d-grid">
                    <button class="btn btn-primary">Simpan</button>
                </div>
            </form>
        </div>
    </div>

    <form class="row g-2 mb-3" method="get">
        <div class="col-md-6">
            <input class="form-control" name="status" value="{{ $status }}" placeholder="Filter status_gizi...">
        </div>
        <div class="col-md-auto">
            <button class="btn btn-outline-secondary">Filter</button>
        </div>
    </form>

    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table table-striped mb-0">
                <thead>
                <tr>
                    <th>#</th>
                    <th>Status</th>
                    <th>Makanan</th>
                    <th>Kategori</th>
                    <th class="text-end">Aksi</th>
                </tr>
                </thead>
                <tbody>
                @forelse ($mappings as $m)
                    <tr>
                        <td>{{ $m->id }}</td>
                        <td><span class="badge text-bg-info">{{ $m->status_gizi }}</span></td>
                        <td>{{ $m->food?->nama }}</td>
                        <td><span class="badge text-bg-secondary">{{ $m->food?->kategori }}</span></td>
                        <td class="text-end">
                            <form class="d-inline" method="post" action="{{ route('admin.food_conditions.destroy', $m) }}" onsubmit="return confirm('Hapus mapping ini?')">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-outline-danger">Hapus</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="text-center text-muted py-4">Belum ada mapping.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-body">
            {{ $mappings->links('pagination::bootstrap-5') }}
        </div>
    </div>
</x-admin-layout>

