import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/consultation_model.dart';
import 'package:s_gizi/providers/consultation_provider.dart';
import 'package:s_gizi/screens/nutritionist/child_detail_from_chat_screen.dart';
import 'package:s_gizi/widgets/chat_bubble.dart';
import 'package:s_gizi/widgets/child_summary_card.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';

class ConsultationChatScreen extends StatefulWidget {
  const ConsultationChatScreen({super.key, required this.consultation});

  final ConsultationModel consultation;

  @override
  State<ConsultationChatScreen> createState() => _ConsultationChatScreenState();
}

class _ConsultationChatScreenState extends State<ConsultationChatScreen> {
  final _input = TextEditingController();
  late final ConsultationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ConsultationProvider()..fetchMessages(widget.consultation.id);
  }

  @override
  void dispose() {
    _input.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ok = await _provider.sendMessage(widget.consultation.id, _input.text);
    if (!mounted) return;
    if (ok) {
      _input.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Gagal mengirim pesan.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = widget.consultation.isClosed;
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.consultation.parentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Anak: ${widget.consultation.childName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: SgColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: closed
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await _provider.closeConsultation(
                      widget.consultation.id,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Konsultasi ditandai selesai.'
                              : 'Gagal menutup konsultasi.',
                        ),
                      ),
                    );
                  },
            child: const Text('Selesai'),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            if (_provider.isLoading) return const LoadingSkeleton();
            if (_provider.errorMessage != null) {
              return ErrorState(
                message: _provider.errorMessage!,
                onRetry: () => _provider.fetchMessages(widget.consultation.id),
              );
            }
            return Column(
              children: [
                if (_provider.childDetail != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: ChildSummaryCard(
                      child: _provider.childDetail!,
                      onDetail: () => Navigator.of(context).push(
                        fadeRoute(
                          ChildDetailFromChatScreen(
                            consultationId: widget.consultation.id,
                            initialData: _provider.childDetail,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _provider.messages.isEmpty
                      ? const EmptyState(
                          title: 'Belum ada pesan',
                          message:
                              'Chat akan tampil setelah orang tua mengirim pesan.',
                          icon: LucideIcons.messageCircle,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                          itemCount: _provider.messages.length,
                          itemBuilder: (context, index) =>
                              ChatBubble(message: _provider.messages[index]),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          enabled: !closed,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: closed
                                ? 'Konsultasi sudah selesai'
                                : 'Tulis balasan...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: closed || _provider.isSending ? null : _send,
                        icon: const Icon(LucideIcons.send),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
