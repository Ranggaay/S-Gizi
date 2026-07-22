<x-nutritionist-layout title="Rekomendasi">
    @php
        $foodForm = $editingFood;
        $isEdit = (bool) $foodForm;
        $badgesValue = old('badges_input', implode(', ', $foodForm?->badges ?? []));
        $badgeSuggestions = ['Tinggi Protein', 'Tinggi Serat', 'Tinggi Kalori', 'MPASI', 'Rendah Gula'];
        $statusClass = fn ($status) => match ($status) {
            'Gizi Buruk', 'Obesitas', 'Stunting', 'Ditolak' => 'sg-status-red',
            'Gizi Kurang', 'Gizi Lebih', 'Menunggu Verifikasi', 'Draft' => 'sg-status-orange',
            'Risiko Berat Badan Lebih' => 'sg-status-yellow',
            'Gizi Baik', 'Published' => 'sg-status-green',
            'Archived' => 'sg-status-gray',
            default => 'sg-status-blue',
        };
    @endphp
    <div class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
        <div class="d-flex align-items-center gap-3">
            <span class="module-icon"><i class="bi bi-egg-fried"></i></span>
            <div><h1 class="page-title">Rekomendasi Makanan</h1><p class="page-subtitle">Lihat rekomendasi dari sistem dan bagikan ke chat orang tua.</p></div>
        </div>
    </div>

    <section class="row g-2 mb-4">
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Total Menu</span><strong>{{ number_format($foodSummary['total']) }}</strong></div></div>
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Dipublikasikan</span><strong class="text-success">{{ number_format($foodSummary['published']) }}</strong></div></div>
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Menunggu Verifikasi</span><strong class="text-warning">{{ number_format($foodSummary['pending']) }}</strong></div></div>
        <div class="col-sm-6 col-xl-3"><div class="sg-card mini-card"><span>Draft</span><strong class="text-primary">{{ number_format($foodSummary['draft']) }}</strong></div></div>
    </section>

    @if ($mode === 'manage')
    <div class="sg-card p-4 mb-4">
        <div class="d-flex justify-content-between align-items-center gap-2 mb-3">
            <h5 class="fw-bold mb-0">{{ $isEdit ? 'Edit Rekomendasi Makanan' : 'Tambah Rekomendasi Makanan' }}</h5>
            @if ($isEdit)<a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('nutritionist.recommendations') }}">Buat Baru</a>@endif
        </div>
        <form method="post" action="{{ $isEdit ? route('nutritionist.recommendations.update', $foodForm) : route('nutritionist.recommendations.store') }}" enctype="multipart/form-data" class="row g-3">
            @csrf
            @if ($isEdit) @method('PUT') @endif
            <div class="col-md-4"><label class="form-label">Foto makanan</label><input class="form-control" type="file" name="thumbnail" accept="image/*"></div>
            <div class="col-md-5"><label class="form-label">Nama menu</label><input class="form-control" name="nama" value="{{ old('nama', $foodForm?->nama) }}" required></div>
            <div class="col-md-3"><label class="form-label">Status gizi</label><select class="form-select" name="kategori_status">@foreach (['Gizi Buruk','Gizi Kurang','Gizi Baik','Risiko Berat Badan Lebih','Gizi Lebih','Obesitas','Stunting'] as $item)<option @selected(old('kategori_status', $foodForm?->kategori_status) === $item)>{{ $item }}</option>@endforeach</select></div>
            <div class="col-md-3"><label class="form-label">Usia</label><select class="form-select" name="usia_kategori" id="foodAgeCategory">@foreach (['6-8 bulan' => [6,8], '9-11 bulan' => [9,11], '1-3 tahun' => [12,36], '4-5 tahun' => [37,60]] as $label => $range)<option data-min="{{ $range[0] }}" data-max="{{ $range[1] }}" @selected(old('usia_kategori', $foodForm?->usia_kategori ?? '1-3 tahun') === $label)>{{ $label }}</option>@endforeach</select></div>
            <div class="col-md-2"><label class="form-label">Min</label><input id="foodAgeMin" class="form-control" type="number" name="usia_min" value="{{ old('usia_min', $foodForm?->usia_min ?? 12) }}" required></div>
            <div class="col-md-2"><label class="form-label">Max</label><input id="foodAgeMax" class="form-control" type="number" name="usia_max" value="{{ old('usia_max', $foodForm?->usia_max ?? 36) }}" required></div>
            <div class="col-md-3"><label class="form-label">Prioritas</label><select class="form-select" name="prioritas_menu">@foreach (['Menu Utama', 'Menu Alternatif', 'Snack Sehat'] as $item)<option @selected(old('prioritas_menu', $foodForm?->prioritas_menu ?? 'Menu Utama') === $item)>{{ $item }}</option>@endforeach</select></div>
            <input type="hidden" name="status_menu" value="{{ $isEdit ? ($foodForm->status_menu ?? 'Draft') : 'Draft' }}">
            @foreach ([['kalori','Kalori',250],['protein','Protein',12],['karbohidrat','Karbo',30],['lemak','Lemak',8],['serat','Serat',3],['gula','Gula',4]] as [$name,$label,$default])
                <div class="col-6 col-md-2"><label class="form-label">{{ $label }}</label><input class="form-control" type="number" min="0" name="{{ $name }}" value="{{ old($name, $foodForm?->{$name} ?? $default) }}" required></div>
            @endforeach
            <div class="col-md-6">
                <label class="form-label">Badge Kategori</label>
                <input id="foodBadgesInput" class="form-control" name="badges_input" value="{{ $badgesValue }}" placeholder="Tinggi Protein, MPASI">
                <div class="d-flex flex-wrap gap-1 mt-2">
                    @foreach ($badgeSuggestions as $badge)
                        <button class="btn btn-sm btn-outline-primary rounded-pill food-badge-suggestion" type="button">{{ $badge }}</button>
                    @endforeach
                </div>
            </div>
            <div class="col-md-6"><label class="form-label">Bahan</label><input class="form-control" name="bahan" value="{{ old('bahan', $foodForm?->bahan) }}"></div>
            <div class="col-md-6"><label class="form-label">Mengapa cocok?</label><textarea class="form-control" name="alasan" rows="3" required>{{ old('alasan', $foodForm?->alasan) }}</textarea></div>
            <div class="col-md-6"><label class="form-label">Cara penyajian</label><textarea class="form-control" name="cara_memasak" rows="3">{{ old('cara_memasak', $foodForm?->cara_memasak) }}</textarea></div>
            <div class="col-12 text-end d-flex justify-content-end gap-2">
                <button class="btn btn-outline-primary rounded-pill px-4" name="action" value="draft">Simpan Draft</button>
                <button class="btn btn-primary rounded-pill px-4" name="action" value="submit">Ajukan ke Admin</button>
            </div>
        </form>
    </div>
    @endif

    <form class="sg-card p-3 mb-4" method="get">
        @if ($roomId) <input type="hidden" name="room" value="{{ $roomId }}"> @endif
        <div class="row g-2 align-items-end">
            <div class="col-md-4"><label class="form-label fw-semibold text-muted">Pencarian</label><input class="form-control" name="q" value="{{ $q }}" placeholder="Ketik nama menu, status, atau badge"></div>
            <div class="col-md-4"><label class="form-label fw-semibold text-muted">Status Gizi</label><select class="form-select" name="status"><option>Semua</option>@foreach (['Gizi Baik','Berat Badan Kurang','Berat Badan Sangat Kurang','Pendek','Sangat Pendek','Gizi Kurang','Gizi Buruk','Risiko Berat Badan Lebih','Stunting','Underweight','Wasting','Obesitas','Normal'] as $item)<option @selected($status === $item)>{{ $item }}</option>@endforeach</select></div>
            <div class="col-md-3"><label class="form-label fw-semibold text-muted">Usia Anak</label><select class="form-select" name="age"><option>Semua</option>@foreach (['0-6 bulan','7-12 bulan','1-3 tahun','3-5 tahun'] as $item)<option @selected($age === $item)>{{ $item }}</option>@endforeach</select></div>
            <div class="col-md-2"><button class="btn btn-primary rounded-4 w-100">Terapkan</button></div>
        </div>
    </form>

    <div class="row g-3">
        @forelse ($foods as $food)
            <div class="col-md-6 col-xl-4">
                <div class="sg-card food-card h-100">
                    <div class="food-photo">
                        @if ($food->thumbnail)
                            <img src="{{ asset($food->thumbnail) }}" alt="{{ $food->nama }}">
                        @else
                            <i class="bi bi-egg-fried"></i>
                        @endif
                    </div>
                    <div class="p-3">
                    <h5 class="fw-bold mb-2">{{ $food->nama }}</h5>
                    <div class="d-flex flex-wrap gap-2 mb-3">
                        <span class="sg-status {{ $statusClass($food->kategori_status) }}">{{ $food->kategori_status }}</span>
                        <span class="sg-status sg-status-blue">{{ $food->usia_kategori ?: $food->usia_min.'-'.$food->usia_max.' bulan' }}</span>
                        <span class="sg-status {{ $statusClass($food->status_menu) }}">{{ $food->status_menu }}</span>
                    </div>
                    <div class="nutrition-grid small mb-3">
                        <div><span>Kalori</span><strong>{{ $food->kalori }} kkal</strong></div>
                        <div><span>Protein</span><strong>{{ $food->protein }}g</strong></div>
                        <div><span>Karbo</span><strong>{{ $food->karbohidrat }}g</strong></div>
                        <div><span>Lemak</span><strong>{{ $food->lemak }}g</strong></div>
                        <div><span>Serat</span><strong>{{ $food->serat ?? 0 }}g</strong></div>
                        <div><span>Gula</span><strong>{{ $food->gula ?? 0 }}g</strong></div>
                    </div>
                    <div class="d-flex flex-wrap gap-1 mb-2">@foreach (($food->badges ?? []) as $badge)<span class="sg-chip">{{ $badge }}</span>@endforeach</div>
                    @if (($food->status_menu ?? null) === 'Ditolak' && $food->rejection_reason)
                        <div class="rejection-box mb-3">
                            <strong><i class="bi bi-info-circle me-1"></i>Alasan ditolak</strong>
                            <p>{{ $food->rejection_reason }}</p>
                        </div>
                    @endif
                    <div class="text-muted small mb-2"><strong>Bahan:</strong> {{ $food->bahan ?: '-' }}</div>
                    <div class="text-muted small mb-3"><strong>Cara penyajian:</strong> {{ $food->cara_memasak ?: $food->alasan }}</div>
                    @if ($mode === 'send')
                    <form class="recommendation-send-form" method="post" action="{{ route('nutritionist.consultations.recommendations.send', $roomId ?: ($rooms->first()?->id ?? 0)) }}">
                        @csrf
                        <input type="hidden" name="food_id" value="{{ $food->id }}">
                        @unless ($roomId)
                            <input class="form-control form-control-sm mb-2 chat-picker" list="roomOptions-{{ $food->id }}" placeholder="Ketik nama anak/orang tua" autocomplete="off" required>
                            <datalist id="roomOptions-{{ $food->id }}">
                                @foreach ($rooms as $room)<option data-room-id="{{ $room->id }}" value="{{ $room->child?->nama }} - {{ $room->user?->name }}"></option>@endforeach
                            </datalist>
                        @endunless
                        <textarea class="form-control mb-2" name="manual_note" rows="2" placeholder="Saran manual tambahan"></textarea>
                        <button class="btn btn-primary rounded-pill w-100" @disabled(! $roomId && $rooms->isEmpty())>Kirim ke Chat</button>
                    </form>
                    @endif
                    @if ($mode === 'manage')
                    <div class="d-flex flex-wrap gap-2 mt-3">
                        <a class="btn btn-sm btn-outline-primary rounded-pill" href="{{ route('nutritionist.recommendations.manage', ['edit' => $food->id]) }}"><i class="bi bi-pencil"></i> Edit</a>
                        @unless (($food->status_menu ?? 'Published') === 'Archived')
                            <form method="post" action="{{ route('nutritionist.recommendations.archive', $food) }}" data-confirm="Arsipkan rekomendasi ini?">@csrf @method('PATCH')<button class="btn btn-sm btn-outline-warning rounded-pill"><i class="bi bi-archive"></i> Arsipkan</button></form>
                        @endunless
                    </div>
                    @endif
                    </div>
                </div>
            </div>
        @empty
            <div class="col-12"><div class="sg-card p-5 text-center text-muted"><div class="empty-icon mx-auto mb-3"><i class="bi bi-egg-fried"></i></div>Belum ada rekomendasi makanan.</div></div>
        @endforelse
    </div>
    <div class="mt-3">{{ $foods->links('pagination::bootstrap-5') }}</div>
    <x-slot:scripts>
        <style>
            .module-icon, .empty-icon { width:58px; height:58px; border-radius:18px; display:grid; place-items:center; background:#E8F6F6; color:#0F8B8D; font-size:27px; flex:0 0 auto; }
            .empty-icon { width:72px; height:72px; border-radius:24px; font-size:34px; }
            .food-card { overflow:hidden; transition:.18s ease; }
            .food-card:hover { transform:translateY(-2px); box-shadow:0 18px 38px rgba(15,139,141,.12); }
            .food-photo { height:142px; background:#EAF6F4; display:grid; place-items:center; color:#0F8B8D; font-size:38px; overflow:hidden; }
            .food-photo img { width:100%; height:100%; object-fit:cover; }
            .nutrition-grid { display:grid; grid-template-columns:repeat(3,minmax(0,1fr)); gap:7px; }
            .nutrition-grid div { border:1px solid #DCEAEA; border-radius:13px; padding:7px 8px; background:#FAFDFD; }
            .nutrition-grid span { display:block; color:#6B7280; font-size:11px; font-weight:700; }
            .nutrition-grid strong { display:block; font-size:12.5px; }
            .sg-chip { display:inline-flex; padding:4px 9px; border-radius:999px; background:#EAF6F4; color:#2f7580; font-size:11.5px; font-weight:700; }
            .rejection-box { border:1px solid #F4B4B4; border-radius:14px; background:#FDECEC; color:#A93A3A; padding:10px 12px; }
            .rejection-box strong { display:block; font-size:12px; margin-bottom:4px; }
            .rejection-box p { margin:0; font-size:12.5px; line-height:1.45; }
        </style>
        <script>
            document.getElementById('foodAgeCategory')?.addEventListener('change', (event) => {
                const option = event.target.selectedOptions[0];
                document.getElementById('foodAgeMin').value = option.dataset.min;
                document.getElementById('foodAgeMax').value = option.dataset.max;
            });
            const foodBadgesInput = document.getElementById('foodBadgesInput');
            document.querySelectorAll('.food-badge-suggestion').forEach((button) => {
                button.addEventListener('click', () => {
                    if (!foodBadgesInput) return;
                    const current = foodBadgesInput.value.split(',').map((badge) => badge.trim()).filter(Boolean);
                    const value = button.textContent.trim();
                    if (!current.includes(value)) current.push(value);
                    foodBadgesInput.value = current.join(', ');
                    foodBadgesInput.focus();
                });
            });
            document.querySelectorAll('.recommendation-send-form').forEach((form) => {
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
                    form.action = `{{ url('/nutritionist/konsultasi') }}/${match.dataset.roomId}/rekomendasi`;
                });
            });
        </script>
    </x-slot:scripts>
</x-nutritionist-layout>
