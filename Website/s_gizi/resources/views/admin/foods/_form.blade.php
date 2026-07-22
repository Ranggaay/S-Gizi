@php
    $food = $food ?? null;
    $statuses = ['Gizi Buruk', 'Gizi Kurang', 'Gizi Baik', 'Risiko Berat Badan Lebih', 'Gizi Lebih', 'Obesitas', 'Stunting'];
    $ageCategories = [
        '6-8 bulan' => [6, 8],
        '9-11 bulan' => [9, 11],
        '1-3 tahun' => [12, 36],
        '4-5 tahun' => [37, 60],
    ];
    $badgeOptions = ['Tinggi Protein', 'Tinggi Serat', 'Tinggi Kalori', 'MPASI', 'Rendah Gula'];
    $selectedBadges = old('badges_input', implode(', ', $food?->badges ?? []));
@endphp

<div class="row g-3">
    <div class="col-lg-4">
        <label class="form-label small fw-semibold text-muted">Foto Makanan</label>
        <label class="sg-food-dropzone" for="thumbnailInput">
            <input id="thumbnailInput" type="file" name="thumbnail" accept="image/*" @required(! $food?->exists)>
            <img id="thumbPreview" class="{{ $food?->thumbnail ? '' : 'd-none' }}" src="{{ $food?->thumbnail ? asset($food->thumbnail) : '' }}" alt="Preview makanan">
            <span id="dropHint" class="{{ $food?->thumbnail ? 'd-none' : '' }}"><i class="bi bi-cloud-arrow-up"></i> Upload foto makanan</span>
        </label>
    </div>

    <div class="col-lg-8">
        <div class="row g-3">
            <div class="col-md-7">
                <label class="form-label small fw-semibold text-muted">Nama Makanan</label>
                <input class="form-control" name="nama" value="{{ old('nama', $food?->nama) }}" placeholder="Bubur ayam kacang hijau" required>
            </div>
            <div class="col-md-5">
                <label class="form-label small fw-semibold text-muted">Target Status WHO</label>
                <select class="form-select" name="kategori_status" required>
                    @foreach ($statuses as $status)
                        <option value="{{ $status }}" @selected(old('kategori_status', $food?->kategori_status ?? 'Gizi Baik') === $status)>{{ $status }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-4">
                <label class="form-label small fw-semibold text-muted">Usia Target</label>
                <select class="form-select" id="ageCategoryInput" name="usia_kategori" required>
                    @foreach ($ageCategories as $label => $range)
                        <option value="{{ $label }}" data-min="{{ $range[0] }}" data-max="{{ $range[1] }}" @selected(old('usia_kategori', $food?->usia_kategori ?? '1-3 tahun') === $label)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label small fw-semibold text-muted">Usia Min</label>
                <input id="ageMinInput" type="number" class="form-control" name="usia_min" value="{{ old('usia_min', $food?->usia_min ?? 12) }}" required>
            </div>
            <div class="col-md-2">
                <label class="form-label small fw-semibold text-muted">Usia Max</label>
                <input id="ageMaxInput" type="number" class="form-control" name="usia_max" value="{{ old('usia_max', $food?->usia_max ?? 36) }}" required>
            </div>
            <div class="col-md-2">
                <label class="form-label small fw-semibold text-muted">Status</label>
                <select class="form-select" name="status_menu" required>
                    @foreach (['Published', 'Draft', 'Archived'] as $status)
                        <option value="{{ $status }}" @selected(old('status_menu', $food?->status_menu ?? 'Published') === $status)>{{ $status }}</option>
                    @endforeach
                </select>
            </div>
            <div class="col-md-2">
                <label class="form-label small fw-semibold text-muted">Prioritas</label>
                <select class="form-select" name="prioritas_menu" required>
                    @foreach (['Menu Utama', 'Menu Alternatif', 'Snack Sehat'] as $priority)
                        <option value="{{ $priority }}" @selected(old('prioritas_menu', $food?->prioritas_menu ?? 'Menu Utama') === $priority)>{{ $priority }}</option>
                    @endforeach
                </select>
            </div>
        </div>
    </div>

    @foreach ([['kalori','Kalori','kkal',250], ['protein','Protein','g',12], ['karbohidrat','Karbohidrat','g',30], ['lemak','Lemak','g',8], ['serat','Serat','g',3], ['gula','Gula','g',4]] as [$name, $label, $unit, $default])
        <div class="col-6 col-md-2">
            <label class="form-label small fw-semibold text-muted">{{ $label }}</label>
            <div class="input-group">
                <input type="number" class="form-control" name="{{ $name }}" value="{{ old($name, $food?->{$name} ?? $default) }}" min="0" required>
                <span class="input-group-text">{{ $unit }}</span>
            </div>
        </div>
    @endforeach

    <div class="col-12">
        <label class="form-label small fw-semibold text-muted">Badge Kategori</label>
        <input id="badgesInput" class="form-control" name="badges_input" value="{{ $selectedBadges }}" placeholder="Tinggi Protein, MPASI, Rendah Gula">
        <div class="d-flex flex-wrap gap-1 mt-2">
            @foreach ($badgeOptions as $badge)
                <button class="btn btn-sm btn-outline-primary rounded-pill sg-badge-suggestion" type="button">{{ $badge }}</button>
            @endforeach
        </div>
    </div>

    <div class="col-12">
        <label class="form-label small fw-semibold text-muted">Mengapa Cocok?</label>
        <textarea class="form-control" name="alasan" rows="3" required placeholder="Tinggi protein dan energi untuk membantu peningkatan berat badan anak.">{{ old('alasan', $food?->alasan) }}</textarea>
    </div>

    <div class="col-md-6">
        <label class="form-label small fw-semibold text-muted">Bahan Makanan</label>
        <textarea class="form-control" name="bahan" rows="4" placeholder="Beras, ayam, wortel, kacang hijau">{{ old('bahan', $food?->bahan) }}</textarea>
    </div>
    <div class="col-md-6">
        <label class="form-label small fw-semibold text-muted">Cara Memasak</label>
        <textarea class="form-control" name="cara_memasak" rows="4" placeholder="Masak hingga lunak, sesuaikan tekstur dengan usia anak.">{{ old('cara_memasak', $food?->cara_memasak) }}</textarea>
    </div>
</div>

<style>
    .sg-food-dropzone { display: grid; place-items: center; min-height: 220px; border: 1.5px dashed rgba(75,142,150,.35); border-radius: 18px; background: #F7FCFC; cursor: pointer; overflow: hidden; color: #4B8E96; font-weight: 750; text-align: center; }
    .sg-food-dropzone input { display: none; }
    .sg-food-dropzone img { width: 100%; height: 220px; object-fit: cover; }
</style>

<script>
    document.getElementById('ageCategoryInput')?.addEventListener('change', (event) => {
        const option = event.target.selectedOptions[0];
        document.getElementById('ageMinInput').value = option.dataset.min;
        document.getElementById('ageMaxInput').value = option.dataset.max;
    });

    document.querySelectorAll('.sg-badge-suggestion').forEach((button) => {
        button.addEventListener('click', () => {
            const input = document.getElementById('badgesInput');
            const current = input.value.split(',').map((item) => item.trim()).filter(Boolean);
            if (!current.includes(button.textContent.trim())) current.push(button.textContent.trim());
            input.value = current.join(', ');
        });
    });

    document.getElementById('thumbnailInput')?.addEventListener('change', (event) => {
        const file = event.target.files?.[0];
        if (!file) return;
        const preview = document.getElementById('thumbPreview');
        preview.src = URL.createObjectURL(file);
        preview.classList.remove('d-none');
        document.getElementById('dropHint')?.classList.add('d-none');
    });
</script>
