<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login Admin | S-Gizi</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root { --sgizi:#4B8E96; --deep:#2F6870; --line:#DCEAEA; --bg:#F4FAFA; --ink:#182A31; --muted:#687D84; }
        * { box-sizing: border-box; letter-spacing: 0; }
        body { min-height: 100vh; margin: 0; font-family: Inter, system-ui, sans-serif; color: var(--ink); background: linear-gradient(135deg, #F2FAFA, #E7F4F1 45%, #FFF8EF); overflow-x: hidden; }
        .sg-login-shell { min-height: 100vh; display: grid; grid-template-columns: minmax(0, 1fr) 460px; }
        .sg-login-visual { padding: 48px; display: flex; flex-direction: column; justify-content: center; }
        .sg-logo { width: 118px; height: 118px; object-fit: contain; margin-bottom: 20px; }
        .sg-visual-card { max-width: 620px; }
        .sg-visual-card h1 { font-size: clamp(34px, 4vw, 58px); font-weight: 800; line-height: 1.02; margin-bottom: 14px; }
        .sg-visual-card p { color: var(--muted); font-size: 16px; max-width: 520px; }
        .sg-health-panel { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin-top: 28px; max-width: 620px; }
        .sg-health-panel div { background: rgba(255,255,255,.72); border: 1px solid rgba(75,142,150,.14); border-radius: 20px; padding: 16px; box-shadow: 0 18px 38px rgba(35,76,82,.08); }
        .sg-health-panel i { color: var(--sgizi); font-size: 24px; }
        .sg-health-panel strong { display: block; margin-top: 12px; font-size: 14px; }
        .sg-login-side { display: flex; align-items: center; padding: 24px; background: rgba(255,255,255,.56); backdrop-filter: blur(18px); border-left: 1px solid rgba(75,142,150,.12); }
        .sg-login-card { width: 100%; background: #fff; border: 1px solid rgba(75,142,150,.15); border-radius: 28px; padding: 28px; box-shadow: 0 24px 60px rgba(35,76,82,.14); }
        .sg-input { border: 1px solid var(--line); border-radius: 16px; min-height: 48px; padding: 0 12px; display: flex; align-items: center; gap: 10px; }
        .sg-input input { border: 0; outline: 0; flex: 1; min-width: 0; }
        .sg-input i { color: var(--sgizi); }
        .btn-primary { background: var(--sgizi); border-color: var(--sgizi); border-radius: 16px; min-height: 48px; font-weight: 750; }
        .btn-primary:hover { background: var(--deep); border-color: var(--deep); }
        .sg-splash { position: fixed; inset: 0; z-index: 50; display: grid; place-items: center; background: #F4FAFA; animation: sgFade .8s ease 1.1s forwards; pointer-events: none; }
        .sg-splash img { width: 96px; height: 96px; object-fit: contain; animation: sgPulse 1s ease infinite alternate; }
        @keyframes sgFade { to { opacity: 0; visibility: hidden; } }
        @keyframes sgPulse { to { transform: scale(1.05); opacity: .82; } }
        @media (max-width: 991.98px) { .sg-login-shell { grid-template-columns: minmax(0, 1fr); } .sg-login-visual { display: none; } .sg-login-side { min-height: 100vh; border-left: 0; } }
    </style>
</head>
<body>
<div class="sg-splash"><img src="{{ asset('assets/logo_sgizi.png') }}" alt="S-Gizi"></div>
<main class="sg-login-shell">
    <section class="sg-login-visual">
        <div class="sg-visual-card">
            <img class="sg-logo" src="{{ asset('assets/logo_sgizi.png') }}" alt="Logo S-Gizi">
            <h1>S-Gizi Admin Monitoring</h1>
            <p>Sistem Monitoring Gizi Anak Berbasis WHO untuk memantau pertumbuhan, konsultasi, edukasi, dan risiko anak secara aman.</p>
        </div>
        <div class="sg-health-panel">
            <div><i class="bi bi-activity"></i><strong>Validasi WHO</strong></div>
            <div><i class="bi bi-shield-check"></i><strong>Data Aman</strong></div>
            <div><i class="bi bi-clipboard2-pulse"></i><strong>Monitoring Realtime</strong></div>
        </div>
    </section>

    <section class="sg-login-side">
        <form id="loginForm" class="sg-login-card" method="post" action="{{ route('admin.login.store') }}">
            @csrf
            <div class="text-center mb-4 d-lg-none"><img class="sg-logo" src="{{ asset('assets/logo_sgizi.png') }}" alt="Logo S-Gizi"></div>
            <h3 class="fw-bold mb-1">Login Admin</h3>
            <p class="text-muted mb-4">Masuk untuk mengelola dashboard monitoring gizi anak.</p>

            @if (session('status'))
                <div class="alert alert-success rounded-4 border-0">{{ session('status') }}</div>
            @endif
            @if ($errors->any())
                <div class="alert alert-danger rounded-4 border-0">{{ $errors->first() }}</div>
            @endif

            <label class="form-label small fw-semibold text-muted">Email / Nomor HP</label>
            <div class="sg-input mb-3">
                <i class="bi bi-person"></i>
                <input name="login" value="{{ old('login') }}" placeholder="admin@sgizi.local" required autocomplete="username">
            </div>

            <label class="form-label small fw-semibold text-muted">Password</label>
            <div class="sg-input mb-2">
                <i class="bi bi-lock"></i>
                <input id="passwordInput" type="password" name="password" placeholder="Minimal 8 karakter" minlength="8" required autocomplete="current-password">
                <button class="btn btn-sm border-0 p-0" id="togglePassword" type="button"><i class="bi bi-eye"></i></button>
            </div>

            <div class="d-flex justify-content-end align-items-center mb-4">
                <a class="small text-decoration-none" style="color:var(--sgizi)" href="{{ route('admin.password.request') }}">Lupa Password?</a>
            </div>

            <button id="loginButton" class="btn btn-primary w-100" type="submit">
                <span class="login-text">Login</span>
                <span class="loading-text d-none"><span class="spinner-border spinner-border-sm me-2"></span>Memverifikasi akun...</span>
            </button>
            <div class="text-center small text-muted mt-4">Sistem Monitoring Gizi Anak Berbasis WHO</div>
        </form>
    </section>
</main>
<script>
    document.getElementById('togglePassword')?.addEventListener('click', () => {
        const input = document.getElementById('passwordInput');
        input.type = input.type === 'password' ? 'text' : 'password';
    });
    document.getElementById('loginForm')?.addEventListener('submit', () => {
        const button = document.getElementById('loginButton');
        button.disabled = true;
        button.querySelector('.login-text').classList.add('d-none');
        button.querySelector('.loading-text').classList.remove('d-none');
    });
</script>
</body>
</html>
