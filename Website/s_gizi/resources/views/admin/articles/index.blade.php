<x-admin-layout :title="'Artikel Edukasi'">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <div>
            <h4 class="fw-bold mb-1">Artikel Edukasi</h4>
            <div class="text-muted">Kelola konten edukasi untuk dashboard mobile.</div>
        </div>
    </div>

    <div class="card shadow-sm mb-4">
        <div class="card-body">
            <form method="post" action="{{ route('admin.articles.store') }}" class="row g-3">
                @csrf
                <div class="col-md-6"><input name="title" class="form-control" placeholder="Judul"></div>
                <div class="col-md-3"><input name="category" class="form-control" value="Edukasi Gizi"></div>
                <div class="col-md-3 form-check pt-2"><input name="published" value="1" class="form-check-input" type="checkbox" checked> <label class="form-check-label">Published</label></div>
                <div class="col-12"><input name="excerpt" class="form-control" placeholder="Ringkasan singkat"></div>
                <div class="col-12"><textarea name="content" rows="4" class="form-control" placeholder="Konten artikel"></textarea></div>
                <div class="col-12"><button class="btn btn-primary">Tambah Artikel</button></div>
            </form>
        </div>
    </div>

    <div class="row g-3">
        @foreach ($articles as $article)
            <div class="col-md-6">
                <div class="card shadow-sm h-100">
                    <div class="card-body">
                        <div class="d-flex justify-content-between">
                            <span class="badge text-bg-light">{{ $article->category }}</span>
                            <span class="badge {{ $article->published ? 'text-bg-success' : 'text-bg-secondary' }}">{{ $article->published ? 'Published' : 'Draft' }}</span>
                        </div>
                        <h5 class="mt-3">{{ $article->title }}</h5>
                        <p class="text-muted">{{ $article->excerpt }}</p>
                        <form method="post" action="{{ route('admin.articles.destroy', $article) }}">
                            @csrf @method('delete')
                            <button class="btn btn-sm btn-outline-danger">Hapus</button>
                        </form>
                    </div>
                </div>
            </div>
        @endforeach
    </div>
    <div class="mt-3">{{ $articles->links('pagination::bootstrap-5') }}</div>
</x-admin-layout>
