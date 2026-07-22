<x-nutritionist-layout title="Notifikasi">
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div><h1 class="page-title">Notifikasi</h1><p class="page-subtitle">Informasi penting dari konsultasi yang Anda tangani.</p></div>
        <form method="post" action="{{ route('nutritionist.notifications.read_all') }}">@csrf<button class="btn btn-outline-primary rounded-pill">Tandai Semua Dibaca</button></form>
    </div>
    <div class="sg-card p-3 mb-4 d-flex flex-wrap gap-2">
        @foreach ($filters as $item)
            <a class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" href="{{ route('nutritionist.notifications', ['filter' => $item]) }}">{{ $item }}</a>
        @endforeach
    </div>
    <div class="sg-card p-3">
        <div class="vstack gap-2">
            @forelse ($notifications as $notification)
                <div class="border rounded-4 p-3 d-flex flex-wrap justify-content-between gap-3">
                    <div>
                        <div class="d-flex flex-wrap gap-2 align-items-center"><strong>{{ $notification->title }}</strong><span class="badge-soft {{ $notification->is_read ? 'risk-neutral' : 'risk-watch' }}">{{ $notification->is_read ? 'Dibaca' : 'Belum dibaca' }}</span><span class="badge-soft risk-neutral">{{ $notification->priority }}</span></div>
                        <div class="text-muted">{{ $notification->description }}</div>
                        <div class="small text-muted">{{ $notification->child?->nama ?? '-' }} • {{ $notification->room?->user?->name ?? '-' }} • {{ $notification->created_at?->diffForHumans() }}</div>
                    </div>
                    <form method="post" action="{{ route('nutritionist.notifications.read', $notification) }}">@csrf<button class="btn btn-sm btn-primary rounded-pill">Buka Konsultasi</button></form>
                </div>
            @empty
                <div class="text-center text-muted py-5">Belum ada notifikasi.</div>
            @endforelse
        </div>
    </div>
    <div class="mt-3">{{ $notifications->links('pagination::bootstrap-5') }}</div>
</x-nutritionist-layout>
