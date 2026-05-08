<x-admin-layout :title="'Data Anak'">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <div>
            <h4 class="mb-1">Data Anak</h4>
            <div class="text-muted">Data balita yang dipakai untuk perhitungan umur (bulan).</div>
        </div>
        <a class="btn btn-primary" href="{{ route('admin.children.create') }}">Tambah</a>
    </div>

    <form class="row g-2 mb-3" method="get">
        <div class="col-md-6">
            <input class="form-control" name="q" value="{{ $q }}" placeholder="Cari nama anak...">
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
                    <th>Tanggal Lahir</th>
                    <th>JK</th>
                    <th class="text-end">Aksi</th>
                </tr>
                </thead>
                <tbody>
                @forelse ($children as $c)
                    <tr>
                        <td>{{ $c->id }}</td>
                        <td>{{ $c->nama }}</td>
                        <td>{{ $c->tanggal_lahir?->format('Y-m-d') }}</td>
                        <td><span class="badge text-bg-secondary">{{ $c->jenis_kelamin }}</span></td>
                        <td class="text-end">
                            <a class="btn btn-sm btn-outline-primary" href="{{ route('admin.children.edit', $c) }}">Edit</a>
                            <form class="d-inline" method="post" action="{{ route('admin.children.destroy', $c) }}" onsubmit="return confirm('Hapus data anak ini?')">
                                @csrf
                                @method('DELETE')
                                <button class="btn btn-sm btn-outline-danger">Hapus</button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td colspan="5" class="text-center text-muted py-4">Belum ada data.</td></tr>
                @endforelse
                </tbody>
            </table>
        </div>
        <div class="card-body">
            {{ $children->links('pagination::bootstrap-5') }}
        </div>
    </div>
</x-admin-layout>

