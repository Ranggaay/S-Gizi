<?php

namespace App\Http\Controllers\Nutritionist;

use App\Helpers\NutritionStatusHelper;
use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Child;
use App\Models\ConsultationMessage;
use App\Models\ConsultationRoom;
use App\Models\Makanan;
use App\Models\Measurement;
use App\Models\Nutritionist;
use App\Models\NutritionistNote;
use App\Models\NutritionistNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class NutritionistWebController extends Controller
{
    public function dashboard(Request $request): View
    {
        $nutritionist = $this->nutritionist($request);
        $rooms = $this->assignedRooms($nutritionist)
            ->with(['user', 'child.measurements'])
            ->latest('last_message_at')
            ->get();

        $rows = $rooms->map(fn (ConsultationRoom $room) => $this->roomRow($room));
        $stats = [
            'active' => $rows->whereIn('status', ['active', 'waiting_reply'])->count(),
            'unreplied' => $rows->where('needs_reply', true)->count(),
            'high_risk' => $rows->where('risk', 'Risiko Tinggi')->count(),
            'watch' => $rows->where('risk', 'Perlu Dipantau')->count(),
            'remeasure' => $rows->where('validation', 'Perlu Ukur Ulang')->count(),
        ];

        $notifications = $this->notificationQuery($nutritionist)
            ->with(['child', 'room.user'])
            ->latest()
            ->take(6)
            ->get();

        return view('nutritionist.dashboard', [
            'stats' => $stats,
            'rooms' => $rows->take(6),
            'notifications' => $notifications,
        ]);
    }

    public function consultations(Request $request): View
    {
        $nutritionist = $this->nutritionist($request);
        $filter = (string) $request->query('filter', 'Semua');
        $q = trim((string) $request->query('q', ''));
        $selectedRoomId = (int) $request->query('room');

        $rooms = $this->assignedRooms($nutritionist)
            ->with(['user', 'child.measurements', 'messages' => fn ($query) => $query->latest()->take(1)])
            ->latest('last_message_at')
            ->get()
            ->map(fn (ConsultationRoom $room) => $this->roomRow($room, true))
            ->when($q !== '', fn (Collection $rows) => $rows->filter(function ($row) use ($q) {
                $needle = mb_strtolower($q);

                return str_contains(mb_strtolower($row['parent_name']), $needle)
                    || str_contains(mb_strtolower($row['child_name']), $needle);
            }))
            ->when($filter !== 'Semua', fn (Collection $rows) => $rows->filter(fn ($row) => match ($filter) {
                'Belum Dibalas' => $row['needs_reply'],
                'Aktif' => in_array($row['status'], ['active', 'waiting_reply'], true),
                'Risiko Tinggi' => $row['risk'] === 'Risiko Tinggi',
                'Perlu Dipantau' => $row['risk'] === 'Perlu Dipantau',
                'Perlu Ukur Ulang' => $row['validation'] === 'Perlu Ukur Ulang',
                'Selesai' => $row['status'] === 'closed',
                default => true,
            }))->values();

        $selected = $selectedRoomId
            ? $this->assignedRooms($nutritionist)->with(['user', 'child.measurements', 'messages'])->find($selectedRoomId)
            : ($rooms->first()['room'] ?? null);

        if ($selected) {
            $selected->messages()
                ->where('sender_type', 'parent')
                ->where('is_read', false)
                ->update(['is_read' => true]);
            $selected->forceFill(['unread_count' => 0])->saveQuietly();
            $selected->load(['user', 'child.measurements', 'messages']);
        }

        return view('nutritionist.consultations', [
            'filters' => ['Semua', 'Belum Dibalas', 'Aktif', 'Risiko Tinggi', 'Perlu Dipantau', 'Perlu Ukur Ulang', 'Selesai'],
            'filter' => $filter,
            'q' => $q,
            'rooms' => $rooms,
            'selected' => $selected,
            'selectedRow' => $selected ? $this->roomRow($selected) : null,
        ]);
    }

    public function sendMessage(Request $request, ConsultationRoom $room): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        $this->abortUnlessAssigned($nutritionist, $room);
        abort_if($this->isClosed($room), 422, 'Konsultasi sudah selesai.');
        abort_unless($room->messages()->exists(), 422, 'Ahli gizi tidak dapat memulai chat.');

        $data = $request->validate([
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $message = $room->messages()->create([
            'sender_type' => 'expert',
            'message' => $data['message'],
            'is_read' => false,
        ]);

        $room->update([
            'status' => 'active',
            'last_message' => $message->message,
            'last_message_at' => now(),
        ]);

        return redirect()->route('nutritionist.consultations', ['room' => $room->id])->with('success', 'Pesan terkirim.');
    }

    public function closeConsultation(Request $request, ConsultationRoom $room): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        $this->abortUnlessAssigned($nutritionist, $room);

        $room->update(['status' => 'closed']);
        $this->notify($nutritionist, $room, 'closed', 'Konsultasi selesai', 'Konsultasi telah ditandai selesai.', 'Normal');

        return back()->with('success', 'Konsultasi ditandai selesai.');
    }

    public function childDetail(Request $request, ConsultationRoom $room): View
    {
        $nutritionist = $this->nutritionist($request);
        $this->abortUnlessAssigned($nutritionist, $room);

        $room->load(['user', 'child.measurements']);
        $child = $room->child;
        $measurements = $child?->measurements?->sortByDesc('tanggal_ukur')->values() ?? collect();
        $latest = $measurements->first();
        $notes = NutritionistNote::query()
            ->where('nutritionist_id', $nutritionist->id)
            ->where('consultation_room_id', $room->id)
            ->latest()
            ->get();

        return view('nutritionist.child-detail', [
            'room' => $room,
            'child' => $child,
            'parent' => $room->user,
            'latest' => $latest,
            'measurements' => $measurements,
            'notes' => $notes,
            'summary' => $this->childSummary($child),
            'chartRows' => $measurements->sortBy('tanggal_ukur')->values()->map(fn (Measurement $measurement) => [
                'date' => $measurement->tanggal_ukur?->format('d/m/Y'),
                'raw_date' => $measurement->tanggal_ukur?->toDateString(),
                'weight' => (float) $measurement->berat,
                'height' => (float) $measurement->tinggi,
                'z_bbu' => (float) $measurement->z_bbu,
                'z_tbu' => (float) $measurement->z_tbu,
                'z_bbtb' => (float) $measurement->z_bbtb,
            ]),
        ]);
    }

    public function storeNote(Request $request, ConsultationRoom $room): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        $this->abortUnlessAssigned($nutritionist, $room);

        $data = $request->validate([
            'category' => ['required', Rule::in(['Saran pola makan', 'Saran pengukuran ulang', 'Saran konsultasi lanjutan', 'Catatan umum'])],
            'note' => ['required', 'string', 'max:3000'],
        ]);

        NutritionistNote::query()->create([
            'consultation_room_id' => $room->id,
            'nutritionist_id' => $nutritionist->id,
            'child_id' => $room->child_id,
            'category' => $data['category'],
            'note' => $data['note'],
        ]);

        return redirect()->route('nutritionist.consultations.child', $room)->with('success', 'Catatan tersimpan.');
    }

    public function recommendations(Request $request): View
    {
        $nutritionist = $this->nutritionist($request);
        $mode = (string) ($request->route('mode') ?? 'manage');
        $status = (string) $request->query('status', 'Semua');
        $age = (string) $request->query('age', 'Semua');
        $q = trim((string) $request->query('q', ''));
        $roomId = (int) $request->query('room');
        $editId = $request->integer('edit');

        $baseFoods = Makanan::query()
            ->when($mode === 'manage', fn ($query) => $query->where('created_by', $request->user()->id))
            ->when($mode === 'send', fn ($query) => $query->where('status_menu', 'Published'))
            ->when($mode !== 'send', fn ($query) => $query->where('status_menu', '!=', 'Archived'));

        $foodSummary = [
            'total' => (clone $baseFoods)->count(),
            'published' => (clone $baseFoods)->where('status_menu', 'Published')->count(),
            'pending' => (clone $baseFoods)->where('status_menu', 'Menunggu Verifikasi')->count(),
            'draft' => (clone $baseFoods)->where('status_menu', 'Draft')->count(),
        ];

        $foods = (clone $baseFoods)
            ->when($q !== '', fn ($query) => $query->where(fn ($where) => $where
                ->where('nama', 'like', "%{$q}%")
                ->orWhere('kategori_status', 'like', "%{$q}%")
                ->orWhere('badges', 'like', "%{$q}%")
                ->orWhere('alasan', 'like', "%{$q}%")))
            ->when($status !== 'Semua', fn ($query) => $query->where('kategori_status', $status))
            ->when($age !== 'Semua', function ($query) use ($age) {
                [$min, $max] = match ($age) {
                    '0-6 bulan' => [0, 6],
                    '7-12 bulan' => [7, 12],
                    '1-3 tahun' => [12, 36],
                    '3-5 tahun' => [36, 60],
                    default => [0, 120],
                };
                $query->where('usia_min', '<=', $max)->where('usia_max', '>=', $min);
            })
            ->orderBy('kategori_status')
            ->orderBy('nama')
            ->paginate(12)
            ->withQueryString();

        return view('nutritionist.recommendations', [
            'foods' => $foods,
            'q' => $q,
            'status' => $status,
            'age' => $age,
            'roomId' => $roomId,
            'rooms' => $this->shareableRooms($nutritionist),
            'editingFood' => $editId ? Makanan::query()->where('created_by', $request->user()->id)->find($editId) : null,
            'mode' => $mode,
            'foodSummary' => $foodSummary,
        ]);
    }

    public function storeRecommendation(Request $request): RedirectResponse
    {
        $data = $this->validatedFood($request);
        $data['thumbnail'] = $this->storeUploadedFile($request, 'thumbnail', 'assets/foods', 'menu');
        $data['created_by'] = $request->user()->id;
        $data['status_menu'] = $request->input('action') === 'draft' ? 'Draft' : 'Menunggu Verifikasi';

        Makanan::query()->create($data);

        return redirect()->route('nutritionist.recommendations.manage')->with('success', 'Rekomendasi makanan berhasil disimpan.');
    }

    public function updateRecommendation(Request $request, Makanan $food): RedirectResponse
    {
        abort_unless((int) $food->created_by === (int) $request->user()->id, 403);
        abort_unless(in_array($food->status_menu, ['Draft', 'Ditolak'], true), 422, 'Rekomendasi hanya bisa diedit saat Draft atau Ditolak.');
        $data = $this->validatedFood($request);
        $thumbnail = $this->storeUploadedFile($request, 'thumbnail', 'assets/foods', 'menu');
        if ($thumbnail) {
            $data['thumbnail'] = $thumbnail;
        }

        $data['status_menu'] = $request->input('action') === 'submit' ? 'Menunggu Verifikasi' : 'Draft';
        $food->update($data);

        return redirect()->route('nutritionist.recommendations.manage')->with('success', 'Rekomendasi makanan berhasil diperbarui.');
    }

    public function archiveRecommendation(Request $request, Makanan $food): RedirectResponse
    {
        abort_unless((int) $food->created_by === (int) $request->user()->id, 403);
        $food->update(['status_menu' => 'Archived']);

        return back()->with('success', 'Rekomendasi makanan berhasil diarsipkan.');
    }

    public function destroyRecommendation(Request $request, Makanan $food): RedirectResponse
    {
        abort_unless((int) $food->created_by === (int) $request->user()->id, 403);
        abort_if($food->status_menu === 'Published', 422, 'Menu yang sudah dipublikasikan hanya bisa dihapus permanen oleh admin/super admin.');

        $food->delete();

        return redirect()->route('nutritionist.recommendations.manage')->with('success', 'Rekomendasi makanan berhasil dihapus permanen.');
    }

    public function sendRecommendation(Request $request, ConsultationRoom $room): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        $this->abortUnlessAssigned($nutritionist, $room);
        abort_if($this->isClosed($room), 422, 'Konsultasi sudah selesai.');

        $data = $request->validate([
            'food_id' => ['required', Rule::exists('makanan', 'id')->where('status_menu', 'Published')],
            'manual_note' => ['nullable', 'string', 'max:1000'],
        ]);

        $food = Makanan::query()->findOrFail($data['food_id']);
        $text = "Rekomendasi makanan:\n{$food->nama}\nKategori: {$food->kategori_status}\nPorsi/usia: ".($food->usia_kategori ?: "{$food->usia_min}-{$food->usia_max} bulan")."\nAlasan: {$food->alasan}";
        if (! empty($data['manual_note'])) {
            $text .= "\nCatatan ahli gizi: ".$data['manual_note'];
        }

        $this->appendExpertMessage($room, $text);

        return redirect()->route('nutritionist.consultations', ['room' => $room->id])->with('success', 'Rekomendasi dikirim ke chat.');
    }

    public function articles(Request $request): View
    {
        $nutritionist = $this->nutritionist($request);
        $mode = (string) ($request->route('mode') ?? 'manage');
        $q = trim((string) $request->query('q', ''));
        $category = (string) $request->query('category', 'Semua');
        $archive = strtolower((string) $request->query('archive', 'aktif'));
        $archive = match ($archive) {
            'arsip', 'diarsipkan', 'archived' => 'arsip',
            'semua', 'all' => 'semua',
            default => 'aktif',
        };
        $roomId = (int) $request->query('room');

        $baseArticles = Article::query()
            ->when($mode === 'manage', fn ($query) => $query->where('created_by', $request->user()->id))
            ->when($mode === 'send', fn ($query) => $query->where('published', true)->where('status', 'Published'));

        if ($mode === 'manage') {
            $baseArticles
                ->when($archive === 'arsip', fn ($query) => $query->where('status', 'Archived'))
                ->when($archive === 'aktif', fn ($query) => $query->where('status', '!=', 'Archived'));
        }

        $articleSummary = [
            'total' => (clone $baseArticles)->count(),
            'published' => (clone $baseArticles)->where('status', 'Published')->count(),
            'pending' => (clone $baseArticles)->where('status', 'Menunggu Verifikasi')->count(),
            'draft' => (clone $baseArticles)->where('status', 'Draft')->count(),
        ];

        $articles = (clone $baseArticles)
            ->when($q !== '', fn ($query) => $query->where(fn ($where) => $where
                ->where('title', 'like', "%{$q}%")
                ->orWhere('excerpt', 'like', "%{$q}%")
                ->orWhere('content', 'like', "%{$q}%")))
            ->when($category !== 'Semua', fn ($query) => $query->where('category', $category))
            ->latest('published_at')
            ->paginate(10)
            ->withQueryString();

        return view('nutritionist.articles', [
            'articles' => $articles,
            'q' => $q,
            'category' => $category,
            'archive' => $archive,
            'archives' => ['aktif' => 'Aktif', 'arsip' => 'Diarsipkan', 'semua' => 'Semua'],
            'roomId' => $roomId,
            'rooms' => $this->shareableRooms($nutritionist),
            'categories' => Article::query()->whereNotNull('category')->distinct()->pluck('category')->filter()->values(),
            'editingArticle' => $request->integer('edit') ? Article::query()->where('created_by', $request->user()->id)->find($request->integer('edit')) : null,
            'mode' => $mode,
            'articleSummary' => $articleSummary,
        ]);
    }

    public function storeArticle(Request $request): RedirectResponse
    {
        $data = $this->validatedArticle($request);
        $data['thumbnail'] = $this->storeUploadedFile($request, 'thumbnail', 'assets/articles', 'artikel');
        $data['created_by'] = $request->user()->id;
        $data['status'] = $request->input('action') === 'draft' ? 'Draft' : 'Menunggu Verifikasi';
        $data['published'] = $data['status'] === 'Published';
        $data['published_at'] = $data['published'] ? now() : null;
        $data['author'] = $request->user()->name ?: 'Ahli Gizi S-Gizi';
        $data['slug'] = $this->uniqueArticleSlug($data['title']);
        $data['read_time'] = max(1, (int) ceil(str_word_count(strip_tags($data['content'])) / 200));

        Article::query()->create($data);

        return redirect()->route('nutritionist.articles.manage')->with('success', 'Artikel berhasil disimpan.');
    }

    public function updateArticle(Request $request, Article $article): RedirectResponse
    {
        abort_unless((int) $article->created_by === (int) $request->user()->id, 403);
        abort_unless(in_array($article->status, ['Draft', 'Ditolak'], true), 422, 'Artikel hanya bisa diedit saat Draft atau Ditolak.');

        $data = $this->validatedArticle($request);
        $thumbnail = $this->storeUploadedFile($request, 'thumbnail', 'assets/articles', 'artikel');
        if ($thumbnail) {
            $data['thumbnail'] = $thumbnail;
        }
        $data['status'] = $request->input('action') === 'submit' ? 'Menunggu Verifikasi' : 'Draft';
        $data['published'] = false;
        $data['published_at'] = null;
        $data['slug'] = $article->slug ?: $this->uniqueArticleSlug($data['title']);
        $data['read_time'] = max(1, (int) ceil(str_word_count(strip_tags($data['content'])) / 200));
        $article->update($data);

        return redirect()->route('nutritionist.articles.manage')->with('success', 'Artikel berhasil diperbarui.');
    }

    public function archiveArticle(Request $request, Article $article): RedirectResponse
    {
        abort_unless((int) $article->created_by === (int) $request->user()->id, 403);
        $article->update(['status' => 'Archived', 'published' => false]);

        return back()->with('success', 'Artikel berhasil diarsipkan.');
    }

    public function destroyArticle(Request $request, Article $article): RedirectResponse
    {
        abort_unless((int) $article->created_by === (int) $request->user()->id, 403);
        abort_if($article->status === 'Published', 422, 'Artikel yang sudah dipublikasikan hanya bisa dihapus permanen oleh admin/super admin.');

        $article->delete();

        return redirect()->route('nutritionist.articles.manage')->with('success', 'Artikel berhasil dihapus permanen.');
    }

    public function shareArticle(Request $request, ConsultationRoom $room): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        $this->abortUnlessAssigned($nutritionist, $room);
        abort_if($this->isClosed($room), 422, 'Konsultasi sudah selesai.');

        $data = $request->validate([
            'article_id' => ['required', Rule::exists('articles', 'id')->where('status', 'Published')->where('published', true)],
            'manual_note' => ['nullable', 'string', 'max:1000'],
        ]);
        $article = Article::query()->findOrFail($data['article_id']);
        $text = "Artikel edukasi:\n{$article->title}\nKategori: {$article->category}\nRingkasan: ".($article->excerpt ?: strip_tags(substr($article->content, 0, 180)));
        if (! empty($data['manual_note'])) {
            $text .= "\nCatatan ahli gizi: ".$data['manual_note'];
        }

        $this->appendExpertMessage($room, $text);

        return redirect()->route('nutritionist.consultations', ['room' => $room->id])->with('success', 'Artikel dibagikan ke chat.');
    }

    public function notifications(Request $request): View
    {
        $nutritionist = $this->nutritionist($request);
        $filter = (string) $request->query('filter', 'Semua');
        $query = $this->notificationQuery($nutritionist)->with(['room.user', 'child'])->latest();

        $query->when($filter === 'Belum dibaca', fn ($q) => $q->where('is_read', false))
            ->when($filter === 'Risiko tinggi', fn ($q) => $q->where('priority', 'Risiko Tinggi'))
            ->when($filter === 'Perlu dipantau', fn ($q) => $q->where('priority', 'Perlu Dipantau'))
            ->when($filter === 'Perlu ukur ulang', fn ($q) => $q->where('priority', 'Perlu Ukur Ulang'));

        return view('nutritionist.notifications', [
            'notifications' => $query->paginate(12)->withQueryString(),
            'filter' => $filter,
            'filters' => ['Semua', 'Belum dibaca', 'Risiko tinggi', 'Perlu dipantau', 'Perlu ukur ulang'],
        ]);
    }

    public function readNotification(Request $request, NutritionistNotification $notification): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        abort_unless($notification->nutritionist_id === $nutritionist->id, 403);
        $notification->update(['is_read' => true]);

        return $notification->consultation_room_id
            ? redirect()->route('nutritionist.consultations', ['room' => $notification->consultation_room_id])
            : back();
    }

    public function readAllNotifications(Request $request): RedirectResponse
    {
        $nutritionist = $this->nutritionist($request);
        $this->notificationQuery($nutritionist)->update(['is_read' => true]);

        return back()->with('success', 'Semua notifikasi ditandai dibaca.');
    }

    public function profile(Request $request): View
    {
        return view('nutritionist.profile', [
            'user' => $request->user(),
            'nutritionist' => $this->nutritionist($request),
        ]);
    }

    public function updateProfile(Request $request): RedirectResponse
    {
        $user = $request->user();
        $nutritionist = $this->nutritionist($request);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['nullable', 'email', 'max:150', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:30'],
            'title' => ['nullable', 'string', 'max:80'],
            'specialization' => ['nullable', Rule::in($this->specializationOptions())],
            'bio' => ['nullable', 'string', 'max:2000'],
            'avatar' => ['nullable', 'image', 'max:3072'],
        ]);

        $userData = $request->only(['name', 'email', 'phone']);
        $avatar = $this->storeUploadedFile($request, 'avatar', 'assets/avatars', 'avatar');
        if ($avatar) {
            $userData['avatar'] = $avatar;
        }

        $user->update($userData);
        $nutritionist->update($request->only(['title', 'specialization', 'bio']));

        return back()->with('success', 'Profil diperbarui.');
    }

    public function updateStatus(Request $request): RedirectResponse
    {
        $data = $request->validate(['is_available' => ['required', 'boolean']]);
        $this->nutritionist($request)->update(['is_available' => (bool) $data['is_available']]);

        return back()->with('success', 'Status konsultasi diperbarui.');
    }

    public function updatePassword(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', 'min:8'],
        ]);
        abort_unless(Hash::check($data['current_password'], (string) $request->user()->password), 422, 'Password lama tidak sesuai.');
        $request->user()->update(['password' => $data['password']]);

        return back()->with('success', 'Password diperbarui.');
    }

    private function nutritionist(Request $request): Nutritionist
    {
        return $request->user()->nutritionist()->firstOrFail();
    }

    private function assignedRooms(Nutritionist $nutritionist)
    {
        $expertId = $this->expertId($nutritionist);

        return ConsultationRoom::query()->where('expert_id', $expertId);
    }

    private function shareableRooms(Nutritionist $nutritionist): Collection
    {
        return $this->assignedRooms($nutritionist)
            ->with(['user', 'child'])
            ->where('status', '!=', 'closed')
            ->latest('last_message_at')
            ->get();
    }

    private function abortUnlessAssigned(Nutritionist $nutritionist, ConsultationRoom $room): void
    {
        abort_unless($room->expert_id === $this->expertId($nutritionist), 403);
    }

    private function expertId(Nutritionist $nutritionist): string
    {
        return trim((string) ($nutritionist->expert_id ?: 'expert-'.$nutritionist->user_id));
    }

    private function roomRow(ConsultationRoom $room, bool $withRoom = false): array
    {
        $summary = $this->childSummary($room->child);
        $lastSender = $room->messages->sortByDesc('created_at')->first()?->sender_type;

        return [
            'room' => $withRoom ? $room : $room,
            'parent_name' => $room->user?->name ?? 'Orang Tua',
            'child_name' => $room->child?->nama ?? $room->child?->nama_anak ?? '-',
            'age' => $summary['age_label'],
            'risk' => $summary['risk'],
            'validation' => $summary['validation'],
            'status' => $this->normalizeRoomStatus($room->status),
            'last_message' => $room->last_message ?: 'Belum ada pesan terbaru',
            'last_message_at' => $room->last_message_at,
            'unread_count' => $room->messages()->where('sender_type', 'parent')->where('is_read', false)->count(),
            'needs_reply' => $lastSender === 'parent' || $room->messages()->where('sender_type', 'parent')->where('is_read', false)->exists(),
        ];
    }

    private function childSummary(?Child $child): array
    {
        $latest = $child?->measurements?->sortByDesc('tanggal_ukur')->first()
            ?? $child?->latestMeasurement;
        $status = NutritionStatusHelper::getStatus($latest);

        return [
            'age_label' => $this->ageLabel($child),
            'weight' => $latest ? number_format((float) $latest->berat, 1).' kg' : '-',
            'height' => $latest ? number_format((float) $latest->tinggi, 1).' cm' : '-',
            'date' => $latest?->tanggal_ukur?->format('d/m/Y') ?? '-',
            'bbu' => NutritionStatusHelper::bbuStatus($latest),
            'tbu' => NutritionStatusHelper::tbuStatus($latest),
            'bbtb' => NutritionStatusHelper::bbtbStatus($latest),
            'status' => $status,
            'risk' => NutritionStatusHelper::riskLabel($status),
            'validation' => $latest?->validation_status ?: ($latest?->is_anomaly ? 'Perlu Ukur Ulang' : 'Valid'),
            'latest' => $latest,
        ];
    }

    private function ageLabel(?Child $child): string
    {
        if (! $child?->tanggal_lahir) {
            return '-';
        }

        $months = max(0, (int) $child->tanggal_lahir->diffInMonths(now()));
        $years = intdiv($months, 12);
        $remainingMonths = $months % 12;

        if ($years > 0 && $remainingMonths > 0) {
            return "{$years} tahun {$remainingMonths} bulan";
        }

        if ($years > 0) {
            return "{$years} tahun";
        }

        return "{$months} bulan";
    }

    private function normalizeRoomStatus(?string $status): string
    {
        return match ($status) {
            'closed', 'selesai' => 'closed',
            'waiting', 'waiting_reply', 'menunggu' => 'waiting_reply',
            default => 'active',
        };
    }

    private function isClosed(ConsultationRoom $room): bool
    {
        return $this->normalizeRoomStatus($room->status) === 'closed';
    }

    private function appendExpertMessage(ConsultationRoom $room, string $message): void
    {
        $created = $room->messages()->create([
            'sender_type' => 'expert',
            'message' => $message,
            'is_read' => false,
        ]);

        $room->update([
            'last_message' => $created->message,
            'last_message_at' => now(),
        ]);
    }

    private function notify(Nutritionist $nutritionist, ConsultationRoom $room, string $type, string $title, string $description, string $priority): void
    {
        NutritionistNotification::query()->create([
            'nutritionist_id' => $nutritionist->id,
            'consultation_room_id' => $room->id,
            'child_id' => $room->child_id,
            'type' => $type,
            'title' => $title,
            'description' => $description,
            'priority' => $priority,
            'is_read' => false,
        ]);
    }

    private function notificationQuery(Nutritionist $nutritionist)
    {
        return NutritionistNotification::query()->where('nutritionist_id', $nutritionist->id);
    }

    private function validatedFood(Request $request): array
    {
        $data = $request->validate([
            'thumbnail' => ['nullable', 'image', 'max:3072'],
            'nama' => ['required', 'string', 'max:255'],
            'kategori_status' => ['required', 'string', 'max:100'],
            'usia_min' => ['required', 'integer', 'min:0'],
            'usia_max' => ['required', 'integer', 'min:0'],
            'usia_kategori' => ['required', 'string', 'max:40'],
            'kalori' => ['required', 'integer', 'min:0'],
            'protein' => ['required', 'integer', 'min:0'],
            'lemak' => ['required', 'integer', 'min:0'],
            'karbohidrat' => ['required', 'integer', 'min:0'],
            'serat' => ['required', 'integer', 'min:0'],
            'gula' => ['required', 'integer', 'min:0'],
            'badges_input' => ['nullable', 'string', 'max:255'],
            'status_menu' => ['nullable', 'string', 'max:30'],
            'prioritas_menu' => ['required', 'string', 'max:40'],
            'alasan' => ['required', 'string'],
            'bahan' => ['nullable', 'string'],
            'cara_memasak' => ['nullable', 'string'],
        ]);

        $data['badges'] = collect(explode(',', (string) ($data['badges_input'] ?? '')))
            ->map(fn ($badge) => trim($badge))
            ->filter()
            ->values()
            ->all();
        unset($data['badges_input'], $data['thumbnail']);

        return $data;
    }

    private function validatedArticle(Request $request): array
    {
        $data = $request->validate([
            'thumbnail' => ['nullable', 'image', 'max:3072'],
            'title' => ['required', 'string', 'max:180'],
            'category' => ['required', 'string', 'max:80'],
            'excerpt' => ['nullable', 'string', 'max:260'],
            'tags_input' => ['nullable', 'string', 'max:255'],
            'content' => ['required', 'string'],
        ]);

        $data['tags'] = collect(explode(',', (string) ($data['tags_input'] ?? '')))
            ->map(fn ($tag) => trim($tag))
            ->filter()
            ->values()
            ->all();
        unset($data['tags_input'], $data['thumbnail']);

        return $data;
    }

    private function storeUploadedFile(Request $request, string $field, string $directory, string $prefix): ?string
    {
        if (! $request->hasFile($field)) {
            return null;
        }

        $target = public_path($directory);
        if (! is_dir($target)) {
            mkdir($target, 0755, true);
        }

        $file = $request->file($field);
        $filename = $prefix.'-'.now()->format('YmdHis').'-'.Str::random(8).'.'.$file->getClientOriginalExtension();
        $file->move($target, $filename);

        return trim($directory, '/').'/'.$filename;
    }

    private function uniqueArticleSlug(string $title): string
    {
        $base = Str::slug($title) ?: 'artikel-sgizi';
        $slug = $base;
        $counter = 2;

        while (Article::query()->where('slug', $slug)->exists()) {
            $slug = $base.'-'.$counter++;
        }

        return $slug;
    }

    private function specializationOptions(): array
    {
        return ['Stunting', 'Gizi Kurang', 'MPASI', 'Obesitas Anak', 'Tumbuh Kembang', 'Konsultasi Umum'];
    }
}
