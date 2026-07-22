<x-admin-layout :title="$mode === 'create' ? 'Tambah Ahli Gizi' : 'Edit Ahli Gizi'">
    @php
        $user = $nutritionist->user;
        $isEdit = $mode === 'edit';
        $status = $user?->account_status ?: 'Aktif';
        $gender = $user?->parent_gender;
        $specializations = ['Stunting', 'Gizi Kurang', 'MPASI', 'Obesitas Anak', 'Tumbuh Kembang', 'Konsultasi Umum'];
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-3">
        <div>
            <h1 class="sg-page-title">{{ $isEdit ? 'Edit Ahli Gizi' : 'Tambah Ahli Gizi' }}</h1>
            <p class="sg-page-subtitle">Akun ahli gizi hanya dibuat admin dan dapat digunakan login di aplikasi mobile.</p>
        </div>
        <a class="btn btn-outline-primary rounded-4 px-3" href="{{ route('admin.nutritionists') }}"><i class="bi bi-arrow-left me-1"></i>Kembali</a>
    </div>

    @if ($errors->any())
        <div class="alert alert-danger rounded-4 border-0">
            <strong>Data belum bisa disimpan.</strong>
            <div class="small mt-1">{{ $errors->first() }}</div>
        </div>
    @endif

    <form class="sg-card p-3 p-lg-4" method="post" enctype="multipart/form-data" action="{{ $isEdit ? route('admin.nutritionists.update', $nutritionist) : route('admin.nutritionists.store') }}" @if($isEdit) data-confirm="Simpan perubahan data ahli gizi ini?" @endif>
        @csrf
        @if ($isEdit)
            @method('PUT')
        @endif

        <div class="row g-3">
            <div class="col-lg-3">
                <label class="form-label small fw-semibold text-muted">Foto profile/avatar</label>
                <div class="sg-avatar-upload">
                    @if ($user?->avatar)
                        <img src="{{ asset($user->avatar) }}" alt="Foto {{ $user->name }}">
                    @else
                        <span>{{ strtoupper(substr($user?->name ?? 'A', 0, 1)) }}</span>
                    @endif
                </div>
                <input class="form-control mt-2" type="file" name="avatar" accept="image/*">
            </div>

            <div class="col-lg-9">
                <div class="row g-3">
                    <div class="col-md-7">
                        <label class="form-label small fw-semibold text-muted">Nama lengkap</label>
                        <input class="form-control" name="name" value="{{ old('name', $user?->name) }}" required>
                    </div>
                    <div class="col-md-5">
                        <label class="form-label small fw-semibold text-muted">Gelar</label>
                        <input class="form-control" name="title" value="{{ old('title', $nutritionist->title) }}" placeholder="S.Gz, M.Gz">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Nomor HP</label>
                        <input class="form-control" name="phone" value="{{ old('phone', $user?->phone) }}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Email</label>
                        <input class="form-control" type="email" name="email" value="{{ old('email', $user?->email) }}" required>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Password</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="password" autocomplete="new-password" {{ $isEdit ? '' : 'required' }}>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                        @if ($isEdit)<div class="small text-muted mt-1">Kosongkan jika tidak ingin mengganti password.</div>@endif
                    </div>
                    <div class="col-md-6">
                        <label class="form-label small fw-semibold text-muted">Konfirmasi password</label>
                        <div class="input-group">
                            <input class="form-control" type="password" name="password_confirmation" autocomplete="new-password" {{ $isEdit ? '' : 'required' }}>
                            <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
                                <i class="bi bi-eye"></i>
                            </button>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted">Jenis kelamin</label>
                        <select class="form-select" name="gender">
                            <option value="">-</option>
                            <option value="laki-laki" @selected(old('gender', $gender) === 'laki-laki')>Laki-laki</option>
                            <option value="perempuan" @selected(old('gender', $gender) === 'perempuan')>Perempuan</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted">Spesialisasi</label>
                        <select class="form-select" name="specialization" required>
                            @foreach ($specializations as $option)
                                <option value="{{ $option }}" @selected(old('specialization', $nutritionist->specialization) === $option)>{{ $option }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted">Pengalaman kerja</label>
                        <input class="form-control" type="number" min="0" max="60" name="experience_years" value="{{ old('experience_years', $nutritionist->experience_years ?? 0) }}" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted">Status akun</label>
                        <select class="form-select" name="account_status">
                            <option value="Aktif" @selected(old('account_status', $status) === 'Aktif')>Aktif</option>
                            <option value="Nonaktif" @selected(old('account_status', $status) === 'Nonaktif')>Nonaktif</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted">Maks. konsultasi aktif</label>
                        <input class="form-control" type="number" min="1" max="100" name="max_consultation" value="{{ old('max_consultation', $nutritionist->max_consultation ?? 25) }}" required>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label small fw-semibold text-muted">STR/SIP</label>
                        <input class="form-control" name="str_sip" value="{{ old('str_sip', $nutritionist->str_sip) }}" placeholder="Opsional">
                    </div>
                    <div class="col-12">
                        <label class="form-label small fw-semibold text-muted">Bio singkat</label>
                        <textarea class="form-control" name="bio" rows="3" placeholder="Fokus layanan dan pengalaman pendampingan anak">{{ old('bio', $nutritionist->bio) }}</textarea>
                    </div>
                    <div class="col-12">
                        <label class="form-label small fw-semibold text-muted">Expert ID</label>
                        <input class="form-control" name="expert_id" value="{{ old('expert_id', $nutritionist->expert_id ?: 'exp-'.str_pad((string) ($nutritionist->id ?: random_int(10, 99)), 2, '0', STR_PAD_LEFT)) }}" required>
                    </div>
                    <div class="col-12">
                        <button class="btn btn-primary rounded-4 px-4" type="submit">Simpan Data</button>
                    </div>
                </div>
            </div>
        </div>
    </form>

    <x-slot:styles>
        <style>
            .sg-avatar-upload {
                width: 132px;
                height: 132px;
                border-radius: 24px;
                border: 1px solid rgba(75,142,150,.18);
                background: #EAF6F4;
                display: grid;
                place-items: center;
                overflow: hidden;
                color: #4B8E96;
                font-weight: 800;
                font-size: 34px;
            }
            .sg-avatar-upload img { width: 100%; height: 100%; object-fit: cover; }
        </style>
    </x-slot:styles>
</x-admin-layout>
