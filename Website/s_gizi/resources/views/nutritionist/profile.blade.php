<x-nutritionist-layout title="Profil">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div><h1 class="page-title">Profil Ahli Gizi</h1><p class="page-subtitle">Kelola data akun dan status menerima konsultasi.</p></div>
        <form method="post" action="{{ route('admin.logout') }}">@csrf<button class="btn btn-outline-primary rounded-pill">Logout</button></form>
    </div>
    <div class="row g-4">
        <div class="col-xl-7">
            <form class="sg-card p-4" method="post" action="{{ route('nutritionist.profile.update') }}" enctype="multipart/form-data">
                @csrf @method('PUT')
                <h5 class="fw-bold mb-3">Data Profil</h5>
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label">Foto Profil</label>
                        <div class="d-flex align-items-center gap-3">
                            <div class="nutri-avatar" style="width:86px;height:86px;border-radius:24px">
                                @if ($user->avatar)<img src="{{ asset($user->avatar) }}" alt="{{ $user->name }}">@else{{ strtoupper(substr($user->name, 0, 1)) }}@endif
                            </div>
                            <input class="form-control" type="file" name="avatar" accept="image/*">
                        </div>
                    </div>
                    <div class="col-md-6"><label class="form-label">Nama</label><input class="form-control" name="name" value="{{ old('name', $user->name) }}" required></div>
                    <div class="col-md-6"><label class="form-label">Nomor HP</label><input class="form-control" name="phone" value="{{ old('phone', $user->phone) }}"></div>
                    <div class="col-md-6"><label class="form-label">Email</label><input class="form-control" name="email" value="{{ old('email', $user->email) }}"></div>
                    <div class="col-md-6"><label class="form-label">Profesi</label><input class="form-control" name="title" value="{{ old('title', $nutritionist->title) }}"></div>
                    <div class="col-md-6"><label class="form-label">Spesialisasi</label><select class="form-select" name="specialization">@foreach (['Stunting', 'Gizi Kurang', 'MPASI', 'Obesitas Anak', 'Tumbuh Kembang', 'Konsultasi Umum'] as $item)<option value="{{ $item }}" @selected(old('specialization', $nutritionist->specialization) === $item)>{{ $item }}</option>@endforeach</select></div>
                    <div class="col-12"><label class="form-label">Tempat kerja / Bio</label><textarea class="form-control" name="bio" rows="4">{{ old('bio', $nutritionist->bio) }}</textarea></div>
                    <div class="col-12 text-end"><button class="btn btn-primary rounded-pill px-4">Simpan Profil</button></div>
                </div>
            </form>
        </div>
        <div class="col-xl-5">
            <div class="sg-card p-4 mb-4">
                <h5 class="fw-bold mb-3">Status Konsultasi</h5>
                <form method="post" action="{{ route('nutritionist.profile.status') }}">
                    @csrf @method('PUT')
                    <select class="form-select mb-3" name="is_available"><option value="1" @selected($nutritionist->is_available)>Aktif menerima konsultasi</option><option value="0" @selected(! $nutritionist->is_available)>Tidak aktif</option></select>
                    <button class="btn btn-primary rounded-pill w-100">Perbarui Status</button>
                </form>
            </div>
            <form class="sg-card p-4" method="post" action="{{ route('nutritionist.profile.password') }}">
                @csrf @method('PUT')
                <h5 class="fw-bold mb-3">Ubah Password</h5>
                <input class="form-control mb-2" type="password" name="current_password" placeholder="Password lama" required>
                <input class="form-control mb-2" type="password" name="password" placeholder="Password baru" required>
                <input class="form-control mb-3" type="password" name="password_confirmation" placeholder="Konfirmasi password" required>
                <button class="btn btn-outline-primary rounded-pill w-100">Ubah Password</button>
            </form>
        </div>
    </div>
</x-nutritionist-layout>
