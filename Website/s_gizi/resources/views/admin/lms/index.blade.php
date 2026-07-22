<x-admin-layout :title="'LMS WHO'">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h4 class="fw-bold mb-1">LMS Data Management</h4>
            <div class="text-muted">Kelola who_lms_age, who_lms_wfh, dan who_lms_wfl.</div>
        </div>
        <div class="btn-group">
            <a class="btn btn-outline-primary {{ $type === 'age' ? 'active' : '' }}" href="{{ route('admin.lms.index', ['type' => 'age']) }}">Age</a>
            <a class="btn btn-outline-primary {{ $type === 'wfh' ? 'active' : '' }}" href="{{ route('admin.lms.index', ['type' => 'wfh']) }}">WFH</a>
            <a class="btn btn-outline-primary {{ $type === 'wfl' ? 'active' : '' }}" href="{{ route('admin.lms.index', ['type' => 'wfl']) }}">WFL</a>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="post" action="{{ route('admin.lms.store') }}" class="row g-2">
                @csrf
                <input type="hidden" name="type" value="{{ $type }}">
                @if ($type === 'age')
                    <div class="col-md-2"><input name="umur" class="form-control" placeholder="Umur bln"></div>
                    <div class="col-md-2"><select name="indikator" class="form-select"><option value="bbu">BB/U</option><option value="tbu">TB/U</option></select></div>
                @else
                    <div class="col-md-2"><input name="{{ $type === 'wfl' ? 'panjang' : 'tinggi' }}" class="form-control" placeholder="{{ $type === 'wfl' ? 'Panjang' : 'Tinggi' }}"></div>
                @endif
                <div class="col-md-2"><select name="jk" class="form-select"><option value="L">L</option><option value="P">P</option></select></div>
                <div class="col-md-2"><input name="L" class="form-control" placeholder="L"></div>
                <div class="col-md-2"><input name="M" class="form-control" placeholder="M"></div>
                <div class="col-md-1"><input name="S" class="form-control" placeholder="S"></div>
                <div class="col-md-1"><button class="btn btn-primary w-100">Tambah</button></div>
            </form>
        </div>
    </div>

    <div class="card shadow-sm">
        <div class="table-responsive">
            <table class="table align-middle mb-0">
                <thead>
                <tr>
                    <th>ID</th>
                    @if ($type === 'age') <th>Umur</th><th>Indikator</th> @else <th>{{ $type === 'wfl' ? 'Panjang' : 'Tinggi' }}</th> @endif
                    <th>JK</th><th>L</th><th>M</th><th>S</th><th></th>
                </tr>
                </thead>
                <tbody>
                @foreach ($rows as $row)
                    <tr>
                        <td>{{ $row->id }}</td>
                        @if ($type === 'age') <td>{{ $row->umur }}</td><td>{{ $row->indikator }}</td> @else <td>{{ $type === 'wfl' ? $row->panjang : $row->tinggi }}</td> @endif
                        <td>{{ $row->jk }}</td><td>{{ $row->L }}</td><td>{{ $row->M }}</td><td>{{ $row->S }}</td>
                        <td class="text-end">
                            <form method="post" action="{{ route('admin.lms.destroy', [$type, $row->id]) }}" data-confirm="Hapus data LMS?">
                                @csrf @method('delete')
                                <button class="btn btn-sm btn-outline-danger">Hapus</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
                </tbody>
            </table>
        </div>
        <div class="card-body">{{ $rows->links('pagination::bootstrap-5') }}</div>
    </div>
</x-admin-layout>
