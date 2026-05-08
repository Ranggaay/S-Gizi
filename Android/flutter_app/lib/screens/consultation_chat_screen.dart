import 'package:flutter/material.dart';

import '../app_design.dart';

class ConsultationChatScreen extends StatelessWidget {
  const ConsultationChatScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: showAppBar
          ? AppBar(
              title: const Text('Ahli Gizi'),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.person_outline_rounded),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!showAppBar)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: const [
                    AppLogo(size: 38),
                    SizedBox(width: 12),
                    Text('Ahli Gizi', style: AppTypography.h1),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: const [
                  Center(
                    child: StatusBadge(
                      text: 'HARI INI',
                      color: SgColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20),
                  _ChatBubble(
                    text:
                        'Halo Ibu! Saya dr. Sarah, ahli gizi S-Gizi. Ada yang bisa saya bantu terkait tumbuh kembang si kecil?',
                    time: '10:00',
                    isUser: false,
                  ),
                  _ChatBubble(
                    text:
                        'Halo dok, saya agak khawatir dengan berat badan anak saya yang tidak naik bulan ini.',
                    time: '10:02',
                    isUser: true,
                  ),
                  _ChatBubble(
                    text:
                        'Saya mengerti kekhawatiran Ibu. Berdasarkan data terakhir di dashboard, status gizinya masih normal, namun memang ada penurunan tren. Apakah ada perubahan pola makan akhir-akhir ini?',
                    time: '10:05',
                    isUser: false,
                  ),
                  _ChatBubble(
                    text:
                        'Iya dok, dia sedang pilih-pilih makanan. Hanya mau makan nasi putih saja.',
                    time: '10:07',
                    isUser: true,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: SgColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis pesan...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: SgColors.border),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      minimumSize: const Size(52, 52),
                      padding: EdgeInsets.zero,
                      backgroundColor: SgColors.primary,
                    ),
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.time,
    required this.isUser,
  });

  final String text;
  final String time;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFD9EEE7),
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 18,
                color: SgColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? SgColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: SgColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: AppTypography.body.copyWith(
                      color: isUser ? Colors.white : SgColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: AppTypography.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
