<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Lupa Password | S-Gizi</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { min-height:100vh; display:grid; place-items:center; margin:0; background:linear-gradient(135deg,#F2FAFA,#FFF8EF); font-family:Inter,system-ui,sans-serif; }
        .card { width:min(430px, calc(100vw - 28px)); border:0; border-radius:26px; box-shadow:0 24px 60px rgba(35,76,82,.14); }
        .btn-primary { background:#4B8E96; border-color:#4B8E96; border-radius:16px; min-height:46px; }
        .form-control { border-radius:16px; min-height:46px; }
    </style>
</head>
<body>
<form class="card p-4" method="post" action="{{ route('admin.password.email') }}">
    @csrf
    <img src="{{ asset('assets/logo_sgizi.png') }}" alt="S-Gizi" style="width:82px;height:82px;object-fit:contain">
    <h3 class="fw-bold mt-3">Lupa Password</h3>
    <p class="text-muted">Masukkan email admin untuk menerima link reset password.</p>
    @if (session('status'))<div class="alert alert-success rounded-4 border-0">{{ session('status') }}</div>@endif
    @if ($errors->any())<div class="alert alert-danger rounded-4 border-0">{{ $errors->first() }}</div>@endif
    <label class="form-label small fw-semibold text-muted">Email Admin</label>
    <input class="form-control mb-3" type="email" name="email" required>
    <button class="btn btn-primary w-100">Kirim Reset Link</button>
    <a class="btn btn-link mt-2 text-decoration-none" style="color:#4B8E96" href="{{ route('admin.login') }}">Kembali ke login</a>
</form>
</body>
</html>
