import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../app_design.dart';
import '../app_state.dart';
import '../models/riwayat_response_model.dart';
import '../services/api_service.dart';
import '../services/local_notification_service.dart';
import '../utils/nutrition_display_utils.dart';

enum ConsultationStatus { aktif, menunggu, selesai }

class _Expert {
  const _Expert({
    required this.id,
    required this.name,
    required this.specialization,
    required this.focusTag,
    required this.assetImage,
    required this.online,
    required this.rating,
    required this.experience,
    this.recommended = false,
    this.reason = '',
  });

  final String id;
  final String name;
  final String specialization;
  final String focusTag;
  final String assetImage;
  final bool online;
  final double rating;
  final String experience;
  final bool recommended;
  final String reason;

  _Expert copyWith({
    bool? recommended,
    String? reason,
  }) {
    return _Expert(
      id: id,
      name: name,
      specialization: specialization,
      focusTag: focusTag,
      assetImage: assetImage,
      online: online,
      rating: rating,
      experience: experience,
      recommended: recommended ?? this.recommended,
      reason: reason ?? this.reason,
    );
  }
}

class _RoomVm {
  const _RoomVm({
    required this.id,
    required this.keyId,
    required this.childName,
    required this.expert,
    required this.status,
    required this.lastMessage,
    required this.updatedAt,
    required this.unread,
  });

  final int id;
  final String keyId;
  final String childName;
  final _Expert expert;
  final ConsultationStatus status;
  final String lastMessage;
  final DateTime updatedAt;
  final int unread;

  _RoomVm copyWith({
    ConsultationStatus? status,
  }) {
    return _RoomVm(
      id: id,
      keyId: keyId,
      childName: childName,
      expert: expert,
      status: status ?? this.status,
      lastMessage: lastMessage,
      updatedAt: updatedAt,
      unread: unread,
    );
  }
}

class _MsgVm {
  const _MsgVm({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.fromUser,
    this.read = true,
    this.analysis = false,
  });

  final int id;
  final String text;
  final DateTime createdAt;
  final bool fromUser;
  final bool read;
  final bool analysis;
}

class ConsultationChatScreen extends StatefulWidget {
  const ConsultationChatScreen({
    super.key,
    this.showAppBar = true,
    this.roomKey,
  });

  final bool showAppBar;
  final String? roomKey;

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final _api = ApiService();
  final _app = SgiziAppState.instance;
  final _search = TextEditingController();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  Timer? _roomPoll;
  bool _isPolling = false;
  bool _loadingMessages = false;
  int? _pollingRoomId;
  bool _loading = true;
  bool _sending = false;
  bool _openingChat = false;
  RiwayatItemModel? _latest;

  List<_Expert> _experts = const [];
  List<_RoomVm> _rooms = const [];
  List<_MsgVm> _messages = const [];
  _RoomVm? _activeRoom;

  @override
  void initState() {
    super.initState();
    _reloadEverything();
  }

  @override
  void dispose() {
    _stopPolling();
    _search.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reloadEverything() async {
    _stopPolling();
    setState(() => _loading = true);

    final child = _app.activeChild;
    if (child == null) {
      setState(() {
        _loading = false;
        _rooms = const [];
        _messages = const [];
        _activeRoom = null;
      });
      return;
    }

    try {
      final history = await _api.getRiwayat(childId: child.id);
      final sorted = [...history.riwayat]..sort((a, b) {
          final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
          final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
          return bd.compareTo(ad);
        });
      _latest = sorted.isEmpty ? null : sorted.first;
    } catch (_) {
      _latest = null;
    }

    _experts = _recommendedExperts(_latest?.statusGabungan ?? '');
    await _loadRooms();

    if (widget.roomKey != null) {
      _activeRoom = _rooms.where((e) => e.keyId == widget.roomKey).firstOrNull;
      final roomId = _activeRoom?.id;
      if (roomId != null) await _loadMessages(roomId);
    } else {
      _activeRoom = null;
      _messages = const [];
    }

    _startPolling();
    setState(() => _loading = false);
  }

  Future<void> _loadRooms() async {
    final child = _app.activeChild;
    if (child == null) {
      _rooms = const [];
      return;
    }
    try {
      final rows = await _api.getConsultationRooms(childId: child.id);
      _rooms = rows.map(_roomFromApi).toList();
    } catch (_) {
      _rooms = const [];
    }
  }

  Future<bool> _loadMessages(int roomId) async {
    if (_loadingMessages) return false;
    _loadingMessages = true;
    try {
      final rows = await _api.getConsultationMessages(roomId: roomId);
      final activeRoomId = _activeRoom?.id;
      if (activeRoomId != null && activeRoomId != roomId) return false;
      final oldLength = _messages.length;
      final next = rows.map(_msgFromApi).toList();
      final changed = next.length != oldLength;
      _messages = next;
      return changed;
    } catch (_) {
      _messages = const [];
      return true;
    } finally {
      _loadingMessages = false;
    }
  }

  void _startPolling() {
    final activeRoom = _activeRoom;
    if (activeRoom == null) {
      _stopPolling();
      return;
    }

    final roomId = activeRoom.id;
    if (_isPolling && _pollingRoomId == roomId) return;

    _isPolling = true;
    _pollingRoomId = roomId;

    _roomPoll?.cancel();
    _roomPoll = Timer.periodic(const Duration(seconds: 3), (_) async {
      final room = _activeRoom;
      if (!mounted || room == null) return;
      if (_loadingMessages) return;
      try {
        final changed = await _loadMessages(room.id);
        if (mounted && changed) {
          setState(() {});
          _jumpBottom();
        }
      } catch (e) {
        debugPrint('Polling Error: $e');
      }
    });
  }

  void _stopPolling() {
    _roomPoll?.cancel();
    _roomPoll = null;
    _isPolling = false;
    _pollingRoomId = null;
  }

  List<_Expert> _recommendedExperts(String status) {
    final n = normalizeStatus(status);
    String reasonFor(_Expert e) {
      if (n.hasStunting && e.focusTag == 'growth') {
        return 'Direkomendasikan berdasarkan hasil analisis tumbuh kembang anak.';
      }
      if (n.hasObesitas && e.focusTag == 'obesity') {
        return 'Direkomendasikan berdasarkan pola makan dan obesitas anak.';
      }
      if ((n.hasUnderweight || n.hasWasting) && e.focusTag == 'weight') {
        return 'Direkomendasikan berdasarkan kebutuhan peningkatan berat badan.';
      }
      return 'Tersedia untuk konsultasi nutrisi umum anak.';
    }

    bool isMatch(_Expert e) {
      if (n.hasStunting) return e.focusTag == 'growth';
      if (n.hasObesitas) return e.focusTag == 'obesity';
      if (n.hasUnderweight || n.hasWasting) return e.focusTag == 'weight';
      return e.focusTag == 'general';
    }

    const base = [
      _Expert(
        id: 'exp-1',
        name: 'dr. Siti Rahma, S.Gz',
        specialization: 'Tumbuh Kembang Anak',
        focusTag: 'growth',
        assetImage: 'assets/image/onboarding_monitoring.png',
        online: true,
        rating: 4.9,
        experience: '8 tahun',
      ),
      _Expert(
        id: 'exp-2',
        name: 'dr. Rina Kurnia, M.Gz',
        specialization: 'MPASI & Nutrisi Balita',
        focusTag: 'general',
        assetImage: 'assets/image/onboarding_food.png',
        online: true,
        rating: 4.8,
        experience: '6 tahun',
      ),
      _Expert(
        id: 'exp-3',
        name: 'dr. Aditya Pratama, S.Gz',
        specialization: 'Obesitas Anak',
        focusTag: 'obesity',
        assetImage: 'assets/image/onboarding_consultation.png',
        online: false,
        rating: 4.7,
        experience: '7 tahun',
      ),
      _Expert(
        id: 'exp-4',
        name: 'dr. Nabila Utami, S.Gz',
        specialization: 'Peningkatan Berat Badan Anak',
        focusTag: 'weight',
        assetImage: 'assets/image/onboarding_food.png',
        online: true,
        rating: 4.8,
        experience: '5 tahun',
      ),
    ];

    return [
      for (final e in base)
        e.copyWith(
          recommended: isMatch(e),
          reason: reasonFor(e),
        ),
    ];
  }

  List<String> _quickReplies() {
    final n = normalizeStatus(_latest?.statusGabungan ?? '');
    if (n.hasStunting) {
      return const [
        'Menu tinggi protein',
        'Cara menaikkan tinggi badan',
        'Anak susah makan',
      ];
    }
    if (n.hasObesitas) {
      return const [
        'Mengurangi gula anak',
        'Aktivitas fisik anak',
        'Porsi makan sehat',
      ];
    }
    if (n.hasUnderweight || n.hasWasting) {
      return const [
        'Cara menaikkan berat badan',
        'Menu tinggi kalori sehat',
      ];
    }
    return const ['Pola makan sehat', 'Konsultasi tumbuh kembang'];
  }

  Future<void> _openOrCreateRoom(_Expert expert) async {
    if (_openingChat) return;
    _openingChat = true;
    final child = _app.activeChild;
    if (child == null) {
      _openingChat = false;
      return;
    }
    try {
      final room = await _api.openConsultationRoom(
        childId: child.id,
        expertId: expert.id,
        expertName: expert.name,
        specialization: expert.specialization,
        assetImage: expert.assetImage,
        online: expert.online,
      );
      final roomVm = _roomFromApi(room);
      _activeRoom = roomVm;
      await _loadMessages(roomVm.id);

      final latest = _latest;
      if (_messages.isEmpty && latest != null) {
        final normalized = normalizeStatus(latest.statusGabungan);
        final analysisText =
            'Hasil Analisis Anak\n\n'
            'Nama: ${child.nama}\n'
            'Umur: ${formatAgeFromMonths(latest.umurBulan)}\n'
            'Status Utama: ${normalized.primaryCategory}\n'
            'Status Tambahan: ${normalized.categories.skip(1).join(', ')}\n'
            'BB/U: ${bbuCategoryFromScore(latest.zBbu, fallback: latest.kategori.bbu)}\n'
            'TB/U: ${formatScore(latest.zTbu)}\n'
            'BB/TB: ${formatScore(latest.zBbtb)}';
        await _api.sendConsultationMessage(roomId: roomVm.id, message: analysisText);
        await _loadMessages(roomVm.id);
      }

      await _loadRooms();
      _startPolling();
      setState(() {});
      _jumpBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka room konsultasi.')),
      );
    } finally {
      _openingChat = false;
    }
  }

  Future<void> _enterExistingRoom(_RoomVm room) async {
    if (_openingChat) return;
    _openingChat = true;
    try {
      _activeRoom = room;
      await _loadMessages(room.id);
      _startPolling();
      if (mounted) {
        setState(() {});
        _jumpBottom();
      }
    } finally {
      _openingChat = false;
    }
  }

  ConsultationStatus _statusFromApi(String raw) {
    switch (raw.toLowerCase()) {
      case 'menunggu':
        return ConsultationStatus.menunggu;
      case 'selesai':
        return ConsultationStatus.selesai;
      default:
        return ConsultationStatus.aktif;
    }
  }

  _RoomVm _roomFromApi(Map<String, dynamic> json) {
    return _RoomVm(
      id: (json['id'] as num?)?.toInt() ?? 0,
      keyId:
          '${(json['child_id'] as num?)?.toInt() ?? 0}::${json['expert_id'] ?? ''}',
      childName: (json['child_name'] as String?) ?? '-',
      expert: _Expert(
        id: (json['expert_id'] as String?) ?? '',
        name: (json['expert_name'] as String?) ?? '',
        specialization: (json['specialization'] as String?) ?? '',
        focusTag: 'general',
        assetImage: (json['asset_image'] as String?)?.isNotEmpty == true
            ? (json['asset_image'] as String)
            : 'assets/image/onboarding_consultation.png',
        online: (json['online'] as bool?) ?? false,
        rating: 4.8,
        experience: '5 tahun',
      ),
      status: _statusFromApi((json['status'] as String?) ?? 'aktif'),
      lastMessage: (json['last_message'] as String?) ?? '',
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String?) ?? '') ?? DateTime.now(),
      unread: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  _MsgVm _msgFromApi(Map<String, dynamic> json) {
    final sender = ((json['sender_type'] as String?) ?? 'parent').toLowerCase();
    final text = (json['message'] as String?) ?? '';
    return _MsgVm(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: text,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ?? DateTime.now(),
      fromUser: sender == 'parent',
      read: (json['is_read'] as bool?) ?? true,
      analysis: text.startsWith('Hasil Analisis Anak'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: widget.showAppBar
            ? AppBar(title: const Text('Konsultasi Ahli Gizi'))
            : null,
        body: const _ConsultationShimmer(),
      );
    }
    if (_activeRoom != null) return _buildChatRoom();
    return _buildConsultationHome();
  }

  Widget _buildConsultationHome() {
    final child = _app.activeChild;
    final query = _search.text.toLowerCase().trim();
    final filteredExperts = _experts.where((e) {
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
          e.specialization.toLowerCase().contains(query);
    }).toList();
    final recommended = filteredExperts.where((e) => e.recommended).toList();
    final others = filteredExperts.where((e) => !e.recommended).toList();

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Konsultasi Ahli Gizi'),
              actions: [
                IconButton(
                  onPressed: child == null
                      ? null
                      : () => Navigator.of(context).push(
                            fadeRoute(const _HistoryScreen()),
                          ),
                  icon: const Icon(LucideIcons.history),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: child == null
            ? const EmptyState(
                title: 'Belum Ada Anak Aktif',
                message: 'Pilih anak aktif terlebih dahulu untuk memulai konsultasi.',
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konsultasikan tumbuh kembang si kecil bersama ahli gizi terpercaya.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(LucideIcons.search),
                        hintText: 'Cari ahli gizi...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Direkomendasikan Untuk Anda', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    if (recommended.isEmpty)
                      const HealthCard(
                        child: Text('Belum ada ahli rekomendasi untuk status anak saat ini.'),
                      )
                    else
                      ...recommended.map(
                        (e) => _RecommendedCard(
                          expert: e,
                          onChat: () => _openOrCreateRoom(e),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text('Riwayat Konsultasi', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    if (_rooms.isEmpty)
                      const HealthCard(child: Text('Belum ada riwayat konsultasi.'))
                    else
                      ..._rooms.take(3).map(
                            (room) => _HistoryTile(
                              room: room,
                              onTap: () => _enterExistingRoom(room),
                            ),
                          ),
                    const SizedBox(height: 8),
                    Text('Ahli Gizi Lainnya', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    ...others.map(
                      (e) => _ExpertTile(
                        expert: e,
                        onChat: () => _openOrCreateRoom(e),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.02, end: 0),
      ),
    );
  }

  Widget _buildChatRoom() {
    final room = _activeRoom;
    if (room == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final grouped = _groupByDate(_messages);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              room: room,
              onBack: () {
                _stopPolling();
                setState(() {
                  _activeRoom = null;
                });
              },
              onFinish: () async {
                await _api.updateConsultationRoomStatus(
                  roomId: room.id,
                  status: 'selesai',
                );
                await _loadRooms();
                setState(() {
                  _activeRoom = room.copyWith(status: ConsultationStatus.selesai);
                });
              },
            ),
            Expanded(
              child: grouped.isEmpty
                  ? const _ChatEmpty()
                  : ListView.builder(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(),
                      cacheExtent: 600,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final item = grouped[i];
                        if (item.date != null) return _DateBadge(item.date!);
                        if (item.message == null) return const SizedBox.shrink();
                        return _MessageBubble(message: item.message!, expert: room.expert);
                      },
                    ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (_, i) {
                  final quick = _quickReplies()[i];
                  final chipWidth = _quickChipWidth(quick);
                  return SizedBox(
                    width: chipWidth,
                    child: Material(
                      color: const Color(0xFFF3F8F9),
                      borderRadius: BorderRadius.circular(99),
                      elevation: 1,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: () {
                          _input.text = quick;
                          _input.selection = TextSelection.collapsed(
                            offset: _input.text.length,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Text(
                            quick,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF0B7A86),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: _quickReplies().length,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Tulis pesan...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        maximumSize: const Size(48, 48),
                        fixedSize: const Size(48, 48),
                        shape: const CircleBorder(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Icon(LucideIcons.send, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final room = _activeRoom;
    if (room == null) return;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    try {
      await _api.sendConsultationMessage(roomId: room.id, message: text);
      _input.clear();
      await _loadMessages(room.id);
      await _loadRooms();
      _jumpBottom();
      _triggerServerExpertAutoReply(room);
      await LocalNotificationService.instance.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Pesan konsultasi terkirim',
        body: room.expert.name,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim pesan.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _triggerServerExpertAutoReply(_RoomVm room) {
    Future<void>.delayed(const Duration(milliseconds: 1200), () async {
      if (!mounted || _activeRoom?.id != room.id) return;
      final text = _buildAutoReplyText(room);
      try {
        await _api.sendConsultationExpertReply(roomId: room.id, message: text);
      } catch (_) {
        // Abaikan error auto-reply agar tidak mengganggu alur kirim parent.
      }
    });
  }

  String _buildAutoReplyText(_RoomVm room) {
    final status = normalizeStatus(_latest?.statusGabungan ?? '')
        .primaryCategory
        .toLowerCase();
    if (status.contains('stunting')) {
      return 'Terima kasih Bunda. Untuk kondisi stunting, fokuskan protein hewani 2x/hari dan evaluasi porsi selama 7 hari ke depan.';
    }
    if (status.contains('obes') || status.contains('gemuk')) {
      return 'Baik Bunda, untuk kondisi ini kita atur porsi dan jadwal camilan. Hindari minuman manis kemasan selama pemantauan minggu ini.';
    }
    if (status.contains('kurang') || status.contains('under')) {
      return 'Siap Bunda, kita tingkatkan asupan energi secara bertahap. Mohon catat frekuensi makan utama dan selingan selama 3 hari.';
    }
    return 'Terima kasih sudah berkonsultasi. Saya akan bantu review pola makan anak, silakan kirim jadwal makan harian terbaru.';
  }

  void _jumpBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if ((_scroll.offset - target).abs() < 2) return;
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  double _quickChipWidth(String text) {
    final estimate = 56 + (text.length * 7.2);
    return math.min(220, math.max(80, estimate));
  }
}

class _HistoryScreen extends StatefulWidget {
  const _HistoryScreen();

  @override
  State<_HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<_HistoryScreen> {
  final _api = ApiService();
  final _app = SgiziAppState.instance;
  List<_RoomVm> _rooms = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final child = _app.activeChild;
    if (child == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _rooms = const [];
      });
      return;
    }
    try {
      final rows = await _api.getConsultationRooms(childId: child.id);
      if (!mounted) return;
      setState(() {
        _rooms = rows.map((json) {
          final status = ((json['status'] as String?) ?? 'aktif').toLowerCase();
          ConsultationStatus state = ConsultationStatus.aktif;
          if (status == 'menunggu') state = ConsultationStatus.menunggu;
          if (status == 'selesai') state = ConsultationStatus.selesai;
          return _RoomVm(
            id: (json['id'] as num?)?.toInt() ?? 0,
            keyId:
                '${(json['child_id'] as num?)?.toInt() ?? 0}::${json['expert_id'] ?? ''}',
            childName: (json['child_name'] as String?) ?? '-',
            expert: _Expert(
              id: (json['expert_id'] as String?) ?? '',
              name: (json['expert_name'] as String?) ?? '',
              specialization: (json['specialization'] as String?) ?? '',
              focusTag: 'general',
              assetImage: (json['asset_image'] as String?)?.isNotEmpty == true
                  ? (json['asset_image'] as String)
                  : 'assets/image/onboarding_consultation.png',
              online: (json['online'] as bool?) ?? false,
              rating: 4.8,
              experience: '5 tahun',
            ),
            status: state,
            lastMessage: (json['last_message'] as String?) ?? '',
            updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
                DateTime.now(),
            unread: (json['unread_count'] as num?)?.toInt() ?? 0,
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Konsultasi')),
      body: SafeArea(
        child: _loading
            ? const _ConsultationShimmer()
            : _rooms.isEmpty
                ? const EmptyState(
                    title: 'Belum Ada Konsultasi',
                    message:
                        'Belum ada konsultasi. Mulai konsultasi pertama Anda bersama ahli gizi terpercaya.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (_, i) => _HistoryTile(
                      room: _rooms[i],
                      onTap: () => Navigator.of(context).push(
                        fadeRoute(ConsultationChatScreen(roomKey: _rooms[i].keyId)),
                      ),
                    ),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemCount: _rooms.length,
                  ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.expert, required this.onChat});
  final _Expert expert;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: const Color(0xFF0B7A86),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              expert.assetImage,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3,
                ),
                Text(expert.specialization, style: AppTypography.caption),
                Text(
                  expert.reason,
                  style: AppTypography.caption.copyWith(color: const Color(0xFF0B7A86)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(onPressed: onChat, child: const Text('Chat')),
        ],
      ),
    );
  }
}

class _ExpertTile extends StatelessWidget {
  const _ExpertTile({required this.expert, required this.onChat});
  final _Expert expert;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              expert.assetImage,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3,
                ),
                Text(expert.specialization, style: AppTypography.caption),
              ],
            ),
          ),
          OutlinedButton(onPressed: onChat, child: const Text('Chat')),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.room, required this.onTap});
  final _RoomVm room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final last = room.lastMessage.isEmpty ? '-' : room.lastMessage;
    return HealthCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              room.expert.assetImage,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.expert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3,
                ),
                Text(room.childName, style: AppTypography.caption),
                Text(
                  last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
          _StatusBadge(room.status),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.room,
    required this.onBack,
    required this.onFinish,
  });

  final _RoomVm room;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1E8E6)),
          ),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(LucideIcons.chevronLeft)),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  room.expert.assetImage,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.expert.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3,
                    ),
                    Text(
                      room.expert.specialization,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              _StatusBadge(room.status),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'finish') onFinish();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'finish', child: Text('Selesaikan')),
                ],
                icon: const Icon(LucideIcons.moreVertical),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.expert});
  final _MsgVm message;
  final _Expert expert;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                expert.assetImage,
                width: 26,
                height: 26,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: message.analysis
                      ? const Color(0xFFE8F7F1)
                      : isUser
                          ? const Color(0xFF0B7A86)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: message.analysis
                        ? const Color(0xFF0B7A86)
                        : const Color(0xFFE1E8E6),
                  ),
                ),
                child: message.analysis
                    ? _AnalysisBubbleContent(rawText: message.text)
                    : Text(
                        message.text,
                        softWrap: true,
                        style: AppTypography.body.copyWith(
                          color: isUser ? Colors.white : SgColors.textPrimary,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(_fmtTime(message.createdAt), style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final ConsultationStatus status;

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color color;
    switch (status) {
      case ConsultationStatus.aktif:
        text = 'Aktif';
        color = const Color(0xFF34A853);
        break;
      case ConsultationStatus.menunggu:
        text = 'Menunggu Balasan';
        color = const Color(0xFFF59E0B);
        break;
      case ConsultationStatus.selesai:
        text = 'Selesai';
        color = const Color(0xFF9CA3AF);
        break;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnalysisBubbleContent extends StatelessWidget {
  const _AnalysisBubbleContent({required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.toLowerCase().contains('hasil analisis anak'))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil Analisis Anak',
          style: AppTypography.h3.copyWith(color: Colors.black87),
        ),
        const SizedBox(height: 8),
        ...lines.map((line) {
          final idx = line.indexOf(':');
          if (idx == -1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: AppTypography.body.copyWith(color: Colors.black87),
              ),
            );
          }
          final key = line.substring(0, idx).trim();
          final value = line.substring(idx + 1).trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                style: AppTypography.body.copyWith(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$key: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1EF),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: AppTypography.caption),
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'Belum Ada Pesan',
      message: 'Mulai konsultasi pertama Anda bersama ahli gizi terpercaya.',
    );
  }
}

class _ConsultationShimmer extends StatelessWidget {
  const _ConsultationShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EEEC),
      highlightColor: const Color(0xFFF7FAF9),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 18, color: Colors.white),
          const SizedBox(height: 10),
          Container(height: 50, color: Colors.white),
          const SizedBox(height: 10),
          Container(height: 120, color: Colors.white),
        ],
      ),
    );
  }
}

class _GroupedMessage {
  const _GroupedMessage.date(this.date) : message = null;
  const _GroupedMessage.message(this.message) : date = null;

  final String? date;
  final _MsgVm? message;
}

List<_GroupedMessage> _groupByDate(List<_MsgVm> source) {
  final sorted = [...source]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final out = <_GroupedMessage>[];
  DateTime? current;
  for (final m in sorted) {
    final d = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
    if (current == null || current != d) {
      out.add(_GroupedMessage.date(_fmtDay(d)));
      current = d;
    }
    out.add(_GroupedMessage.message(m));
  }
  return out;
}

String _fmtDay(DateTime d) {
  final n = DateTime.now();
  final t = DateTime(n.year, n.month, n.day);
  if (d == t) return 'Hari Ini';
  if (d == t.subtract(const Duration(days: 1))) return 'Kemarin';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

