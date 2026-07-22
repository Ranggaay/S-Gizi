<x-admin-layout :title="'Artikel'">
    @php
        $article = $editingArticle;
        $isEdit = (bool) $article;
        $filters = ['Semua', 'Menunggu Verifikasi', 'Dari Ahli Gizi', 'Published', 'Draft', 'Ditolak', 'Archived', 'Edukasi Gizi', 'MPASI', 'Stunting', 'Obesitas'];
        $categories = ['Edukasi Gizi', 'MPASI', 'Stunting', 'Obesitas', 'ASI', 'Gizi Kurang'];
        $defaultTags = ['MPASI', 'Protein Tinggi', 'Stunting', 'ASI', 'Obesitas', 'Gizi Kurang'];
        $statusClass = fn ($status) => match ($status) {
            'Published' => 'sg-status-green',
            'Menunggu Verifikasi', 'Draft' => 'sg-status-orange',
            'Ditolak' => 'sg-status-red',
            'Archived' => 'sg-status-gray',
            default => 'sg-status-gray',
        };
    @endphp

    <div id="articleSkeleton" class="row g-3 mb-3">
        <div class="col-lg-7"><div class="sg-skeleton" style="min-height:140px"></div></div>
        <div class="col-lg-5"><div class="sg-skeleton" style="min-height:140px"></div></div>
    </div>

    <div id="articleContent" class="d-none">
        @if ($errors->any())
            <div class="alert alert-danger rounded-4 border-0">
                <strong>Artikel belum bisa disimpan.</strong>
                <div class="small mt-1">{{ $errors->first() }}</div>
            </div>
        @endif

        <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-2">
            <div>
                <h1 class="sg-page-title">Artikel</h1>
                <p class="sg-page-subtitle">CMS edukasi kesehatan anak dan gizi untuk publikasi ke aplikasi mobile.</p>
            </div>
        </div>

        <section class="row g-2 mb-3 sg-article-summary">
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Total Artikel</div><div class="fs-4 fw-semibold">{{ number_format($summary['total']) }}</div></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Published</div><div class="fs-4 fw-semibold text-success">{{ number_format($summary['published']) }}</div></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Menunggu Verifikasi</div><div class="fs-4 fw-semibold text-warning">{{ number_format($summary['pending']) }}</div></div></div>
            <div class="col-sm-6 col-xl-3"><div class="sg-card sg-mini-metric"><div class="small text-muted">Total Dibaca</div><div class="fs-4 fw-semibold text-primary">{{ number_format($summary['views']) }}</div></div></div>
        </section>

        <div class="sg-article-layout">
            <section class="sg-card p-3 sg-editor-panel">
                <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                    <div>
                        <h6 class="fw-semibold mb-1">{{ $isEdit ? 'Edit Artikel Edukasi' : 'Editor Artikel Edukasi' }}</h6>
                        <div class="small text-muted">Draft tersimpan otomatis di browser saat mengetik.</div>
                    </div>
                    <div class="d-flex flex-wrap align-items-center gap-2 sg-editor-actions">
                        <button class="btn btn-sm btn-outline-primary rounded-pill" form="articleForm" name="action" value="draft" type="submit" title="Simpan artikel sebagai draft">
                            <i class="bi bi-save me-1"></i>Draft
                        </button>
                        <button class="btn btn-sm btn-primary rounded-pill" form="articleForm" name="action" value="publish" type="submit" title="Upload artikel ke aplikasi mobile">
                            <i class="bi bi-cloud-arrow-up me-1"></i>Upload
                        </button>
                        <button class="btn btn-sm btn-outline-secondary rounded-pill" id="previewButton" type="button">
                            <i class="bi bi-eye me-1"></i>Preview
                        </button>
                        @if ($isEdit)
                            <button class="btn btn-sm btn-outline-warning rounded-pill" form="articleForm" name="action" value="archive" type="submit">
                                <i class="bi bi-archive me-1"></i>Arsipkan
                            </button>
                            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.articles.index') }}">Buat Baru</a>
                        @endif
                    </div>
                </div>

                <form id="articleForm" method="post" enctype="multipart/form-data" action="{{ $isEdit ? route('admin.articles.update', $article) : route('admin.articles.store') }}">
                    @csrf
                    @if ($isEdit)
                        @method('PUT')
                    @endif

                    <div class="row g-3">
                        <div class="col-lg-5">
                            <label class="form-label small fw-semibold text-muted">Thumbnail</label>
                            <label class="sg-dropzone" for="thumbnailInput">
                                <input id="thumbnailInput" type="file" name="thumbnail" accept="image/*" @required(! $isEdit && ! $article?->thumbnail)>
                                <img id="thumbPreview" class="{{ $article?->thumbnail ? '' : 'd-none' }}" src="{{ $article?->thumbnail ? asset($article->thumbnail) : '' }}" alt="Preview thumbnail">
                                <span id="dropHint" class="{{ $article?->thumbnail ? 'd-none' : '' }}"><i class="bi bi-cloud-arrow-up"></i> Drag & drop thumbnail</span>
                            </label>
                        </div>
                        <div class="col-lg-7">
                            <label class="form-label small fw-semibold text-muted">Judul</label>
                            <input id="titleInput" class="form-control mb-2" name="title" value="{{ old('title', $article?->title) }}" placeholder="Judul artikel anak sehat" required>

                            <label class="form-label small fw-semibold text-muted">Slug</label>
                            <input id="slugPreview" class="form-control mb-2" value="{{ old('slug', $article?->slug) }}" readonly>

                            <label class="form-label small fw-semibold text-muted">Kategori</label>
                            <select id="categoryInput" class="form-select" name="category" required>
                                @foreach ($categories as $category)
                                    <option value="{{ $category }}" @selected(old('category', $article?->category ?? 'Edukasi Gizi') === $category)>{{ $category }}</option>
                                @endforeach
                            </select>
                        </div>
                        <div class="col-12">
                            <label class="form-label small fw-semibold text-muted">Ringkasan</label>
                            <input id="excerptInput" class="form-control" name="excerpt" value="{{ old('excerpt', $article?->excerpt) }}" placeholder="Ringkasan singkat untuk mobile">
                        </div>
                        <div class="col-12">
                            <label class="form-label small fw-semibold text-muted">Tag</label>
                            <input id="tagsInput" class="form-control" name="tags_input" value="{{ old('tags_input', implode(', ', $article?->tags ?? [])) }}" placeholder="MPASI, Protein Tinggi, Stunting">
                            <div class="d-flex flex-wrap gap-1 mt-2">
                                @foreach ($defaultTags as $tag)
                                    <button class="btn btn-sm btn-outline-primary rounded-pill sg-tag-suggestion" type="button">{{ $tag }}</button>
                                @endforeach
                            </div>
                        </div>
                        <div class="col-12">
                            <div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-2">
                                <label class="form-label small fw-semibold text-muted mb-0">Editor Artikel</label>
                                <div class="d-flex flex-wrap gap-2 sg-editor-inline-actions">
                                    <button class="btn btn-sm btn-outline-primary rounded-pill" name="action" value="draft" type="submit" title="Simpan artikel sebagai draft">
                                        <i class="bi bi-save me-1"></i>Draft
                                    </button>
                                    <button class="btn btn-sm btn-primary rounded-pill" name="action" value="publish" type="submit" title="Upload artikel ke aplikasi mobile">
                                        <i class="bi bi-cloud-arrow-up me-1"></i>Upload
                                    </button>
                                </div>
                            </div>
                            <div id="quillEditor" class="sg-quill">{!! old('content', $article?->content) !!}</div>
                            <input id="contentInput" type="hidden" name="content" value="{{ old('content', $article?->content) }}">
                        </div>
                    </div>
                </form>
            </section>

            <aside class="sg-article-side">
                <section class="sg-card p-3 mb-3">
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <h6 class="fw-semibold mb-0">Live Preview</h6>
                        <span id="readTimeBadge" class="sg-status sg-status-blue">{{ $article?->read_time ?? 1 }} menit baca</span>
                    </div>
                    <div class="sg-preview-card">
                        <img id="previewImage" class="{{ $article?->thumbnail ? '' : 'd-none' }}" src="{{ $article?->thumbnail ? asset($article->thumbnail) : '' }}" alt="Preview artikel">
                        <div class="p-3">
                            <div class="d-flex flex-wrap gap-1 mb-2">
                                <span id="previewCategory" class="sg-chip">{{ $article?->category ?? 'Edukasi Gizi' }}</span>
                                <span class="sg-chip">Admin S-Gizi</span>
                            </div>
                            <h5 id="previewTitle" class="fw-semibold mb-2">{{ $article?->title ?? 'Judul artikel edukasi' }}</h5>
                            <div id="previewBody" class="small text-muted">{!! $article?->content ?: 'Isi artikel akan muncul otomatis saat admin mengetik.' !!}</div>
                        </div>
                    </div>
                </section>

                <section class="sg-card p-3">
                    <h6 class="fw-semibold mb-3">Status Publish</h6>
                    <div class="vstack gap-2 small">
                        <div class="d-flex justify-content-between"><span class="text-muted">Author</span><strong>Admin S-Gizi</strong></div>
                        <div class="d-flex justify-content-between"><span class="text-muted">Status</span><span class="sg-status {{ $statusClass($article?->status ?? 'Draft') }}">{{ $article?->status ?? 'Draft' }}</span></div>
                        <div class="d-flex justify-content-between"><span class="text-muted">Tanggal Publish</span><strong>{{ $article?->published_at?->format('d M Y') ?? '-' }}</strong></div>
                    </div>
                </section>
            </aside>
        </div>

        <section class="sg-card p-3 mt-3">
            <form class="row g-2 align-items-end mb-3" method="get">
                <div class="col-lg-5">
                    <label class="form-label small fw-semibold text-muted">Search realtime</label>
                    <div class="sg-search d-flex align-items-center gap-2 w-100" style="max-width:none">
                        <i class="bi bi-search"></i>
                        <input id="articleSearch" name="q" value="{{ $q }}" placeholder="Cari judul, kategori, atau tag...">
                    </div>
                </div>
                <div class="col-lg-2"><button class="btn btn-primary rounded-4 w-100">Terapkan</button></div>
                <div class="col-12">
                    <div class="sg-filter-scroll">
                        @foreach ($filters as $item)
                            <button class="btn btn-sm rounded-pill {{ $filter === $item ? 'btn-primary' : 'btn-outline-primary' }}" name="filter" value="{{ $item }}">{{ $item }}</button>
                        @endforeach
                    </div>
                </div>
            </form>

            <div class="vstack gap-2">
                @forelse ($articles as $item)
                    @php
                        $creatorName = $item->creator?->name ?: 'Admin S-Gizi';
                        $creatorRole = $item->creator?->role === 'nutritionist' ? 'Dari Ahli Gizi' : 'Dibuat Admin';
                    @endphp
                    <article class="sg-article-row">
                        <div class="d-flex align-items-center gap-2 min-w-0">
                            @if ($item->thumbnail)
                                <img class="sg-article-thumb" src="{{ asset($item->thumbnail) }}" alt="{{ $item->title }}">
                            @else
                                <span class="sg-letter-avatar"><i class="bi bi-newspaper"></i></span>
                            @endif
                            <div class="min-w-0">
                                <div class="fw-semibold text-truncate">{{ $item->title }}</div>
                                <div class="small text-muted text-truncate">{{ $item->excerpt ?: Str::limit(strip_tags($item->content), 90) }}</div>
                                <div class="d-flex flex-wrap gap-1 mt-1">
                                    <span class="sg-chip">{{ $creatorRole }}</span>
                                    <span class="sg-chip">{{ $creatorName }}</span>
                                    @foreach (($item->tags ?? []) as $tag)
                                        <span class="sg-chip">{{ $tag }}</span>
                                    @endforeach
                                </div>
                                @if (($item->status ?? null) === 'Ditolak' && $item->rejection_reason)
                                    <div class="small text-danger mt-1"><strong>Alasan ditolak:</strong> {{ $item->rejection_reason }}</div>
                                @endif
                            </div>
                        </div>
                        <div><span class="sg-status sg-status-blue">{{ $item->category }}</span></div>
                        <div><span class="sg-status {{ $statusClass($item->status) }}">{{ $item->status }}</span></div>
                        <div class="small text-muted">{{ $item->published_at?->format('d M Y') ?? '-' }}<br>{{ $item->author }}</div>
                        <div class="d-flex flex-wrap gap-1 justify-content-end">
                            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.articles.index', ['edit' => $item->id]) }}"><i class="bi bi-pencil"></i> Edit</a>
                            @if (($item->status ?? null) === 'Menunggu Verifikasi')
                                <form method="post" action="{{ route('admin.articles.approve', $item) }}" data-confirm="Setujui dan publish artikel ini?">
                                    @csrf @method('PATCH')
                                    <button class="btn btn-sm btn-success rounded-pill"><i class="bi bi-check2-circle"></i> Setujui</button>
                                </form>
                                <form method="post" action="{{ route('admin.articles.reject', $item) }}" class="sg-reject-form">
                                    @csrf @method('PATCH')
                                    <input type="hidden" name="rejection_reason">
                                    <button class="btn btn-sm btn-outline-danger rounded-pill"><i class="bi bi-x-circle"></i> Tolak</button>
                                </form>
                            @endif
                            @if (! in_array($item->status, ['Published', 'Menunggu Verifikasi'], true))
                                <form method="post" action="{{ route('admin.articles.update', $item) }}">
                                    @csrf @method('PUT')
                                    <input type="hidden" name="title" value="{{ $item->title }}">
                                    <input type="hidden" name="category" value="{{ $item->category }}">
                                    <input type="hidden" name="excerpt" value="{{ $item->excerpt }}">
                                    <input type="hidden" name="tags_input" value="{{ implode(', ', $item->tags ?? []) }}">
                                    <input type="hidden" name="content" value="{{ $item->content }}">
                                    <button class="btn btn-sm btn-primary rounded-pill" name="action" value="publish"><i class="bi bi-cloud-arrow-up"></i> Upload</button>
                                </form>
                            @endif
                            <form method="post" action="{{ route('admin.articles.destroy', $item) }}" data-confirm="Hapus artikel ini dari publikasi?">
                                @csrf @method('delete')
                                <button class="btn btn-sm btn-outline-danger rounded-pill"><i class="bi bi-trash"></i> Hapus</button>
                            </form>
                        </div>
                    </article>
                @empty
                    <div class="text-center text-muted py-5">Belum ada artikel edukasi.</div>
                @endforelse
            </div>

            @if ($articles->hasPages())
                <div class="pt-3 mt-3 border-top">{{ $articles->links('pagination::bootstrap-5') }}</div>
            @endif
        </section>
    </div>

    <x-slot:styles>
        <link href="https://cdn.quilljs.com/1.3.7/quill.snow.css" rel="stylesheet">
        <style>
            .sg-article-summary .sg-mini-metric { min-height: 72px; padding: 12px 14px; border-radius: 16px; }
            .sg-article-layout { display: grid; grid-template-columns: minmax(0, 1.35fr) minmax(330px, .65fr); gap: 14px; align-items: start; }
            .sg-dropzone { display: grid; place-items: center; min-height: 174px; border: 1.5px dashed rgba(75,142,150,.35); border-radius: 18px; background: #F7FCFC; cursor: pointer; overflow: hidden; color: #4B8E96; font-weight: 700; text-align: center; }
            .sg-dropzone input { display: none; }
            .sg-dropzone img { width: 100%; height: 174px; object-fit: cover; }
            .sg-quill { height: 260px; min-height: 260px; max-height: 260px; border-radius: 0 0 16px 16px; background: #fff; overflow: hidden; }
            .ql-toolbar.ql-snow { border-radius: 16px 16px 0 0; border-color: rgba(75,142,150,.18); }
            .ql-container.ql-snow { height: 260px; max-height: 260px; border-color: rgba(75,142,150,.18); border-radius: 0 0 16px 16px; overflow: hidden; }
            .ql-editor { max-height: 258px; overflow-y: auto; overflow-x: hidden; }
            .sg-preview-card { border: 1px solid rgba(75,142,150,.16); border-radius: 18px; overflow: hidden; background: #fff; }
            .sg-preview-card img { width: 100%; height: 156px; object-fit: cover; background: #EDF6F5; }
            .sg-chip { display: inline-flex; padding: 4px 9px; border-radius: 999px; background: #EAF6F4; color: #2f7580; font-size: 11.5px; font-weight: 700; }
            .sg-article-row { display: grid; grid-template-columns: minmax(260px, 1.4fr) 120px 110px 130px minmax(190px, .8fr); gap: 10px; align-items: center; padding: 10px; border: 1px solid rgba(75,142,150,.14); border-radius: 16px; background: #fff; }
            .sg-article-thumb { width: 56px; height: 56px; border-radius: 14px; object-fit: cover; flex: 0 0 56px; }
            @media (max-width: 1199.98px) {
                .sg-article-layout { grid-template-columns: minmax(0, 1fr); }
                .sg-article-row { grid-template-columns: minmax(0, 1fr) minmax(180px, .45fr); align-items: start; }
            }
            @media (max-width: 767.98px) {
                .sg-quill,
                .ql-container.ql-snow { height: 220px; min-height: 220px; max-height: 220px; }
                .ql-editor { max-height: 218px; }
                .sg-article-row { grid-template-columns: minmax(0, 1fr); }
            }
        </style>
    </x-slot:styles>

    <x-slot:scripts>
        <script src="https://cdn.quilljs.com/1.3.7/quill.min.js"></script>
        <script>
            document.getElementById('articleSkeleton')?.classList.add('d-none');
            document.getElementById('articleContent')?.classList.remove('d-none');

            const slugify = (value) => value.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-');
            const countReadTime = (html) => Math.max(1, Math.ceil((html.replace(/<[^>]+>/g, ' ').trim().split(/\s+/).filter(Boolean).length || 1) / 200));
            const titleInput = document.getElementById('titleInput');
            const slugPreview = document.getElementById('slugPreview');
            const categoryInput = document.getElementById('categoryInput');
            const excerptInput = document.getElementById('excerptInput');
            const tagsInput = document.getElementById('tagsInput');
            const contentInput = document.getElementById('contentInput');
            const readTimeBadge = document.getElementById('readTimeBadge');
            const previewTitle = document.getElementById('previewTitle');
            const previewCategory = document.getElementById('previewCategory');
            const previewBody = document.getElementById('previewBody');
            const storageKey = 'sgizi_article_autosave';

            const quill = new Quill('#quillEditor', {
                theme: 'snow',
                modules: {
                    toolbar: [['bold', 'italic'], [{ header: [2, 3, false] }], [{ list: 'bullet' }], ['blockquote', 'link', 'image']]
                }
            });

            const updatePreview = () => {
                const html = quill.root.innerHTML;
                contentInput.value = html;
                previewTitle.textContent = titleInput.value || 'Judul artikel edukasi';
                previewCategory.textContent = categoryInput.value || 'Edukasi Gizi';
                previewBody.innerHTML = html || 'Isi artikel akan muncul otomatis saat admin mengetik.';
                slugPreview.value = slugify(titleInput.value || 'judul-artikel-anak-sehat');
                readTimeBadge.textContent = `${countReadTime(html)} menit baca`;
                localStorage.setItem(storageKey, JSON.stringify({
                    title: titleInput.value,
                    category: categoryInput.value,
                    excerpt: excerptInput.value,
                    tags: tagsInput.value,
                    content: html,
                }));
            };

            [titleInput, categoryInput, excerptInput, tagsInput].forEach((el) => el?.addEventListener('input', updatePreview));
            quill.on('text-change', updatePreview);
            document.getElementById('articleForm')?.addEventListener('submit', updatePreview);

            document.querySelectorAll('.sg-tag-suggestion').forEach((button) => {
                button.addEventListener('click', () => {
                    const current = tagsInput.value.split(',').map((tag) => tag.trim()).filter(Boolean);
                    if (!current.includes(button.textContent.trim())) current.push(button.textContent.trim());
                    tagsInput.value = current.join(', ');
                    updatePreview();
                });
            });

            document.getElementById('thumbnailInput')?.addEventListener('change', (event) => {
                const file = event.target.files?.[0];
                if (!file) return;
                const url = URL.createObjectURL(file);
                for (const id of ['thumbPreview', 'previewImage']) {
                    const image = document.getElementById(id);
                    image.src = url;
                    image.classList.remove('d-none');
                }
                document.getElementById('dropHint')?.classList.add('d-none');
            });

            document.getElementById('articleSearch')?.addEventListener('input', (event) => {
                clearTimeout(window.articleSearchTimer);
                window.articleSearchTimer = setTimeout(() => event.target.form.submit(), 500);
            });
            updatePreview();
        </script>
    </x-slot:scripts>
</x-admin-layout>
