@props(['title' => 'Admin Gizi Balita'])

<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        :root { --sgizi: #4B8E96; --sgizi-bg: #F5F7F6; }
        body { background: var(--sgizi-bg); }
        .navbar { background: var(--sgizi) !important; }
        .card { border: 1px solid #e0e7e4; border-radius: 20px; }
        .btn-primary { background: var(--sgizi); border-color: var(--sgizi); }
        .text-sgizi { color: var(--sgizi); }
    </style>
</head>
<body class="bg-light">
<nav class="navbar navbar-expand-lg navbar-dark bg-primary">
    <div class="container">
        <a class="navbar-brand fw-bold" href="{{ route('admin.dashboard') }}">S-Gizi Admin</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#nav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="nav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.dashboard') }}">Dashboard</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.children.index') }}">Anak</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.foods.index') }}">Makanan</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.lms.index') }}">LMS WHO</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.articles.index') }}">Artikel</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.food_conditions.index') }}">Mapping Status</a></li>
                <li class="nav-item"><a class="nav-link" href="{{ route('admin.measurements.index') }}">Riwayat</a></li>
            </ul>
        </div>
    </div>
</nav>

<main class="container py-4">
    @if (session('success'))
        <div class="alert alert-success">{{ session('success') }}</div>
    @endif
    @if ($errors->any())
        <div class="alert alert-danger">
            <div class="fw-semibold mb-2">Validasi gagal</div>
            <ul class="mb-0">
                @foreach ($errors->all() as $e)
                    <li>{{ $e }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    {{ $slot }}
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>

