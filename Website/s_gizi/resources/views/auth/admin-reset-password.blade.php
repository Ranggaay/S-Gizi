<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reset Password | S-Gizi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body { min-height:100vh; display:grid; place-items:center; margin:0; background:linear-gradient(135deg,#F2FAFA,#FFF8EF); font-family:Inter,system-ui,sans-serif; }
        .card { width:min(430px, calc(100vw - 28px)); border:0; border-radius:26px; box-shadow:0 24px 60px rgba(35,76,82,.14); }
        .btn-primary { background:#4B8E96; border-color:#4B8E96; border-radius:16px; min-height:46px; }
        .form-control { border-radius:16px; min-height:46px; }
        .input-group .form-control { border-top-right-radius:0; border-bottom-right-radius:0; }
        .input-group .btn { border-top-right-radius:16px; border-bottom-right-radius:16px; }
    </style>
</head>
<body>
<form class="card p-4" method="post" action="{{ route('admin.password.update') }}">
    @csrf
    <input type="hidden" name="token" value="{{ $token }}">
    <h3 class="fw-bold">Reset Password</h3>
    <p class="text-muted">Buat password baru minimal 8 karakter.</p>
    @if ($errors->any())<div class="alert alert-danger rounded-4 border-0">{{ $errors->first() }}</div>@endif
    <label class="form-label small fw-semibold text-muted">Email</label>
    <input class="form-control mb-3" type="email" name="email" value="{{ old('email', $email) }}" required>
    <label class="form-label small fw-semibold text-muted">Password Baru</label>
    <div class="input-group mb-3">
        <input class="form-control" type="password" name="password" minlength="8" required>
        <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan password baru">
            <i class="bi bi-eye"></i>
        </button>
    </div>
    <label class="form-label small fw-semibold text-muted">Konfirmasi Password</label>
    <div class="input-group mb-3">
        <input class="form-control" type="password" name="password_confirmation" minlength="8" required>
        <button class="btn btn-outline-secondary" type="button" data-password-toggle aria-label="Tampilkan konfirmasi password">
            <i class="bi bi-eye"></i>
        </button>
    </div>
    <button class="btn btn-primary w-100">Simpan Password</button>
</form>
<script>
    document.addEventListener('click', (event) => {
        const button = event.target.closest('[data-password-toggle]');
        if (!button) return;
        const input = button.closest('.input-group')?.querySelector('input[type="password"], input[type="text"]');
        const icon = button.querySelector('i');
        if (!input) return;
        const shouldShow = input.type === 'password';
        input.type = shouldShow ? 'text' : 'password';
        if (icon) {
            icon.classList.toggle('bi-eye', !shouldShow);
            icon.classList.toggle('bi-eye-slash', shouldShow);
        }
    });
</script>
</body>
</html>
