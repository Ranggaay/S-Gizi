import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/services/local_notification_service.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';

enum ConsultationStatus { aktif, menunggu, selesai }

class _Expert {
  const _Expert({
    required this.id,
    required this.name,
    required this.specialization,
    required this.focusTag,
    this.photoUrl = '',
    required this.online,
    required this.rating,
    required this.experience,
    this.consultationCount = 0,
    this.recommended = false,
    this.reason = '',
  });

  final String id;
  final String name;
  final String specialization;
  final String focusTag;
  final String photoUrl;
  final bool online;
  final double rating;
  final String experience;
  final int consultationCount;
  final bool recommended;
  final String reason;

  _Expert copyWith({bool? recommended, String? reason}) {
    return _Expert(
      id: id,
      name: name,
      specialization: specialization,
      focusTag: focusTag,
      photoUrl: photoUrl,
      online: online,
      rating: rating,
      experience: experience,
      consultationCount: consultationCount,
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
    this.lastSharedMeasurementId,
  });

  final int id;
  final String keyId;
  final String childName;
  final _Expert expert;
  final ConsultationStatus status;
  final String lastMessage;
  final DateTime updatedAt;
  final int unread;
  final int? lastSharedMeasurementId;

  _RoomVm copyWith({ConsultationStatus? status, int? lastSharedMeasurementId}) {
    return _RoomVm(
      id: id,
      keyId: keyId,
      childName: childName,
      expert: expert,
      status: status ?? this.status,
      lastMessage: lastMessage,
      updatedAt: updatedAt,
      unread: unread,
      lastSharedMeasurementId:
          lastSharedMeasurementId ?? this.lastSharedMeasurementId,
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
    this.progressUpdate = false,
  });

  final int id;
  final String text;
  final DateTime createdAt;
  final bool fromUser;
  final bool read;
  final bool analysis;
  final bool progressUpdate;
}

class ConsultationChatScreen extends StatefulWidget {
  const ConsultationChatScreen({
    super.key,
    this.showAppBar = true,
    this.roomKey,
    this.roomId,
    this.autoStart = false,
    this.confirmBeforeStart = false,
    this.initialMeasurementId,
    this.initialMessage,
  });

  final bool showAppBar;
  final String? roomKey;
  final int? roomId;
  final bool autoStart;
  final bool confirmBeforeStart;
  final int? initialMeasurementId;
  final String? initialMessage;

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
  bool _sendingProgressUpdate = false;
  bool _autoStartHandled = false;
  RiwayatItemModel? _latest;
  RiwayatItemModel? _previous;

  List<_Expert> _experts = const [];
  List<_RoomVm> _rooms = const [];
  List<_MsgVm> _messages = const [];
  final Set<String> _dismissedProgressUpdates = {};
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
      final sorted = [...history.riwayat]
        ..sort((a, b) {
          final bd = DateTime.tryParse(b.tanggalUkur) ?? DateTime(2000);
          final ad = DateTime.tryParse(a.tanggalUkur) ?? DateTime(2000);
          return bd.compareTo(ad);
        });
      _latest = sorted.isEmpty ? null : sorted.first;
      _previous = sorted.length > 1 ? sorted[1] : null;
    } catch (_) {
      _latest = null;
      _previous = null;
    }

    try {
      final expertRows = await _api.getNutritionists();
      _experts = _recommendedExperts(
        _latest?.statusGabungan ?? '',
        expertRows.map(_expertFromApi).toList(),
      );
    } catch (e) {
      debugPrint('[loadNutritionists.error] $e');
      _experts = const [];
    }
    await _loadRooms();

    final targetRoomId = widget.roomId;
    final targetRoomKey = widget.roomKey;
    if (targetRoomId != null || targetRoomKey != null) {
      _activeRoom = _rooms
          .where(
            (e) =>
                (targetRoomId != null && e.id == targetRoomId) ||
                (targetRoomKey != null && e.keyId == targetRoomKey),
          )
          .firstOrNull;
      final roomId = _activeRoom?.id;
      if (roomId != null) await _loadMessages(roomId);
    } else {
      _activeRoom = null;
      _messages = const [];
    }

    if (widget.autoStart && !_autoStartHandled && _activeRoom == null) {
      await _autoStartConsultation();
    }

    _startPolling();
    setState(() => _loading = false);
    if (_activeRoom != null) _jumpBottom(instant: true);
  }

  Future<void> _autoStartConsultation() async {
    if (_autoStartHandled) return;
    _autoStartHandled = true;
    if (_experts.isEmpty) return;
    final selected = _experts.firstWhere(
      (expert) => expert.recommended,
      orElse: () => _experts.first,
    );
    await _openOrCreateRoom(selected, sendInitialMessage: true);
  }

  Future<void> _handleExpertSelection(_Expert expert) async {
    if (!widget.confirmBeforeStart) {
      await _openOrCreateRoom(expert);
      return;
    }

    final confirmed = await _showStartConsultationDialog(expert);
    if (confirmed != true || !mounted) return;
    await _openOrCreateRoom(expert, sendInitialMessage: true);
  }

  Future<bool?> _showStartConsultationDialog(_Expert expert) {
    final child = _app.activeChild;
    final latest = _latest;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.messagesSquare,
                          color: SgColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mulai konsultasi?',
                              style: AppTypography.h2.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hasil status gizi akan dikirim sebagai pesan awal ke ahli gizi.',
                              style: AppTypography.caption.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DialogInfoRow(
                    icon: LucideIcons.user,
                    label: 'Ahli gizi',
                    value: expert.name,
                  ),
                  if (child != null)
                    _DialogInfoRow(
                      icon: LucideIcons.baby,
                      label: 'Anak',
                      value: child.nama,
                    ),
                  if (latest != null) ...[
                    _DialogInfoRow(
                      icon: LucideIcons.activity,
                      label: 'Status terakhir',
                      value: latest.statusGabungan,
                    ),
                    _DialogInfoRow(
                      icon: LucideIcons.scale,
                      label: 'Pengukuran',
                      value:
                          'BB ${latest.berat.toStringAsFixed(1)} kg • TB ${latest.tinggi.toStringAsFixed(1)} cm',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF7E7C1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(
                          LucideIcons.info,
                          size: 18,
                          color: SgColors.warning,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Konsultasi baru hanya dibuat setelah Anda menekan tombol Mulai Konsultasi.',
                            style: AppTypography.caption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Mulai Konsultasi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  _Expert _expertFromApi(Map<String, dynamic> json) {
    return _Expert(
      id: (json['expert_id'] as String? ?? '').trim(),
      name: _cleanExpertName((json['name'] as String? ?? 'Ahli Gizi').trim()),
      specialization:
          (json['specialization'] as String? ?? 'Spesialis Gizi Anak').trim(),
      focusTag: (json['focus_tag'] as String? ?? 'general').trim(),
      photoUrl: (json['photo_url'] as String? ?? '').trim(),
      online: json['is_online'] == true,
      rating: 4.8,
      experience: (json['experience'] as String? ?? '-').trim(),
      consultationCount: (json['consultation_count'] as num?)?.toInt() ?? 0,
    );
  }

  List<_Expert> _recommendedExperts(String status, List<_Expert> experts) {
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

    if (experts.isEmpty) return const [];

    final mapped = [
      for (final e in experts)
        e.copyWith(recommended: isMatch(e), reason: reasonFor(e)),
    ];
    if (mapped.any((e) => e.recommended)) return mapped;

    final fallback = mapped.first;
    return [
      fallback.copyWith(
        recommended: true,
        reason: 'Direkomendasikan sebagai ahli gizi yang tersedia saat ini.',
      ),
      ...mapped.skip(1),
    ];
  }

  Future<void> _openOrCreateRoom(
    _Expert expert, {
    bool sendInitialMessage = false,
  }) async {
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
        assetImage: expert.photoUrl,
        online: expert.online,
      );
      final roomVm = _roomFromApi(room);
      _activeRoom = roomVm;
      await _loadMessages(roomVm.id);
      if (sendInitialMessage) {
        final message = (widget.initialMessage ?? '').trim().isEmpty
            ? _defaultInitialConsultationMessage()
            : widget.initialMessage!.trim();
        await _api.sendConsultationMessage(
          roomId: roomVm.id,
          message: message,
          measurementId: widget.initialMeasurementId ?? _latest?.id,
        );
        await _loadMessages(roomVm.id);
      }

      await _loadRooms();
      _startPolling();
      setState(() {});
      _jumpBottom(instant: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka room konsultasi.')),
      );
    } finally {
      _openingChat = false;
    }
  }

  String _defaultInitialConsultationMessage() {
    final child = _app.activeChild;
    final latest = _latest;
    final status = latest == null
        ? 'status gizi anak'
        : localizeNutritionStatus(latest.statusGabungan);
    return [
      'Halo, saya ingin berkonsultasi mengenai kondisi gizi anak.',
      if (child != null) 'Nama anak: ${child.nama}',
      if (latest != null) 'Status terakhir: $status',
      if (latest != null)
        'Pengukuran terakhir: BB ${latest.berat.toStringAsFixed(1)} kg, TB ${latest.tinggi.toStringAsFixed(0)} cm.',
    ].join('\n');
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
        _jumpBottom(instant: true);
      }
    } finally {
      _openingChat = false;
    }
  }

  ConsultationStatus _statusFromApi(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return ConsultationStatus.menunggu;
      case 'menunggu':
        return ConsultationStatus.menunggu;
      case 'closed':
      case 'selesai':
        return ConsultationStatus.selesai;
      case 'active':
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
        name: _cleanExpertName((json['expert_name'] as String?) ?? ''),
        specialization: (json['specialization'] as String?) ?? '',
        focusTag: 'general',
        photoUrl: (json['asset_image'] as String?) ?? '',
        online: (json['online'] as bool?) ?? false,
        rating: 4.8,
        experience: '5 tahun',
        consultationCount: (json['consultation_count'] as num?)?.toInt() ?? 50,
      ),
      status: _statusFromApi((json['status'] as String?) ?? 'aktif'),
      lastMessage: (json['last_message'] as String?) ?? '',
      updatedAt: _parseIndonesiaTime(json['updated_at'] as String?),
      unread: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastSharedMeasurementId: (json['last_shared_measurement_id'] as num?)
          ?.toInt(),
    );
  }

  bool get _hasPendingProgressUpdate {
    final room = _activeRoom;
    final latest = _latest;
    if (room == null || latest == null) return false;
    if (room.status == ConsultationStatus.selesai) return false;
    if (room.lastSharedMeasurementId == latest.id) return false;
    return !_dismissedProgressUpdates.contains('${room.id}:${latest.id}');
  }

  void _dismissProgressUpdate() {
    final room = _activeRoom;
    final latest = _latest;
    if (room == null || latest == null) return;
    setState(() => _dismissedProgressUpdates.add('${room.id}:${latest.id}'));
  }

  Future<void> _sendProgressUpdate() async {
    final room = _activeRoom;
    final child = _app.activeChild;
    final latest = _latest;
    if (room == null || child == null || latest == null) return;
    if (_sendingProgressUpdate) return;

    setState(() => _sendingProgressUpdate = true);
    late final String message;
    try {
      message = _buildProgressUpdateMessage(
        childName: child.nama,
        latest: latest,
        previous: _previous,
      );
      await _api.sendConsultationMessage(
        roomId: room.id,
        message: message,
        measurementId: latest.id,
      );
      if (!mounted) return;
      setState(() {
        _activeRoom = room.copyWith(lastSharedMeasurementId: latest.id);
        _dismissedProgressUpdates.add('${room.id}:${latest.id}');
        _messages = [
          ..._messages,
          _MsgVm(
            id: -DateTime.now().millisecondsSinceEpoch,
            text: message,
            createdAt: _indonesiaNow(),
            fromUser: true,
            read: true,
            progressUpdate: true,
          ),
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update perkembangan berhasil dikirim.')),
      );

      try {
        await _loadMessages(room.id);
        await _loadRooms();
        if (!mounted) return;
        setState(() {});
        _jumpBottom();
      } catch (refreshError, stackTrace) {
        debugPrint('[sendProgressUpdate.refresh] $refreshError\n$stackTrace');
      }
    } catch (error, stackTrace) {
      debugPrint('[sendProgressUpdate.error] $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim update perkembangan.')),
      );
    } finally {
      if (mounted) setState(() => _sendingProgressUpdate = false);
    }
  }

  String _buildProgressUpdateMessage({
    required String childName,
    required RiwayatItemModel latest,
    RiwayatItemModel? previous,
  }) {
    final oldWeight = previous == null
        ? '-'
        : '${previous.berat.toStringAsFixed(1)} kg';
    final oldHeight = previous == null
        ? '-'
        : '${previous.tinggi.toStringAsFixed(0)} cm';
    final oldStatus = previous == null
        ? '-'
        : localizeNutritionStatus(previous.statusGabungan);
    return [
      'Update Perkembangan Anak',
      'Nama Anak: $childName',
      'Pengukuran: ${formatMeasurementDate(latest.tanggalUkur)}',
      'Berat Badan: $oldWeight -> ${latest.berat.toStringAsFixed(1)} kg',
      'Tinggi Badan: $oldHeight -> ${latest.tinggi.toStringAsFixed(0)} cm',
      'Status Gizi: $oldStatus -> ${localizeNutritionStatus(latest.statusGabungan)}',
      'Catatan: ${_progressNote(latest, previous)}',
    ].join('\n');
  }

  String _progressNote(RiwayatItemModel latest, RiwayatItemModel? previous) {
    if (previous == null) {
      return 'Data pengukuran terbaru siap dipantau bersama ahli gizi.';
    }
    final weightUp = latest.berat >= previous.berat;
    final heightUp = latest.tinggi >= previous.tinggi;
    if (weightUp && heightUp) {
      return 'Berat dan tinggi mengalami peningkatan stabil.';
    }
    if (!weightUp && heightUp) {
      return 'Tinggi bertambah, tetapi berat badan perlu dipantau.';
    }
    if (weightUp && !heightUp) {
      return 'Berat bertambah, tinggi badan perlu pemantauan berkala.';
    }
    return 'Perkembangan perlu perhatian dan evaluasi bersama ahli gizi.';
  }

  _MsgVm _msgFromApi(Map<String, dynamic> json) {
    final sender = ((json['sender_type'] as String?) ?? 'parent').toLowerCase();
    final text = (json['message'] as String?) ?? '';
    return _MsgVm(
      id: (json['id'] as num?)?.toInt() ?? 0,
      text: text,
      createdAt: _parseIndonesiaTime(json['created_at'] as String?),
      fromUser: sender == 'parent',
      read: (json['is_read'] as bool?) ?? true,
      analysis: text.startsWith('Hasil Analisis Anak'),
      progressUpdate: text.startsWith('Update Perkembangan Anak'),
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
                      : () => Navigator.of(
                          context,
                        ).push(fadeRoute(const _HistoryScreen())),
                  icon: const Icon(LucideIcons.history),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: child == null
            ? const EmptyState(
                title: 'Belum Ada Anak Aktif',
                message:
                    'Pilih anak aktif terlebih dahulu untuk memulai konsultasi.',
              )
            : RefreshIndicator(
                color: SgColors.primary,
                onRefresh: _loadRooms,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(SgSpacing.pageH),
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
                      Text(
                        'Direkomendasikan Untuk Anda',
                        style: AppTypography.h2,
                      ),
                      const SizedBox(height: 8),
                      if (recommended.isEmpty)
                        const HealthCard(
                          child: Text(
                            'Belum ada ahli rekomendasi untuk status anak saat ini.',
                          ),
                        )
                      else
                        ...recommended.map(
                          (e) => _RecommendedCard(
                            expert: e,
                            onChat: () => _handleExpertSelection(e),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text('Riwayat Konsultasi', style: AppTypography.h2),
                      const SizedBox(height: 8),
                      if (_rooms.isEmpty)
                        const HealthCard(
                          child: Text('Belum ada riwayat konsultasi.'),
                        )
                      else
                        ..._rooms
                            .take(3)
                            .map(
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
                          onChat: () => _handleExpertSelection(e),
                        ),
                      ),
                    ],
                  ),
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
      resizeToAvoidBottomInset: true,
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
                  status: 'closed',
                );
                await _loadRooms();
                setState(() {
                  _activeRoom = room.copyWith(
                    status: ConsultationStatus.selesai,
                  );
                });
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: _hasPendingProgressUpdate
                  ? _ProgressUpdatePromptCard(
                      key: ValueKey('progress-${room.id}-${_latest!.id}'),
                      childName: _app.activeChild?.nama ?? room.childName,
                      latest: _latest!,
                      previous: _previous,
                      sending: _sendingProgressUpdate,
                      onSend: _sendProgressUpdate,
                      onLater: _dismissProgressUpdate,
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: grouped.isEmpty
                  ? const _ChatEmpty()
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      physics: const BouncingScrollPhysics(),
                      cacheExtent: 600,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final item = grouped[grouped.length - 1 - i];
                        if (item.date != null) return _DateBadge(item.date!);
                        if (item.message == null) {
                          return const SizedBox.shrink();
                        }
                        return _MessageBubble(
                          message: item.message!,
                          expert: room.expert,
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12 + MediaQuery.viewInsetsOf(context).bottom * 0.08,
              ),
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
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                      ),
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
      await LocalNotificationService.instance.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: 'Pesan konsultasi terkirim',
        body: room.expert.name,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan.')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _jumpBottom({bool instant = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      const target = 0.0;
      if ((_scroll.offset - target).abs() < 2) return;
      if (instant) {
        _scroll.jumpTo(target);
        return;
      }
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
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
          final status = ((json['status'] as String?) ?? 'active')
              .toLowerCase();
          ConsultationStatus state = ConsultationStatus.aktif;
          if (status == 'pending' || status == 'menunggu') {
            state = ConsultationStatus.menunggu;
          }
          if (status == 'closed' || status == 'selesai') {
            state = ConsultationStatus.selesai;
          }
          return _RoomVm(
            id: (json['id'] as num?)?.toInt() ?? 0,
            keyId:
                '${(json['child_id'] as num?)?.toInt() ?? 0}::${json['expert_id'] ?? ''}',
            childName: (json['child_name'] as String?) ?? '-',
            expert: _Expert(
              id: (json['expert_id'] as String?) ?? '',
              name: _cleanExpertName((json['expert_name'] as String?) ?? ''),
              specialization: (json['specialization'] as String?) ?? '',
              focusTag: 'general',
              photoUrl: (json['asset_image'] as String?) ?? '',
              online: (json['online'] as bool?) ?? false,
              rating: 4.8,
              experience: '5 tahun',
              consultationCount:
                  (json['consultation_count'] as num?)?.toInt() ?? 50,
            ),
            status: state,
            lastMessage: (json['last_message'] as String?) ?? '',
            updatedAt: _parseIndonesiaTime(json['updated_at'] as String?),
            unread: (json['unread_count'] as num?)?.toInt() ?? 0,
            lastSharedMeasurementId:
                (json['last_shared_measurement_id'] as num?)?.toInt(),
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
      dense: true,
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: const Color(0xFF0B7A86),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExpertAvatar(expert: expert, radius: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  expert.specialization,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _ExpertMetaRow(expert: expert),
                if (expert.reason.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    expert.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF0B7A86),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: onChat,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Chat', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  const _DialogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SgColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertMetaRow extends StatelessWidget {
  const _ExpertMetaRow({required this.expert});

  final _Expert expert;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _MiniStatusDot(online: expert.online),
        Text(
          expert.experience,
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
        Text(
          '${expert.consultationCount} konsultasi',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _MiniStatusDot extends StatelessWidget {
  const _MiniStatusDot({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: online ? SgColors.success : SgColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          online ? 'Online' : 'Offline',
          style: AppTypography.caption.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _ExpertAvatar extends StatelessWidget {
  const _ExpertAvatar({required this.expert, required this.radius});

  final _Expert expert;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = expert.photoUrl.trim();
    final photoUrl = _resolveExpertPhotoUrl(photo);
    if (photoUrl != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFEAF8F7),
        backgroundImage: NetworkImage(photoUrl),
      );
    }
    return SgAvatar(name: expert.name, radius: radius, icon: LucideIcons.user);
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SgColors.danger,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
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
      dense: true,
      margin: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExpertAvatar(expert: expert, radius: 21),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
                Text(
                  expert.specialization,
                  style: AppTypography.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                _ExpertMetaRow(expert: expert),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onChat,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Chat', style: TextStyle(fontSize: 12)),
          ),
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ExpertAvatar(expert: room.expert, radius: 22),
              if (room.unread > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: _UnreadBadge(count: room.unread),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.expert.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      LucideIcons.clock3,
                      size: 12,
                      color: SgColors.textSecondary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fmtTime(room.updatedAt),
                      style: AppTypography.caption.copyWith(fontSize: 11),
                    ),
                  ],
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
          const SizedBox(width: 8),
          Flexible(child: _StatusBadge(room.status)),
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
              IconButton(
                onPressed: onBack,
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              _ExpertAvatar(expert: room.expert, radius: 20),
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
              Flexible(child: _StatusBadge(room.status)),
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
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _ExpertAvatar(expert: expert, radius: 13),
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
                      : message.progressUpdate
                      ? const Color(0xFFF0FAF8)
                      : isUser
                      ? const Color(0xFF0B7A86)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: message.analysis
                        ? const Color(0xFF0B7A86)
                        : message.progressUpdate
                        ? const Color(0xFFBFE8E1)
                        : const Color(0xFFE1E8E6),
                  ),
                ),
                child: message.analysis
                    ? _AnalysisMessageContent(rawText: message.text)
                    : message.progressUpdate
                    ? _ProgressUpdateMessageContent(rawText: message.text)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.text,
                            softWrap: true,
                            style: AppTypography.body.copyWith(
                              color: isUser
                                  ? Colors.white
                                  : SgColors.textPrimary,
                            ),
                          ),
                          if (isUser) ...[
                            const SizedBox(height: 4),
                            Text(
                              message.read ? 'Dibaca' : 'Belum Dibaca',
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
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

class _ProgressUpdatePromptCard extends StatelessWidget {
  const _ProgressUpdatePromptCard({
    super.key,
    required this.childName,
    required this.latest,
    required this.previous,
    required this.sending,
    required this.onSend,
    required this.onLater,
  });

  final String childName;
  final RiwayatItemModel latest;
  final RiwayatItemModel? previous;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: HealthCard(
        dense: true,
        padding: const EdgeInsets.all(12),
        color: const Color(0xFFF0FAF8),
        borderColor: const Color(0xFFBFE8E1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDDF4F0),
                  child: Icon(
                    LucideIcons.trendingUp,
                    color: SgColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ada perkembangan baru anak',
                        style: AppTypography.h3,
                      ),
                      Text(
                        '$childName • ${formatMeasurementDate(latest.tanggalUkur)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: StatusBadge(
                    text: 'Belum dikirim',
                    color: SgColors.warning,
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ProgressMiniChart(items: [?previous, latest]),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ProgressDelta(
                    label: 'Berat',
                    value:
                        '${previous == null ? '-' : previous!.berat.toStringAsFixed(1)} → ${latest.berat.toStringAsFixed(1)} kg',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProgressDelta(
                    label: 'Tinggi',
                    value:
                        '${previous == null ? '-' : previous!.tinggi.toStringAsFixed(0)} → ${latest.tinggi.toStringAsFixed(0)} cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ProgressDelta(
              label: 'Status',
              value:
                  '${previous == null ? '-' : localizeNutritionStatus(previous!.statusGabungan)} → ${localizeNutritionStatus(latest.statusGabungan)}',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttons = [
                  OutlinedButton(
                    onPressed: sending ? null : onLater,
                    child: const Text('Nanti'),
                  ),
                  FilledButton(
                    onPressed: sending ? null : onSend,
                    style: FilledButton.styleFrom(
                      backgroundColor: SgColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kirim Update'),
                  ),
                ];
                if (constraints.maxWidth < 320) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buttons[1],
                      const SizedBox(height: 8),
                      buttons[0],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: buttons[0]),
                    const SizedBox(width: 10),
                    Expanded(child: buttons[1]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDelta extends StatelessWidget {
  const _ProgressDelta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEDEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: SgColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMiniChart extends StatelessWidget {
  const _ProgressMiniChart({required this.items});

  final List<RiwayatItemModel> items;

  @override
  Widget build(BuildContext context) {
    final safe = items.isEmpty ? <RiwayatItemModel>[] : items;
    if (safe.length < 2) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 72,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (safe.length - 1).toDouble(),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            _miniLine(safe, (item) => item.berat, SgColors.primary),
            _miniLine(safe, (item) => item.tinggi, const Color(0xFF2F80ED)),
          ],
        ),
        duration: const Duration(milliseconds: 450),
      ),
    );
  }

  LineChartBarData _miniLine(
    List<RiwayatItemModel> items,
    double Function(RiwayatItemModel item) valueOf,
    Color color,
  ) {
    final values = items.map(valueOf).toList();
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final spread = (max - min).abs() < 0.001 ? 1.0 : max - min;
    return LineChartBarData(
      spots: [
        for (var i = 0; i < items.length; i++)
          FlSpot(i.toDouble(), ((valueOf(items[i]) - min) / spread) * 10),
      ],
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.10),
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
        text = 'Sedang Berlangsung';
        color = const Color(0xFF34A853);
        break;
      case ConsultationStatus.menunggu:
        text = 'Sedang Berlangsung';
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProgressUpdateMessageContent extends StatelessWidget {
  const _ProgressUpdateMessageContent({required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    final data = <String, String>{};
    for (final line in rawText.split('\n')) {
      final idx = line.indexOf(':');
      if (idx == -1) continue;
      data[line.substring(0, idx).trim()] = line.substring(idx + 1).trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.activity, color: SgColors.primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Update Perkembangan Anak',
                style: AppTypography.h3.copyWith(color: SgColors.textPrimary),
              ),
            ),
            StatusBadge(
              text: 'Sudah dikirim',
              color: SgColors.success,
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ProgressMessageRow(
          label: 'Nama Anak',
          value: data['Nama Anak'] ?? '-',
        ),
        _ProgressMessageRow(
          label: 'Pengukuran',
          value: data['Pengukuran'] ?? '-',
        ),
        _ProgressMessageRow(
          label: 'Berat Badan',
          value: data['Berat Badan'] ?? '-',
          icon: LucideIcons.scale,
        ),
        _ProgressMessageRow(
          label: 'Tinggi Badan',
          value: data['Tinggi Badan'] ?? '-',
          icon: LucideIcons.ruler,
        ),
        _ProgressMessageRow(
          label: 'Status Gizi',
          value: data['Status Gizi'] ?? '-',
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDCEDEA)),
          ),
          child: Text(
            data['Catatan'] ?? '-',
            style: AppTypography.caption.copyWith(
              color: SgColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressMessageRow extends StatelessWidget {
  const _ProgressMessageRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? LucideIcons.checkCircle2,
            size: 15,
            color: SgColors.primary,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.caption.copyWith(
                  color: SgColors.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisMessageContent extends StatelessWidget {
  const _AnalysisMessageContent({required this.rawText});

  final String rawText;

  @override
  Widget build(BuildContext context) {
    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where(
          (e) =>
              e.isNotEmpty && !e.toLowerCase().contains('hasil analisis anak'),
        )
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
  final sorted = [...source]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
  final n = _indonesiaNow();
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
    '${_toIndonesiaTime(d).hour.toString().padLeft(2, '0')}:${_toIndonesiaTime(d).minute.toString().padLeft(2, '0')}';

String _cleanExpertName(String raw) {
  final cleaned = raw
      .replaceAll(RegExp(r'\bdr\.?\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.isEmpty ? 'Ahli Gizi' : cleaned;
}

String? _resolveExpertPhotoUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  final baseUri = Uri.tryParse(ApiService().baseUrl);
  if (baseUri == null) return null;
  final root = baseUri.replace(path: '', query: '', fragment: '').toString();
  final normalizedRoot = root.endsWith('/') ? root : '$root/';
  final path = value.startsWith('/') ? value.substring(1) : value;
  return '$normalizedRoot$path';
}

DateTime _indonesiaNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 7));

DateTime _parseIndonesiaTime(String? raw) {
  final parsed = DateTime.tryParse(raw ?? '');
  if (parsed == null) return _indonesiaNow();
  return _toIndonesiaTime(parsed);
}

DateTime _toIndonesiaTime(DateTime value) {
  final local = value.toLocal();
  if (local.timeZoneOffset == const Duration(hours: 7)) return local;
  return value.toUtc().add(const Duration(hours: 7));
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
