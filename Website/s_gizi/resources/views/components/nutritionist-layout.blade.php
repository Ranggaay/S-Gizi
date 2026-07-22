@props(['title' => 'Ahli Gizi S-Gizi'])

@php
    $user = auth()->user();
    $initials = collect(explode(' ', trim((string) ($user?->name ?? 'Ahli Gizi'))))->filter()->take(2)->map(fn ($part) => mb_substr($part, 0, 1))->implode('') ?: 'AG';
    $nutritionist = $user?->nutritionist;
    $expertId = trim((string) ($nutritionist?->expert_id ?: 'expert-'.$nutritionist?->user_id));
    $unreadChats = $nutritionist
        ? \App\Models\ConsultationRoom::query()
            ->where('expert_id', $expertId)
            ->whereHas('messages', fn ($query) => $query->where('sender_type', 'parent')->where('is_read', false))
            ->with(['user', 'child', 'messages' => fn ($query) => $query->where('sender_type', 'parent')->where('is_read', false)->latest()->take(1)])
            ->latest('last_message_at')
            ->take(5)
            ->get()
        : collect();
    $navItems = [
        ['label' => 'Dashboard', 'icon' => 'bi-grid-1x2', 'route' => 'nutritionist.dashboard'],
        ['label' => 'Konsultasi', 'icon' => 'bi-chat-dots', 'route' => 'nutritionist.consultations'],
        ['label' => 'Rekomendasi', 'icon' => 'bi-egg-fried', 'route' => 'nutritionist.recommendations.manage', 'children' => [
            ['label' => 'Manajemen Rekomendasi', 'icon' => 'bi-sliders', 'route' => 'nutritionist.recommendations.manage'],
            ['label' => 'Kirim ke Chat', 'icon' => 'bi-send', 'route' => 'nutritionist.recommendations.send'],
        ]],
        ['label' => 'Artikel', 'icon' => 'bi-newspaper', 'route' => 'nutritionist.articles.manage', 'children' => [
            ['label' => 'Manajemen Artikel', 'icon' => 'bi-pencil-square', 'route' => 'nutritionist.articles.manage'],
            ['label' => 'Kirim ke Chat', 'icon' => 'bi-send', 'route' => 'nutritionist.articles.send'],
        ]],
        ['label' => 'Profil', 'icon' => 'bi-person-circle', 'route' => 'nutritionist.profile'],
    ];
@endphp

<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }} | S-Gizi Ahli Gizi</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root { --primary:#0F8B8D; --bg:#F7FAFA; --text:#1F2937; --muted:#6B7280; --line:#DCEAEA; --shadow:0 18px 42px rgba(15,139,141,.10); }
        * { box-sizing:border-box; letter-spacing:0; }
        body { margin:0; min-height:100vh; background:var(--bg); color:var(--text); font-family:Inter,system-ui,sans-serif; }
        a { text-decoration:none; }
        .nutri-shell { display:flex; min-height:100vh; }
        .nutri-sidebar { position:fixed; inset:0 auto 0 0; width:240px; padding:12px 10px; background:linear-gradient(180deg,#FFFFFF 0%,#F8FCFC 100%); border-right:1px solid var(--line); z-index:20; transition:.22s ease; display:flex; flex-direction:column; }
        .nutri-brand { display:flex; align-items:center; gap:10px; padding:2px 6px 12px; margin-bottom:22px; color:var(--text); }
        .nutri-logo { width:68px; height:68px; display:grid; place-items:center; flex:0 0 auto; }
        .nutri-logo img { width:100%; height:100%; object-fit:contain; }
        .nutri-nav-label { color:#8EA0A6; font-size:12px; font-weight:800; text-transform:uppercase; margin:0 0 10px 8px; }
        .nutri-nav { flex:1 1 auto; min-height:0; display:flex; flex-direction:column; gap:8px; overflow-y:auto; overflow-x:hidden; padding-right:2px; }
        .nutri-nav::-webkit-scrollbar { width:6px; }
        .nutri-nav::-webkit-scrollbar-thumb { background:#C8DADA; border-radius:999px; }
        .nutri-nav a { display:flex; align-items:center; gap:12px; min-height:46px; padding:11px 13px; border-radius:14px; color:#42616A; font-weight:700; }
        .nutri-nav a.active, .nutri-nav a:hover { background:rgba(15,139,141,.11); color:var(--primary); }
        .nutri-main { flex:1; margin-left:240px; min-width:0; transition:.22s ease; }
        .sidebar-collapsed .nutri-sidebar { width:82px; }
        .sidebar-collapsed .nutri-main { margin-left:82px; }
        .sidebar-collapsed .nutri-brand { justify-content:center; }
        .sidebar-collapsed .nutri-brand span:not(.nutri-logo), .sidebar-collapsed .nutri-nav-label, .sidebar-collapsed .nutri-nav span, .sidebar-collapsed .nutri-logout span { display:none; }
        .sidebar-collapsed .nutri-nav a, .sidebar-collapsed .nutri-logout { justify-content:center; }
        .nutri-topbar { min-height:78px; padding:16px 28px; background:rgba(247,250,250,.88); border-bottom:1px solid var(--line); backdrop-filter:blur(14px); position:sticky; top:0; z-index:10; }
        .nutri-avatar { width:44px; height:44px; border-radius:50%; background:linear-gradient(135deg,var(--primary),#77C6AC); color:#fff; display:grid; place-items:center; font-weight:800; overflow:hidden; border:1px solid rgba(15,139,141,.16); }
        .nutri-avatar img { width:100%; height:100%; object-fit:cover; }
        .nutri-content { padding:28px; }
        .page-title { font-size:32px; font-weight:800; margin:0; }
        .page-subtitle { color:var(--muted); margin:6px 0 0; }
        .sg-card { background:#fff; border:1px solid var(--line); border-radius:22px; box-shadow:var(--shadow); }
        .mini-card { padding:18px; min-height:116px; display:flex; flex-direction:column; justify-content:space-between; }
        .mini-card span { color:var(--muted); font-weight:700; font-size:13px; }
        .mini-card strong { font-size:34px; line-height:1; }
        .badge-soft { display:inline-flex; align-items:center; min-height:28px; border-radius:999px; padding:5px 11px; font-size:12px; font-weight:800; white-space:normal; }
        .risk-high { background:#FDECEC; color:#C62828; }
        .risk-watch, .risk-repeat { background:#FFF3E0; color:#EF6C00; }
        .risk-normal { background:#E8F5E9; color:#2E7D32; }
        .risk-neutral { background:#EEF6F7; color:#0F8B8D; }
        .status-active { background:#E3F2FD; color:#1565C0; }
        .status-closed { background:#F3F4F6; color:#374151; }
        .sg-chip, .sg-status { display:inline-flex; align-items:center; gap:6px; border-radius:999px; padding:5px 9px; font-size:11px; font-weight:750; white-space:nowrap; }
        .sg-chip { background:#EAF6F4; color:#2f7580; }
        .sg-status-red { color:#A93A3A; background:#FFE5E5; }
        .sg-status-orange { color:#A66019; background:#FFF0DE; }
        .sg-status-yellow { color:#846012; background:#FFF7D8; }
        .sg-status-green { color:#1D7A50; background:#DCF6E9; }
        .sg-status-blue { color:#0F6F76; background:#E5F4F6; }
        .sg-status-gray { color:#66757B; background:#EEF3F4; }
        .btn-primary { --bs-btn-bg:var(--primary); --bs-btn-border-color:var(--primary); --bs-btn-hover-bg:#0b7779; --bs-btn-hover-border-color:#0b7779; }
        .btn-outline-primary { --bs-btn-color:var(--primary); --bs-btn-border-color:var(--primary); --bs-btn-hover-bg:var(--primary); --bs-btn-hover-border-color:var(--primary); }
        .form-control, .form-select { border-color:var(--line); border-radius:14px; min-height:44px; }
        .table { --bs-table-bg:transparent; }
        .min-w-0 { min-width:0; }
        .chat-grid { display:grid; grid-template-columns:260px minmax(0,1fr) 300px; gap:18px; align-items:stretch; height:calc(100vh - 165px); min-height:680px; }
        .chat-list, .chat-panel, .child-panel { min-height:0; overflow:hidden; border-radius:22px; }
        .chat-list, .chat-panel { display:flex; flex-direction:column; }
        .child-panel { overflow:auto; }
        .consultation-list-scroll { flex:1; overflow:auto; padding-right:3px; }
        .consultation-card { display:block; border:1px solid var(--line); border-radius:18px; padding:14px; margin-bottom:10px; color:inherit; background:#fff; transition:.18s ease; }
        .consultation-card:hover, .consultation-card.active { border-color:rgba(15,139,141,.35); background:#F3FBFB; transform:translateY(-1px); }
        .chat-panel { background:#fff; }
        .chat-header { padding:18px 22px; border-bottom:1px solid var(--line); flex:0 0 auto; }
        .chat-messages { flex:1; padding:22px; overflow-y:auto; min-height:0; }
        .chat-input { flex:0 0 auto; padding:16px 22px; border-top:1px solid var(--line); background:#fff; }
        .message { max-width:70%; padding:11px 14px; border-radius:18px; margin-bottom:11px; background:#EEF6F7; font-size:14px; line-height:1.45; overflow-wrap:anywhere; word-break:break-word; }
        .message.expert { margin-left:auto; background:#0F8B8D; color:#fff; }
        .message.parent { margin-right:auto; }
        .mobile-chat-list-button { display:none; }
        .nutri-logout-wrap { flex:0 0 auto; padding-top:10px; }
        .nutri-logout { display:flex; align-items:center; gap:12px; min-height:46px; padding:11px 13px; border-radius:14px; color:#C62828; font-weight:700; border:0; background:transparent; width:100%; }
        .notif-dot { position:absolute; top:5px; right:5px; width:12px; height:12px; border-radius:999px; background:#C62828; border:2px solid #fff; }
        @media (max-width: 1199.98px) {
            .chat-grid { grid-template-columns:minmax(0,1fr) 300px; height:auto; min-height:0; }
            .chat-grid.has-selected .chat-list { display:none; }
            .chat-grid:not(.has-selected) { grid-template-columns:1fr; }
            .chat-grid:not(.has-selected) .chat-panel, .chat-grid:not(.has-selected) .child-panel { display:none; }
            .chat-panel { min-height:650px; }
            .mobile-chat-list-button { display:inline-flex; }
        }
        @media (max-width: 767.98px) {
            .chat-grid, .chat-grid.has-selected { grid-template-columns:1fr; }
            .chat-panel { min-height:620px; }
            .message { max-width:86%; }
            .chat-messages, .chat-header, .chat-input { padding-left:16px; padding-right:16px; }
        }
        @media (max-width: 860px) { .nutri-sidebar { position:static; width:100%; height:auto; } .nutri-shell { display:block; } .nutri-main { margin-left:0; } .nutri-nav { flex-direction:row; overflow:auto; } .nutri-content { padding:18px; } }
    </style>
    {{ $styles ?? '' }}
</head>
<body>
<div class="nutri-shell">
    <aside class="nutri-sidebar">
        <a class="nutri-brand" href="{{ route('nutritionist.dashboard') }}">
            <span class="nutri-logo"><img src="{{ asset('assets/logo_sgizi.png') }}" alt="Logo S-Gizi"></span>
            <span><strong class="d-block fs-5">S-Gizi</strong><span class="d-block small text-muted fw-semibold">Monitoring Gizi</span></span>
        </a>
        <div class="nutri-nav-label">Menu</div>
        <nav class="nutri-nav">
            @foreach ($navItems as $item)
                @php($hasChildren = ! empty($item['children']))
                @php($isActive = request()->routeIs($item['route']) || ($hasChildren && collect($item['children'])->contains(fn ($child) => request()->routeIs($child['route']))))
                <a class="{{ $isActive ? 'active' : '' }}" href="{{ route($item['route']) }}"><i class="bi {{ $item['icon'] }}"></i><span>{{ $item['label'] }}</span></a>
                @if ($hasChildren)
                    <div class="ms-4 mb-1 vstack gap-1">
                        @foreach ($item['children'] as $child)
                            <a class="small py-1 {{ request()->routeIs($child['route']) ? 'active' : '' }}" href="{{ route($child['route']) }}"><i class="bi {{ $child['icon'] ?? 'bi-dot' }}"></i><span>{{ $child['label'] }}</span></a>
                        @endforeach
                    </div>
                @endif
            @endforeach
        </nav>
        <form class="nutri-logout-wrap" method="post" action="{{ route('admin.logout') }}" data-confirm="Logout dari website ahli gizi?">
            @csrf
            <button class="nutri-logout" type="submit"><i class="bi bi-box-arrow-right"></i><span>Logout</span></button>
        </form>
    </aside>
    <main class="nutri-main">
        <header class="nutri-topbar d-flex justify-content-between align-items-center gap-3">
            <div>
                <button id="sidebarToggle" class="btn btn-outline-primary rounded-4 me-2" type="button"><i class="bi bi-layout-sidebar"></i></button>
                <span class="fw-bold text-muted small">Website Role Ahli Gizi</span>
                <div class="fw-semibold">{{ now()->locale('id')->translatedFormat('d F Y') }}</div>
            </div>
            <div class="d-flex align-items-center gap-3">
                <div class="dropdown">
                    <button class="btn btn-outline-primary rounded-pill position-relative" data-bs-toggle="dropdown" type="button">
                        <i class="bi bi-bell"></i>
                        @if ($unreadChats->isNotEmpty())<span class="notif-dot"></span>@endif
                    </button>
                    <div class="dropdown-menu dropdown-menu-end p-2" style="min-width:320px">
                        <div class="fw-bold px-2 py-1">Chat terbaru</div>
                        @forelse ($unreadChats as $room)
                            <a class="dropdown-item rounded-3 py-2" href="{{ route('nutritionist.consultations', ['room' => $room->id]) }}">
                                <strong>{{ $room->child?->nama ?? '-' }}</strong>
                                <div class="small text-muted">{{ $room->user?->name ?? '-' }} - {{ \Illuminate\Support\Str::limit($room->last_message, 55) }}</div>
                            </a>
                        @empty
                            <div class="text-muted small px-2 py-3">Belum ada chat baru.</div>
                        @endforelse
                    </div>
                </div>
                <div class="text-end d-none d-sm-block"><strong>{{ $user?->name }}</strong><div class="text-muted small">{{ $user?->nutritionist?->specialization ?: 'Ahli Gizi' }}</div></div>
                <div class="dropdown">
                    <button class="nutri-avatar" data-bs-toggle="dropdown" type="button">
                        {{ $initials }}
                    </button>
                    <div class="dropdown-menu dropdown-menu-end p-2">
                        <a class="dropdown-item rounded-3" href="{{ route('nutritionist.profile') }}"><i class="bi bi-person me-2"></i>Profil</a>
                        <form method="post" action="{{ route('admin.logout') }}">@csrf<button class="dropdown-item rounded-3 text-danger"><i class="bi bi-box-arrow-right me-2"></i>Logout</button></form>
                    </div>
                </div>
            </div>
        </header>
        <section class="nutri-content">
            @if (session('success')) <div class="alert alert-success rounded-4 border-0">{{ session('success') }}</div> @endif
            @if ($errors->any()) <div class="alert alert-danger rounded-4 border-0">{{ $errors->first() }}</div> @endif
            {{ $slot }}
        </section>
    </main>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    const nutriBody = document.body;
    if (localStorage.getItem('nutritionistSidebarCollapsed') === '1') nutriBody.classList.add('sidebar-collapsed');
    document.getElementById('sidebarToggle')?.addEventListener('click', () => {
        nutriBody.classList.toggle('sidebar-collapsed');
        localStorage.setItem('nutritionistSidebarCollapsed', nutriBody.classList.contains('sidebar-collapsed') ? '1' : '0');
    });
    document.addEventListener('submit', (event) => {
        const form = event.target;
        if (!(form instanceof HTMLFormElement)) return;
        const method = (form.querySelector('input[name="_method"]')?.value || form.method || 'GET').toUpperCase();
        const submitter = event.submitter;
        const text = (submitter?.textContent || '').trim().toLowerCase();
        let message = form.dataset.confirm || '';
        if (!message && method === 'DELETE') message = 'Yakin ingin menghapus permanen data ini?';
        if (!message && text.includes('arsipkan')) message = 'Yakin ingin mengarsipkan data ini?';
        if (!message && text.includes('logout')) message = 'Logout dari website ahli gizi?';
        if (message && !window.confirm(message)) event.preventDefault();
    });
</script>
{{ $scripts ?? '' }}
</body>
</html>
