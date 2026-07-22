@props(['title' => 'Admin S-Gizi'])

@php
    $adminUser = auth()->user();
    $adminInitials = collect(explode(' ', trim((string) ($adminUser?->name ?? 'Admin S-Gizi'))))
        ->filter()
        ->take(2)
        ->map(fn ($part) => mb_substr($part, 0, 1))
        ->implode('') ?: 'AD';
    $adminRoleLabel = match ($adminUser?->role) {
        'super_admin' => 'Super Admin',
        'admin_operasional' => 'Admin Operasional',
        default => 'Administrator',
    };
    $pendingFoodVerifications = \App\Models\Makanan::query()->where('status_menu', 'Menunggu Verifikasi')->count();
    $pendingArticleVerifications = \App\Models\Article::query()->where('status', 'Menunggu Verifikasi')->count();
    $pendingVerifications = $pendingFoodVerifications + $pendingArticleVerifications;
    $navItems = [
        ['label' => 'Dashboard', 'icon' => 'bi-grid-1x2', 'route' => 'admin.dashboard'],
        ['label' => 'Monitoring Anak', 'icon' => 'bi-activity', 'route' => 'admin.monitoring'],
        ['label' => 'Konsultasi', 'icon' => 'bi-chat-dots', 'route' => 'admin.consultations'],
        ['label' => 'Orang Tua', 'icon' => 'bi-people', 'route' => 'admin.parents'],
        ['label' => 'Data Anak', 'icon' => 'bi-person-hearts', 'route' => 'admin.children.index'],
        ['label' => 'Ahli Gizi', 'icon' => 'bi-person-vcard', 'route' => 'admin.nutritionists'],
        ['label' => 'Artikel', 'icon' => 'bi-newspaper', 'route' => 'admin.articles.index'],
        ['label' => 'Rekomendasi Makanan', 'icon' => 'bi-egg-fried', 'route' => 'admin.foods.index'],
        ['label' => 'Pengaturan', 'icon' => 'bi-gear', 'route' => 'admin.settings'],
    ];
@endphp

<!doctype html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $title }} | Admin S-Gizi</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        :root {
            --sgizi: #4B8E96;
            --sgizi-deep: #2F6870;
            --sgizi-mint: #DFF4E8;
            --sgizi-green: #38B87C;
            --sgizi-orange: #F6A95B;
            --sgizi-red: #EB6B6B;
            --sgizi-yellow: #F4C95D;
            --sgizi-ink: #1C2A33;
            --sgizi-muted: #6E7F86;
            --sgizi-line: #E3ECEC;
            --sgizi-bg: #F5F8F8;
            --sgizi-card: #FFFFFF;
            --sgizi-shadow: 0 18px 45px rgba(35, 76, 82, .10);
        }

        * { box-sizing: border-box; letter-spacing: 0; }
        html, body { max-width: 100%; overflow-x: hidden; }
        body {
            min-height: 100vh;
            margin: 0;
            background: var(--sgizi-bg);
            color: var(--sgizi-ink);
            font-family: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }

        a { text-decoration: none; }
        .admin-shell { min-height: 100vh; display: flex; max-width: 100%; }
        .sg-sidebar {
            position: fixed;
            top: 0;
            left: 0;
            width: 240px;
            height: 100vh;
            flex: 0 0 240px;
            padding: 12px 10px;
            background: linear-gradient(180deg, #FFFFFF 0%, #F8FCFC 100%);
            border-right: 1px solid var(--sgizi-line);
            overflow: hidden;
            z-index: 20;
            display: flex;
            flex-direction: column;
        }

        .sg-brand {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 2px 6px 12px;
            color: var(--sgizi-ink);
        }

        .sg-brand-mark, .sg-avatar, .sg-icon-btn, .sg-letter-avatar {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            flex: 0 0 auto;
        }

        .sg-brand-mark {
            width: 68px;
            height: 68px;
            border-radius: 0;
            background: transparent;
            color: inherit;
            box-shadow: none;
            overflow: hidden;
            border: 0;
        }

        .sg-brand-logo {
            width: 100%;
            height: 100%;
            object-fit: contain;
            padding: 0;
        }

        .sg-nav-label {
            flex: 0 0 auto;
            margin: 8px 10px 6px;
            color: #91A2A7;
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
        }

        .sg-nav-scroll {
            flex: 1 1 auto;
            min-height: 0;
            display: flex;
            flex-direction: column;
            gap: 4px;
            overflow-y: auto;
            overflow-x: hidden;
            padding: 0 2px 8px 0;
            scrollbar-width: thin;
            scrollbar-color: #C8DADA transparent;
        }
        .sg-nav-scroll::-webkit-scrollbar { width: 6px; }
        .sg-nav-scroll::-webkit-scrollbar-thumb { background: #C8DADA; border-radius: 999px; }

        .sg-nav-link {
            display: flex;
            align-items: center;
            gap: 10px;
            min-height: 34px;
            padding: 7px 10px;
            border-radius: 12px;
            color: #577077;
            font-size: 12.5px;
            font-weight: 650;
            transition: .18s ease;
        }

        .sg-nav-link i { font-size: 15px; color: #7D959B; }
        .sg-nav-link:hover, .sg-nav-link.active {
            color: var(--sgizi-deep);
            background: rgba(75, 142, 150, .11);
            transform: translateX(3px);
        }
        .sg-nav-link.active i { color: var(--sgizi); }

        .sg-main { min-width: 0; max-width: calc(100% - 240px); flex: 1; margin-left: 240px; }
        .sidebar-collapsed .sg-sidebar { width: 76px; flex-basis: 76px; }
        .sidebar-collapsed .sg-main { max-width: calc(100% - 76px); margin-left: 76px; }
        .sidebar-collapsed .sg-brand { justify-content: center; padding-left: 0; padding-right: 0; }
        .sidebar-collapsed .sg-brand-mark { width: 54px; height: 54px; }
        .sidebar-collapsed .sg-brand span:not(.sg-brand-mark),
        .sidebar-collapsed .sg-nav-label,
        .sidebar-collapsed .sg-nav-link span { display: none !important; }
        .sidebar-collapsed .sg-nav-link { justify-content: center; }
        .sidebar-collapsed .sg-nav-scroll { padding-right: 0; }
        .sg-topbar {
            position: sticky;
            top: 0;
            z-index: 10;
            min-height: 62px;
            padding: 10px 22px;
            background: rgba(245, 248, 248, .88);
            border-bottom: 1px solid rgba(227, 236, 236, .74);
            backdrop-filter: blur(18px);
        }

        .sg-search {
            max-width: 420px;
            min-height: 40px;
            border: 1px solid var(--sgizi-line);
            border-radius: 14px;
            background: #fff;
            color: var(--sgizi-muted);
            padding: 0 12px;
        }

        .sg-search input {
            border: 0;
            outline: 0;
            width: 100%;
            background: transparent;
            font-size: 13px;
            font-weight: 500;
        }

        .sg-icon-btn {
            width: 40px;
            height: 40px;
            border: 1px solid var(--sgizi-line);
            border-radius: 14px;
            background: #fff;
            color: var(--sgizi-deep);
        }
        .sg-notification-dot {
            position: absolute;
            top: -5px;
            right: -5px;
            min-width: 20px;
            height: 20px;
            padding: 0 5px;
            border-radius: 999px;
            border: 2px solid #fff;
            background: var(--sgizi-red);
            color: #fff;
            font-size: 11px;
            font-weight: 800;
            line-height: 16px;
            text-align: center;
        }
        .sg-notification-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 12px;
            min-width: 260px;
            padding: 8px 10px;
            border-radius: 12px;
            color: var(--sgizi-ink);
        }
        .sg-notification-item:hover { background: #F3F8F8; }

        .sg-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--sgizi), #77C6AC);
            color: #fff;
            font-weight: 800;
        }

        .sg-content { padding: 18px 22px 28px; max-width: 100%; }
        .sg-page-title { font-size: clamp(22px, 2vw, 30px); font-weight: 750; margin: 0; }
        .sg-page-subtitle { color: var(--sgizi-muted); margin: 5px 0 0; font-size: 13px; font-weight: 500; }

        .sg-card {
            background: var(--sgizi-card);
            border: 1px solid rgba(227, 236, 236, .95);
            border-radius: 20px;
            box-shadow: 0 12px 28px rgba(35, 76, 82, .08);
        }

        .sg-stat-card {
            position: relative;
            overflow: hidden;
            min-height: 126px;
            max-height: 150px;
            transition: transform .18s ease, box-shadow .18s ease;
        }
        .sg-stat-card:hover { transform: translateY(-4px); box-shadow: 0 22px 52px rgba(35, 76, 82, .15); }
        .sg-stat-icon {
            width: 40px;
            height: 40px;
            border-radius: 14px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 19px;
        }
        .sg-stat-value { font-size: 28px; font-weight: 750; line-height: 1; }
        .sg-stat-label { color: var(--sgizi-muted); font-size: 11px; font-weight: 600; }
        .sg-trend { font-size: 11px; font-weight: 750; }

        .sg-chip, .sg-status {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            border-radius: 999px;
            padding: 5px 9px;
            font-size: 11px;
            font-weight: 750;
            white-space: nowrap;
        }
        .sg-status-red { color: #A93A3A; background: #FFE5E5; }
        .sg-status-orange { color: #A66019; background: #FFF0DE; }
        .sg-status-yellow { color: #846012; background: #FFF7D8; }
        .sg-status-green { color: #1D7A50; background: #DCF6E9; }
        .sg-status-blue { color: var(--sgizi-deep); background: #E5F4F6; }
        .sg-status-gray { color: #66757B; background: #EEF3F4; }

        .sg-letter-avatar {
            width: 36px;
            height: 36px;
            border-radius: 13px;
            color: #fff;
            background: var(--sgizi);
            font-weight: 800;
        }

        .sg-table { min-width: 0; width: 100%; }
        .sg-table th {
            color: #789096;
            font-size: 11px;
            text-transform: uppercase;
            border-bottom-color: var(--sgizi-line);
            padding: 12px;
        }
        .sg-table td { padding: 12px; vertical-align: middle; border-color: #EDF3F3; }
        .sg-filter-tabs .btn {
            border-radius: 999px;
            border-color: var(--sgizi-line);
            font-size: 12px;
            font-weight: 700;
            color: #60757B;
            background: #fff;
        }
        .sg-filter-tabs .btn.active { background: var(--sgizi); color: #fff; border-color: var(--sgizi); }

        .btn-primary { background: var(--sgizi); border-color: var(--sgizi); }
        .btn-primary:hover { background: var(--sgizi-deep); border-color: var(--sgizi-deep); }
        .btn-outline-primary { color: var(--sgizi); border-color: var(--sgizi); }
        .btn-outline-primary:hover { background: var(--sgizi); border-color: var(--sgizi); }
        .form-control, .form-select { border-radius: 14px; border-color: var(--sgizi-line); padding: 9px 12px; }
        .sg-chart-box { position: relative; height: 240px; max-height: 280px; }
        .sg-chart-box-sm { position: relative; height: 210px; max-height: 240px; }
        .min-w-0 { min-width: 0 !important; }
        .sg-compact-item { min-height: 76px; max-height: 90px; overflow: hidden; }
        .sg-inbox-item {
            height: 78px;
            width: 100%;
            max-width: 100%;
            overflow: hidden;
            border: 1px solid var(--sgizi-line);
            border-radius: 18px;
            padding: 9px;
            background: #fff;
        }
        .sg-inbox-item .sg-letter-avatar {
            width: 32px;
            height: 32px;
            border-radius: 12px;
            font-size: 14px;
        }
        .sg-inbox-title,
        .sg-inbox-meta,
        .sg-inbox-message {
            display: block;
            max-width: 100%;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .sg-inbox-title { font-size: 12.5px; line-height: 1.15; }
        .sg-inbox-meta, .sg-inbox-message { font-size: 11.5px; line-height: 1.22; }
        .sg-inbox-status { padding: 3px 7px; font-size: 9.5px; line-height: 1; }
        .sg-inbox-action { flex-shrink: 0; align-self: flex-start; }
        .sg-filter-scroll {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            max-width: 100%;
        }
        .sg-monitor-card {
            height: 100%;
            min-width: 0;
            overflow: hidden;
        }
        .sg-mini-metric {
            border: 1px solid var(--sgizi-line);
            border-radius: 16px;
            padding: 10px 12px;
            background: #FAFDFD;
        }
        .sg-who-row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            min-width: 0;
            padding: 7px 0;
            border-bottom: 1px solid #EFF5F5;
        }
        .sg-who-row:last-child { border-bottom: 0; }
        .sg-action-grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0, 1fr));
            gap: 6px;
        }
        .sg-action-grid .btn {
            padding: 6px 8px;
            font-size: 11px;
            font-weight: 700;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .sg-consult-grid {
            display: grid;
            grid-template-columns: minmax(236px, 26%) minmax(380px, 1fr) minmax(260px, 25%);
            gap: 12px;
            align-items: stretch;
            max-width: 100%;
            min-height: calc(100vh - 205px);
        }
        .sg-consult-panel { height: calc(100vh - 205px); min-height: 520px; }
        .sg-consult-list {
            max-height: calc(100vh - 330px);
            overflow-y: auto;
            overflow-x: hidden;
            padding-right: 2px;
        }
        .sg-consult-list::-webkit-scrollbar,
        .sg-monitor-chat::-webkit-scrollbar { width: 7px; }
        .sg-consult-list::-webkit-scrollbar-thumb,
        .sg-monitor-chat::-webkit-scrollbar-thumb {
            background: #C8DADA;
            border-radius: 999px;
        }
        .sg-consult-room {
            width: 100%;
            border: 1px solid var(--sgizi-line);
            background: #fff;
            border-radius: 16px;
            padding: 9px;
            color: var(--sgizi-ink);
        }
        .sg-consult-room .sg-letter-avatar {
            width: 34px;
            height: 34px;
            border-radius: 12px;
        }
        .sg-consult-room.active {
            border-color: rgba(75, 142, 150, .55);
            background: #F2FAFA;
        }
        .sg-readonly-banner {
            background: #EAF7F5;
            border: 1px solid #CFE9E6;
            border-radius: 18px;
            padding: 12px;
        }
        .sg-monitor-chat {
            height: calc(100vh - 274px);
            min-height: 418px;
            overflow-y: auto;
            overflow-x: hidden;
            background: #F8FBFB;
        }
        .sg-message-row { display: flex; margin-bottom: 10px; }
        .sg-message-row.expert { justify-content: flex-end; }
        .sg-message-bubble {
            max-width: min(76%, 520px);
            padding: 10px 12px;
            border-radius: 16px;
            background: #fff;
            border: 1px solid #E8F0F0;
            box-shadow: 0 8px 18px rgba(35, 76, 82, .06);
            overflow-wrap: anywhere;
            word-break: break-word;
            font-size: 13px;
            line-height: 1.42;
        }
        .sg-message-row.expert .sg-message-bubble {
            background: #4B8E96;
            border-color: #4B8E96;
            color: #fff;
        }
        .sg-message-meta {
            font-size: 10.5px;
            opacity: .72;
            margin-bottom: 4px;
        }
        .sg-update-card {
            border: 1px dashed #BBDDDD;
            background: #F1FAF8;
            border-radius: 16px;
            padding: 10px;
            margin: 0 0 12px;
        }
        .sg-mini-chart {
            width: 100%;
            height: 92px;
        }
        .sg-history-line {
            display: flex;
            justify-content: space-between;
            gap: 10px;
            padding: 7px 0;
            border-bottom: 1px solid #EFF5F5;
            font-size: 12px;
        }
        .sg-history-line:last-child { border-bottom: 0; }
        .sg-family-row {
            display: grid;
            grid-template-columns: minmax(220px, 1.4fr) minmax(120px, .7fr) minmax(130px, .8fr) minmax(130px, .8fr) minmax(120px, .7fr) 44px;
            gap: 12px;
            align-items: center;
            padding: 12px;
            border: 1px solid var(--sgizi-line);
            border-radius: 18px;
            background: #fff;
            transition: .18s ease;
        }
        .sg-family-row:hover {
            border-color: rgba(75, 142, 150, .45);
            box-shadow: 0 12px 24px rgba(35, 76, 82, .08);
        }
        .sg-family-label {
            display: none;
            color: var(--sgizi-muted);
            font-size: 11px;
            font-weight: 700;
        }
        .sg-skeleton {
            position: relative;
            overflow: hidden;
            background: #edf4f4;
            border-radius: 14px;
            min-height: 76px;
        }
        .sg-skeleton::after {
            content: "";
            position: absolute;
            inset: 0;
            transform: translateX(-100%);
            background: linear-gradient(90deg, transparent, rgba(255,255,255,.65), transparent);
            animation: sg-shimmer 1.15s infinite;
        }
        @keyframes sg-shimmer { 100% { transform: translateX(100%); } }

        .dropdown-menu { border: 1px solid var(--sgizi-line); border-radius: 16px; box-shadow: var(--sgizi-shadow); }
        .pagination { --bs-pagination-active-bg: var(--sgizi); --bs-pagination-active-border-color: var(--sgizi); }
        .sg-confirm-backdrop {
            position: fixed;
            inset: 0;
            z-index: 2000;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 18px;
            background: rgba(20, 37, 43, .46);
            backdrop-filter: blur(8px);
        }
        .sg-confirm-backdrop.show { display: flex; }
        .sg-confirm-dialog {
            width: min(430px, 100%);
            background: #fff;
            border: 1px solid rgba(75, 142, 150, .18);
            border-radius: 24px;
            box-shadow: 0 28px 80px rgba(20, 37, 43, .24);
            padding: 22px;
            transform: translateY(10px) scale(.98);
            opacity: 0;
            transition: .18s ease;
        }
        .sg-confirm-backdrop.show .sg-confirm-dialog { transform: translateY(0) scale(1); opacity: 1; }
        .sg-confirm-icon {
            width: 48px;
            height: 48px;
            border-radius: 18px;
            display: grid;
            place-items: center;
            color: var(--sgizi);
            background: #E5F4F6;
            font-size: 24px;
        }
        .sg-confirm-title { font-size: 20px; font-weight: 760; margin: 14px 0 6px; }
        .sg-confirm-message { color: var(--sgizi-muted); font-size: 13px; line-height: 1.55; margin: 0; }
        .sg-confirm-actions { display: flex; justify-content: flex-end; gap: 8px; margin-top: 20px; }
        .sg-confirm-actions .btn { border-radius: 999px; padding: 8px 16px; font-weight: 750; }
        .sg-reject-textarea {
            width: 100%;
            min-height: 118px;
            margin-top: 14px;
            border: 1px solid rgba(75, 142, 150, .22);
            border-radius: 16px;
            padding: 12px 14px;
            resize: vertical;
            outline: none;
        }
        .sg-reject-textarea:focus { border-color: var(--sgizi); box-shadow: 0 0 0 4px rgba(75, 142, 150, .10); }
        .sg-reject-error { display: none; margin-top: 8px; color: #A93A3A; font-size: 12px; font-weight: 700; }
        .sg-reject-error.show { display: block; }

        @media (max-width: 1199.98px) {
            .sg-sidebar { width: 218px; flex-basis: 218px; }
            .sg-main { max-width: calc(100% - 218px); margin-left: 218px; }
            .sg-content { padding: 16px 18px 24px; }
        }

        @media (max-width: 991.98px) {
            .admin-shell { display: block; }
            .sg-main { max-width: 100%; margin-left: 0; }
            .sidebar-collapsed .sg-main { max-width: 100%; margin-left: 0; }
            .sg-sidebar {
                position: relative;
                width: 100%;
                height: auto;
                display: block;
                padding: 12px;
                overflow: visible;
                border-right: 0;
                border-bottom: 1px solid var(--sgizi-line);
            }
            .sg-brand { padding-bottom: 12px; }
            .sg-nav-scroll {
                display: flex;
                flex-direction: row;
                gap: 8px;
                overflow-x: auto;
                overflow-y: hidden;
                padding-bottom: 4px;
                scrollbar-width: none;
            }
            .sg-nav-scroll::-webkit-scrollbar { display: none; }
            .sg-filter-scroll {
                flex-wrap: nowrap;
                overflow-x: auto;
                padding-bottom: 4px;
                scrollbar-width: none;
            }
            .sg-filter-scroll::-webkit-scrollbar { display: none; }
            .sg-nav-label { display: none; }
            .sg-nav-link { min-width: max-content; }
            .sg-nav-link:hover, .sg-nav-link.active { transform: translateY(-1px); }
            .sg-topbar { position: relative; padding: 10px 14px; }
            .sg-content { padding: 16px 14px 26px; }
            .sg-consult-grid {
                grid-template-columns: minmax(220px, 32%) minmax(0, 1fr);
                min-height: auto;
            }
            .sg-consult-panel { height: auto; min-height: 0; }
            .sg-consult-list { max-height: 520px; }
            .sg-consult-detail {
                grid-column: 2;
            }
            .sg-family-row {
                grid-template-columns: repeat(2, minmax(0, 1fr));
            }
            .sg-family-actions { grid-column: 1 / -1; }
            .sg-family-label { display: block; }
        }

        @media (max-width: 767.98px) {
            .sg-topbar .sg-search { display: none !important; }
            .sg-page-title { font-size: 25px; }
            .sg-table thead { display: none; }
            .sg-table tr { display: block; border-bottom: 1px solid var(--sgizi-line); }
            .sg-table td { display: flex; justify-content: space-between; gap: 12px; border: 0; }
            .sg-action-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .sg-consult-grid { display: block; }
            .sg-consult-grid > * { margin-bottom: 12px; }
            .sg-monitor-chat { height: 420px; }
            .sg-message-bubble { max-width: 88%; }
            .sg-family-row { display: block; }
            .sg-family-row > * { margin-bottom: 10px; }
            .sg-family-row > *:last-child { margin-bottom: 0; }
        }
    </style>
    {{ $styles ?? '' }}
</head>
<body>
<div class="admin-shell">
    <aside class="sg-sidebar">
        <a class="sg-brand" href="{{ route('admin.dashboard') }}">
            <span class="sg-brand-mark">
                <img class="sg-brand-logo" src="{{ asset('assets/logo_sgizi.png') }}" alt="Logo S-Gizi">
            </span>
            <span>
                <span class="d-block fw-bold fs-5">S-Gizi</span>
                <span class="d-block small text-muted fw-semibold">Monitoring Gizi</span>
            </span>
        </a>

        <div class="sg-nav-label">Menu Admin</div>
        <nav class="sg-nav-scroll">
            @foreach ($navItems as $item)
                @php($isActive = request()->routeIs($item['route']) || request()->routeIs(str_replace('.index', '.*', $item['route'])))
                <a class="sg-nav-link {{ $isActive ? 'active' : '' }}" href="{{ Route::has($item['route']) ? route($item['route']) : '#' }}" title="{{ $item['label'] }}">
                    <i class="bi {{ $item['icon'] }}"></i>
                    <span>{{ $item['label'] }}</span>
                </a>
            @endforeach
            @if (Route::has('admin.logout'))
                <form method="post" action="{{ route('admin.logout') }}" data-confirm="Logout dari website admin?">
                    @csrf
                    <button class="sg-nav-link border-0 w-100 bg-transparent" type="submit">
                        <i class="bi bi-box-arrow-right"></i>
                        <span>Logout</span>
                    </button>
                </form>
            @endif
        </nav>
    </aside>

    <div class="sg-main">
        <header class="sg-topbar d-flex align-items-center gap-3">
            <button class="sg-icon-btn d-none d-lg-inline-flex" id="sidebarToggle" type="button" title="Ciutkan sidebar">
                <i class="bi bi-layout-sidebar-inset"></i>
            </button>

            <div class="dropdown ms-auto">
                <button class="sg-icon-btn position-relative" data-bs-toggle="dropdown" type="button" title="Permintaan verifikasi">
                    <i class="bi bi-bell"></i>
                    @if ($pendingVerifications > 0)
                        <span class="sg-notification-dot">{{ $pendingVerifications > 99 ? '99+' : $pendingVerifications }}</span>
                    @endif
                </button>
                <div class="dropdown-menu dropdown-menu-end p-2">
                    <div class="px-2 py-1">
                        <div class="fw-semibold">Permintaan Verifikasi</div>
                        <div class="small text-muted">{{ $pendingVerifications }} item menunggu persetujuan</div>
                    </div>
                    <div class="dropdown-divider"></div>
                    <a class="sg-notification-item" href="{{ route('admin.foods.index', ['filter' => 'Menunggu Verifikasi']) }}">
                        <span><i class="bi bi-egg-fried me-2"></i>Rekomendasi Makanan</span>
                        <span class="sg-status sg-status-orange">{{ $pendingFoodVerifications }}</span>
                    </a>
                    <a class="sg-notification-item" href="{{ route('admin.articles.index', ['filter' => 'Menunggu Verifikasi']) }}">
                        <span><i class="bi bi-newspaper me-2"></i>Artikel</span>
                        <span class="sg-status sg-status-orange">{{ $pendingArticleVerifications }}</span>
                    </a>
                </div>
            </div>

            <div class="dropdown">
                <button class="border-0 bg-transparent d-flex align-items-center gap-2 p-0" data-bs-toggle="dropdown" type="button">
                    <span class="sg-avatar">{{ $adminInitials }}</span>
                    <span class="d-none d-md-block text-start">
                        <span class="d-block fw-bold">{{ $adminUser?->name ?? 'Admin S-Gizi' }}</span>
                        <span class="d-block small text-muted">{{ $adminRoleLabel }}</span>
                    </span>
                    <i class="bi bi-chevron-down small text-muted"></i>
                </button>
                <div class="dropdown-menu dropdown-menu-end p-2">
                    <a class="dropdown-item rounded-3" href="{{ Route::has('admin.settings') ? route('admin.settings') : '#' }}">Profil Admin</a>
                    <a class="dropdown-item rounded-3" href="{{ Route::has('admin.settings') ? route('admin.settings') : '#' }}">Pengaturan</a>
                    <div class="dropdown-divider"></div>
                    @if (Route::has('admin.logout'))
                        <form method="post" action="{{ route('admin.logout') }}" data-confirm="Logout dari website admin?">
                            @csrf
                            <button class="dropdown-item rounded-3 text-danger" type="submit">Logout</button>
                        </form>
                    @endif
                </div>
            </div>
        </header>

        <main class="sg-content">
            @if (session('success'))
                <div class="alert alert-success border-0 rounded-4 shadow-sm sg-auto-alert">{{ session('success') }}</div>
            @endif
            @if (session('warning'))
                <div class="alert alert-warning border-0 rounded-4 shadow-sm sg-auto-alert">{{ session('warning') }}</div>
            @endif
            @if ($errors->any())
                <div class="alert alert-danger border-0 rounded-4 shadow-sm sg-auto-alert">
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
    </div>
</div>

<div class="sg-confirm-backdrop" id="sgConfirm" aria-hidden="true">
    <div class="sg-confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="sgConfirmTitle">
        <div class="sg-confirm-icon"><i class="bi bi-shield-check"></i></div>
        <h5 class="sg-confirm-title" id="sgConfirmTitle">Konfirmasi Aksi</h5>
        <p class="sg-confirm-message" id="sgConfirmMessage">Lanjutkan aksi ini?</p>
        <div class="sg-confirm-actions">
            <button class="btn btn-outline-secondary" id="sgConfirmCancel" type="button">Batal</button>
            <button class="btn btn-primary" id="sgConfirmOk" type="button">Ya, lanjutkan</button>
        </div>
    </div>
</div>

<div class="sg-confirm-backdrop" id="sgRejectModal" aria-hidden="true">
    <div class="sg-confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="sgRejectTitle">
        <div class="sg-confirm-icon" style="color:#A93A3A;background:#FFE5E5"><i class="bi bi-x-circle"></i></div>
        <h5 class="sg-confirm-title" id="sgRejectTitle">Tolak Pengajuan</h5>
        <p class="sg-confirm-message" id="sgRejectMessage">Tulis alasan penolakan agar ahli gizi bisa memperbaiki kontennya.</p>
        <textarea class="sg-reject-textarea" id="sgRejectInput" placeholder="Contoh: Kandungan gizi belum lengkap atau sumber artikel perlu ditambahkan."></textarea>
        <div class="sg-reject-error" id="sgRejectError">Alasan penolakan wajib diisi.</div>
        <div class="sg-confirm-actions">
            <button class="btn btn-outline-secondary" id="sgRejectCancel" type="button">Batal</button>
            <button class="btn btn-danger" id="sgRejectOk" type="button">Tolak Pengajuan</button>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
    document.getElementById('sidebarToggle')?.addEventListener('click', () => {
        document.body.classList.toggle('sidebar-collapsed');
    });

    document.querySelectorAll('.sg-auto-alert').forEach((alert) => {
        window.setTimeout(() => {
            alert.style.transition = 'opacity .24s ease, transform .24s ease';
            alert.style.opacity = '0';
            alert.style.transform = 'translateY(-6px)';
            window.setTimeout(() => alert.remove(), 260);
        }, 3000);
    });

    document.addEventListener('click', (event) => {
        const button = event.target.closest('[data-password-toggle]');
        if (!button) return;

        const group = button.closest('.input-group');
        const input = group?.querySelector('input[type="password"], input[type="text"]');
        const icon = button.querySelector('i');
        if (!input) return;

        const shouldShow = input.type === 'password';
        input.type = shouldShow ? 'text' : 'password';
        button.setAttribute('aria-label', shouldShow ? 'Sembunyikan password' : 'Tampilkan password');
        if (icon) {
            icon.classList.toggle('bi-eye', !shouldShow);
            icon.classList.toggle('bi-eye-slash', shouldShow);
        }
    });

    const sgConfirm = (() => {
        const backdrop = document.getElementById('sgConfirm');
        const title = document.getElementById('sgConfirmTitle');
        const message = document.getElementById('sgConfirmMessage');
        const ok = document.getElementById('sgConfirmOk');
        const cancel = document.getElementById('sgConfirmCancel');
        let resolveConfirm = null;

        const close = (value) => {
            backdrop.classList.remove('show');
            backdrop.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
            if (resolveConfirm) resolveConfirm(value);
            resolveConfirm = null;
        };

        ok.addEventListener('click', () => close(true));
        cancel.addEventListener('click', () => close(false));
        backdrop.addEventListener('click', (event) => {
            if (event.target === backdrop) close(false);
        });
        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape' && backdrop.classList.contains('show')) close(false);
        });

        return (text, heading = 'Konfirmasi Aksi') => new Promise((resolve) => {
            resolveConfirm = resolve;
            title.textContent = heading;
            message.textContent = text || 'Lanjutkan aksi ini?';
            backdrop.classList.add('show');
            backdrop.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
            ok.focus();
        });
    })();

    const sgRejectReason = (() => {
        const backdrop = document.getElementById('sgRejectModal');
        const input = document.getElementById('sgRejectInput');
        const error = document.getElementById('sgRejectError');
        const ok = document.getElementById('sgRejectOk');
        const cancel = document.getElementById('sgRejectCancel');
        let resolveReject = null;

        const close = (value) => {
            backdrop.classList.remove('show');
            backdrop.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
            if (resolveReject) resolveReject(value);
            resolveReject = null;
        };

        ok.addEventListener('click', () => {
            const value = input.value.trim();
            if (!value) {
                error.classList.add('show');
                input.focus();
                return;
            }
            close(value);
        });
        cancel.addEventListener('click', () => close(null));
        backdrop.addEventListener('click', (event) => {
            if (event.target === backdrop) close(null);
        });

        return () => new Promise((resolve) => {
            resolveReject = resolve;
            input.value = '';
            error.classList.remove('show');
            backdrop.classList.add('show');
            backdrop.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
            setTimeout(() => input.focus(), 30);
        });
    })();

    document.addEventListener('submit', async (event) => {
        const form = event.target;
        if (!(form instanceof HTMLFormElement)) return;
        if (!form.classList.contains('sg-reject-form')) return;
        if (form.dataset.confirmed === '1') return;

        event.preventDefault();
        event.stopImmediatePropagation();
        const reason = await sgRejectReason();
        if (!reason) return;

        form.querySelector('input[name="rejection_reason"]').value = reason;
        form.dataset.confirmed = '1';
        form.requestSubmit(event.submitter || undefined);
    }, true);

    document.addEventListener('submit', async (event) => {
        const form = event.target;
        if (!(form instanceof HTMLFormElement)) return;
        if (form.dataset.confirmed === '1') return;
        if (form.classList.contains('sg-reject-form')) return;
        if ((form.getAttribute('method') || 'get').toLowerCase() === 'get') return;
        if (form.hasAttribute('onsubmit')) return;

        const methodInput = form.querySelector('input[name="_method"]');
        const method = (methodInput?.value || form.getAttribute('method') || 'post').toUpperCase();
        const action = (form.getAttribute('action') || '').toLowerCase();
        const submitter = event.submitter;
        const submitText = (submitter?.innerText || submitter?.textContent || '').trim().toLowerCase();

        let message = form.dataset.confirm || '';
        if (!message && action.includes('logout')) {
            message = 'Logout dari website admin?';
        }
        if (!message && (method === 'DELETE' || submitText.includes('hapus'))) {
            message = 'Yakin ingin menghapus data ini?';
        }
        if (!message && (submitText.includes('arsipkan') || action.includes('nonaktifkan') || submitText.includes('nonaktifkan'))) {
            message = submitText.includes('arsipkan') ? 'Yakin ingin mengarsipkan data ini?' : 'Yakin ingin menonaktifkan data ini?';
        }
        if (!message && ['PUT', 'PATCH'].includes(method)) {
            message = 'Simpan perubahan data ini?';
        }

        if (!message) return;

        event.preventDefault();
        const ok = await sgConfirm(message);
        if (!ok) return;

        form.dataset.confirmed = '1';
        form.requestSubmit(submitter || undefined);
    });

    document.addEventListener('click', async (event) => {
        const link = event.target.closest('a');
        if (!link) return;
        if (link.dataset.confirmed === '1') return;
        if (link.hasAttribute('data-bs-toggle')) return;

        const href = (link.getAttribute('href') || '').toLowerCase();
        const text = (link.innerText || link.textContent || '').trim().toLowerCase();
        const isEdit = text === 'edit' || text.includes(' edit') || href.includes('/edit') || href.includes('edit=');
        if (!isEdit) return;

        event.preventDefault();
        const ok = await sgConfirm('Buka halaman edit data ini?', 'Buka Edit Data');
        if (!ok) return;
        link.dataset.confirmed = '1';
        window.location.href = link.href;
    });
</script>
{{ $scripts ?? '' }}
</body>
</html>
