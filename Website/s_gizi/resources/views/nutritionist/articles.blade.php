<x-nutritionist-layout title="Artikel">
    @php
        $articleForm = $editingArticle;
        $isEdit = (bool) $articleForm;
        $tagSuggestions = ['MPASI', 'Protein Tinggi', 'Stunting', 'ASI', 'Obesitas', 'Gizi Kurang'];
        $statusClass = fn ($status) => match ($status) {
            'Published' => 'sg-status-green',
            'Draft', 'Menunggu Verifikasi' => 'sg-status-orange',
            'Ditolak' => 'sg-status-red',
            'Archived' => 'sg-status-gray',
            default => 'sg-status-blue',
        };
    @endphp
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div class="d-flex align-items-center gap-3">
            <span class="module-icon"><i class="bi bi-newspaper"></i></span>
            <div><h1 class="page-title">Artikel Edukasi</h1><p class="page-subtitle">Artikel dikelola admin; ahli gizi dapat membaca dan membagikan ke chat.</p></div>
        </div>
    </div>
    <section class="row g-2 mb-4">
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Total Artikel</span><strong>{{ number_format($articleSummary['total']) }}</strong></div></div>
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Dipublikasikan</span><strong class="text-success">{{ number_format($articleSummary['published']) }}</strong></div></div>
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Menunggu Verifikasi</span><strong class="text-warning">{{ number_format($articleSummary['pending']) }}</strong></div></div>
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Draft</span><strong class="text-primary">{{ number_format($articleSummary['draft']) }}</strong></div></div>
    </section>
    @if ($mode === 'manage')
    <div class="sg-card p-4 mb-4">
        <div class="d-flex justify-content-between align-items-center gap-2 mb-3">
            <h5 class="fw-bold mb-0">{{ $isEdit ? 'Edit Artikel' : 'Tambah Artikel' }}</h5>
            @if ($isEdit)<a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('nutritionist.articles.manage') }}">Buat Baru</a>@endif
        </div>
        <form method="post" action="{{ $isEdit ? route('nutritionist.articles.update', $articleForm) : route('nutritionist.articles.store') }}" enctype="multipart/form-data" class="row g-3">
            @csrf
            @if ($isEdit) @method('PUT') @endif
            <div class="col-md-4"><label class="form-label">Thumbnail</label><input class="form-control" type="file" name="thumbnail" accept="image/*"></div>
            <div class="col-md-5"><label class="form-label">Judul</label><input class="form-control" name="title" value="{{ old('title', $articleForm?->title) }}" required></div>
            <div class="col-md-3"><label class="form-label">Kategori</label><select class="form-select" name="category">@foreach (['Stunting','Gizi balita','MPASI','Pola makan anak','Pertumbuhan anak','Pencegahan stunting','Kesehatan anak'] as $item)<option @selected(old('category', $articleForm?->category) === $item)>{{ $item }}</option>@endforeach</select></div>
            <div class="col-md-6"><label class="form-label">Ringkasan</label><input class="form-control" name="excerpt" value="{{ old('excerpt', $articleForm?->excerpt) }}"></div>
            <div class="col-md-6">
                <label class="form-label">Tag</label>
                <input id="articleTagsInput" class="form-control" name="tags_input" value="{{ old('tags_input', implode(', ', $articleForm?->tags ?? [])) }}" placeholder="MPASI, Stunting">
                <div class="d-flex flex-wrap gap-1 mt-2">
                    @foreach ($tagSuggestions as $tag)
                        <button class="btn btn-sm btn-outline-primary rounded-pill article-tag-suggestion" type="button">{{ $tag }}</button>
                    @endforeach
                </div>
            </div>
            <div class="col-12"><label class="form-label">Isi Artikel</label><textarea class="form-control" name="content" rows="6" required>{{ old('content', $articleForm?->content) }}</textarea></div>
            <div class="col-12 d-flex justify-content-end gap-2"><button class="btn btn-outline-primary rounded-pill px-4" name="action" value="draft">Simpan Draft</button><button class="btn btn-primary rounded-pill px-4" name="action" value="submit">Ajukan ke Admin</button></div>
        </form>
    </div>
    @endif
    <form class="sg-card p-3 mb-4" method="get">
        @if ($roomId) <input type="hidden" name="room" value="{{ $roomId }}"> @endif
        <div class="row g-2 align-items-end">
            <div class="col-md-4"><label class="form-label fw-semibold text-muted">Cari Artikel</label><input class="form-control" name="q" value="{{ $q }}" placeholder="Cari judul atau ringkasan"></div>
            <div class="col-md-3"><label class="form-label fw-semibold text-muted">Kategori</label><select class="form-select" name="category"><option>Semua</option>@foreach ($categories as $item)<option @selected($category === $item)>{{ $item }}</option>@endforeach</select></div>
            @if ($mode === 'manage')
                <div class="col-md-3"><label class="form-label fw-semibold text-muted">Arsip</label><select class="form-select" name="archive">@foreach ($archives as $value => $label)<option value="{{ $value }}" @selected($archive === $value)>{{ $label }}</option>@endforeach</select></div>
            @endif
            <div class="col-md-2"><button class="btn btn-primary rounded-4 w-100">Terapkan</button></div>
        </div>
    </form>
    <div class="row g-3">
        @forelse ($articles as $article)
            <div class="col-md-6 col-xl-4">
                <div class="sg-card article-card h-100">
                    <div class="article-thumb">
                        @if ($article->thumbnail)
                            <img src="{{ asset($article->thumbnail) }}" alt="{{ $article->title }}">
                        @else
                            <i class="bi bi-newspaper"></i>
                        @endif
                    </div>
                    <div class="p-4">
                    <div class="d-flex flex-wrap gap-2 mb-2">
                        <span class="sg-status sg-status-blue">{{ $article->category }}</span>
                        <span class="sg-status {{ $statusClass($article->status) }}">{{ $article->status ?? 'Published' }}</span>
                    </div>
                    <h5 class="fw-bold">{{ $article->title }}</h5>
                    <p class="text-muted">{{ $article->excerpt ?: \Illuminate\Support\Str::limit(strip_tags($article->content), 170) }}</p>
                    <div class="d-flex flex-wrap gap-1 mb-3">@foreach (($article->tags ?? []) as $tag)<span class="sg-chip">{{ $tag }}</span>@endforeach</div>
                    @if (($article->status ?? null) === 'Ditolak' && $article->rejection_reason)
                        <div class="rejection-box mb-3">
                            <strong><i class="bi bi-info-circle me-1"></i>Alasan ditolak</strong>
                            <p>{{ $article->rejection_reason }}</p>
                        </div>
                    @endif
                    <div class="small text-muted mb-3">{{ $article->published_at?->format('d/m/Y') ?? $article->created_at?->format('d/m/Y') }} • {{ $article->status ?? 'Published' }}</div>
                    @if ($mode === 'send')
                    <form class="article-send-form" method="post" action="{{ route('nutritionist.consultations.articles.share', $roomId ?: ($rooms->first()?->id ?? 0)) }}">
                        @csrf
                        <input type="hidden" name="article_id" value="{{ $article->id }}">
                        @unless ($roomId)
                            <input class="form-control form-control-sm mb-2 chat-picker" list="articleRoomOptions-{{ $article->id }}" placeholder="Ketik nama anak/orang tua" autocomplete="off" required>
                            <datalist id="articleRoomOptions-{{ $article->id }}">
                                @foreach ($rooms as $room)<option data-room-id="{{ $room->id }}" value="{{ $room->child?->nama }} - {{ $room->user?->name }}"></option>@endforeach
                            </datalist>
                        @endunless
                        <textarea class="form-control mb-2" name="manual_note" rows="2" placeholder="Catatan saat membagikan"></textarea>
                        <button class="btn btn-primary rounded-pill" @disabled(! $roomId && $rooms->isEmpty())>Bagikan ke Chat</button>
                    </form>
                    @else
                        <div class="d-flex flex-wrap gap-2">
                            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('nutritionist.articles.manage', ['edit' => $article->id]) }}"><i class="bi bi-pencil"></i> Edit</a>
                            @unless (($article->status ?? 'Published') === 'Archived')
                                <form method="post" action="{{ route('nutritionist.articles.archive', $article) }}" data-confirm="Arsipkan artikel ini?">@csrf @method('PATCH')<button class="btn btn-sm btn-outline-warning rounded-pill"><i class="bi bi-archive"></i> Arsipkan</button></form>
                            @endunless
                            <span class="sg-status {{ $statusClass($article->status) }}">{{ $article->status }}</span>
                        </div>
                    @endif
                    </div>
                </div>
            </div>
        @empty
            <div class="col-12"><div class="sg-card p-5 text-center text-muted"><div class="empty-icon mx-auto mb-3"><i class="bi bi-newspaper"></i></div>Belum ada artikel.</div></div>
        @endforelse
    </div>
    <div class="mt-3">{{ $articles->links('pagination::bootstrap-5') }}</div>
    <x-slot:scripts>
        <style>
            .module-icon, .empty-icon { width:58px; height:58px; border-radius:18px; display:grid; place-items:center; background:#E8F6F6; color:#0F8B8D; font-size:27px; flex:0 0 auto; }
            .empty-icon { width:72px; height:72px; border-radius:24px; font-size:34px; }
            .article-card { overflow:hidden; transition:.18s ease; }
            .article-card:hover { transform:translateY(-2px); box-shadow:0 18px 38px rgba(15,139,141,.12); }
            .article-thumb { height:152px; background:#EAF6F4; display:grid; place-items:center; color:#0F8B8D; font-size:38px; overflow:hidden; }
            .article-thumb img { width:100%; height:100%; object-fit:cover; }
            .sg-chip { display:inline-flex; padding:4px 9px; border-radius:999px; background:#EAF6F4; color:#2f7580; font-size:11.5px; font-weight:700; }
            .rejection-box { border:1px solid #F4B4B4; border-radius:14px; background:#FDECEC; color:#A93A3A; padding:10px 12px; }
            .rejection-box strong { display:block; font-size:12px; margin-bottom:4px; }
            .rejection-box p { margin:0; font-size:12.5px; line-height:1.45; }
        </style>
        <script>
            const articleTagsInput = document.getElementById('articleTagsInput');
            document.querySelectorAll('.article-tag-suggestion').forEach((button) => {
                button.addEventListener('click', () => {
                    if (!articleTagsInput) return;
                    const current = articleTagsInput.value.split(',').map((tag) => tag.trim()).filter(Boolean);
                    const value = button.textContent.trim();
                    if (!current.includes(value)) current.push(value);
                    articleTagsInput.value = current.join(', ');
                    articleTagsInput.focus();
                });
            });
            document.querySelectorAll('.article-send-form').forEach((form) => {
                form.addEventListener('submit', (event) => {
                    const picker = form.querySelector('.chat-picker');
                    if (!picker) return;
                    const options = [...form.querySelectorAll('datalist option')];
                    const match = options.find(option => option.value === picker.value);
                    if (!match?.dataset.roomId) {
                        event.preventDefault();
                        picker.setCustomValidity('Pilih chat dari daftar.');
                        picker.reportValidity();
                        return;
                    }
                    picker.setCustomValidity('');
                    form.action = `{{ url('/nutritionist/konsultasi') }}/${match.dataset.roomId}/artikel`;
                });
            });
        </script>
    </x-slot:scripts>
</x-nutritionist-layout>
