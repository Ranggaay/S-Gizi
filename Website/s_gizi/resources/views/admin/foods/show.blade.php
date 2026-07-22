<x-admin-layout :title="'Detail Rekomendasi Makanan'">
    @php
        $targetStatus = \App\Helpers\NutritionStatusHelper::localize($food->kategori_status);
        if (in_array($food->kategori_status, ['Gizi Buruk', 'Gizi Kurang', 'Gizi Baik', 'Risiko Berat Badan Lebih', 'Gizi Lebih', 'Obesitas', 'Stunting'], true)) {
            $targetStatus = $food->kategori_status;
        }
        $statusClass = match ($targetStatus) {
            'Gizi Buruk', 'Obesitas', 'Stunting' => 'sg-status-red',
            'Gizi Kurang', 'Gizi Lebih' => 'sg-status-orange',
            'Risiko Berat Badan Lebih' => 'sg-status-yellow',
            'Gizi Baik' => 'sg-status-green',
            default => 'sg-status-blue',
        };
        $thumbnail = $food->thumbnail ? asset($food->thumbnail) : null;
    @endphp

    <div class="d-flex flex-wrap justify-content-between align-items-end gap-2 mb-3">
        <div>
            <h1 class="sg-page-title">Detail Menu Rekomendasi</h1>
            <p class="sg-page-subtitle">Preview rekomendasi makanan yang akan tampil sebagai edukasi gizi anak.</p>
        </div>
        <div class="d-flex flex-wrap gap-2">
            <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('admin.foods.edit', $food) }}"><i class="bi bi-pencil me-1"></i>Edit</a>
            <a class="btn btn-sm btn-primary rounded-pill" href="{{ route('admin.foods.index') }}">Kembali</a>
        </div>
    </div>

    <div class="sg-food-detail">
        <section class="sg-card overflow-hidden">
            @if ($thumbnail)
                <img class="sg-food-hero" src="{{ $thumbnail }}" alt="{{ $food->nama }}">
            @else
                <div class="sg-food-hero sg-food-hero-empty"><i class="bi bi-egg-fried"></i></div>
            @endif
            <div class="p-3 p-lg-4">
                <div class="d-flex flex-wrap gap-1 mb-2">
                    <span class="sg-status {{ $statusClass }}">{{ $targetStatus }}</span>
                    <span class="sg-status sg-status-blue">{{ $food->usia_kategori ?: "{$food->usia_min}-{$food->usia_max} bulan" }}</span>
                    <span class="sg-status sg-status-green">{{ $food->status_menu ?? 'Published' }}</span>
                    <span class="sg-status sg-status-gray">{{ $food->prioritas_menu ?? 'Menu Utama' }}</span>
                </div>
                <h2 class="fw-semibold mb-3">{{ $food->nama }}</h2>
                <h6 class="fw-semibold">Mengapa cocok?</h6>
                <p class="text-muted">{{ $food->alasan }}</p>
                <div class="d-flex flex-wrap gap-1">
                    @foreach (($food->badges ?? []) as $badge)
                        <span class="sg-chip">{{ $badge }}</span>
                    @endforeach
                </div>
            </div>
        </section>

        <aside class="vstack gap-3">
            <section class="sg-card p-3">
                <h6 class="fw-semibold mb-3">Nutrisi Lengkap</h6>
                <div class="sg-food-detail-nutrition">
                    @foreach ([['Kalori', $food->kalori.' kkal'], ['Protein', $food->protein.' g'], ['Karbohidrat', $food->karbohidrat.' g'], ['Lemak', $food->lemak.' g'], ['Serat', ($food->serat ?? 0).' g'], ['Gula', ($food->gula ?? 0).' g']] as [$label, $value])
                        <div><span>{{ $label }}</span><strong>{{ $value }}</strong></div>
                    @endforeach
                </div>
            </section>

            <section class="sg-card p-3">
                <h6 class="fw-semibold mb-2">Bahan Makanan</h6>
                <p class="text-muted mb-0">{{ $food->bahan ?: 'Belum ada bahan makanan.' }}</p>
            </section>

            <section class="sg-card p-3">
                <h6 class="fw-semibold mb-2">Cara Memasak</h6>
                <p class="text-muted mb-0">{{ $food->cara_memasak ?: 'Belum ada instruksi memasak.' }}</p>
            </section>
        </aside>
    </div>

    <x-slot:styles>
        <style>
            .sg-food-detail { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(320px, .8fr); gap: 14px; align-items: start; }
            .sg-food-hero { width: 100%; height: 320px; object-fit: cover; background: #EAF6F4; }
            .sg-food-hero-empty { display: grid; place-items: center; color: var(--sgizi); font-size: 56px; }
            .sg-food-detail-nutrition { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
            .sg-food-detail-nutrition div { border: 1px solid rgba(75,142,150,.14); border-radius: 14px; padding: 10px; background: #FAFDFD; }
            .sg-food-detail-nutrition span { display: block; color: var(--sgizi-muted); font-size: 11px; font-weight: 650; }
            .sg-food-detail-nutrition strong { font-size: 15px; }
            @media (max-width: 991.98px) { .sg-food-detail { grid-template-columns: minmax(0, 1fr); } }
        </style>
    </x-slot:styles>
</x-admin-layout>
