import 'package:flutter/material.dart';

import '../app_design.dart';
import '../app_state.dart';
import 'add_child_screen.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Anak')),
      backgroundColor: SgColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Kelola Anak', style: AppTypography.h1),
            const SizedBox(height: 8),
            const Text(
              'Pilih profil anak untuk melihat perkembangan dan rekomendasi gizi yang sesuai.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 24),
            ...SgiziAppState.instance.children.map(
              (child) => HealthCard(
                margin: const EdgeInsets.only(bottom: 16),
                onTap: () {
                  SgiziAppState.instance.setActiveChild(child.id);
                  Navigator.pop(context);
                },
                color: child.id == SgiziAppState.instance.activeChildId
                    ? const Color(0xFFEAF7F7)
                    : Colors.white,
                borderColor: child.id == SgiziAppState.instance.activeChildId
                    ? SgColors.primary
                    : SgColors.border,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              child.id == SgiziAppState.instance.activeChildId
                              ? const Color(0xFFD9EEE7)
                              : const Color(0xFFF0F2F1),
                          child: Icon(
                            child.jenisKelamin == 'P'
                                ? Icons.face_3_rounded
                                : Icons.face_rounded,
                            color:
                                child.id == SgiziAppState.instance.activeChildId
                                ? SgColors.primary
                                : SgColors.textSecondary,
                          ),
                        ),
                        if (child.id == SgiziAppState.instance.activeChildId)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: SgColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  child.nama,
                                  style: AppTypography.h2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (child.id ==
                                  SgiziAppState.instance.activeChildId) ...[
                                const SizedBox(width: 8),
                                const StatusBadge(
                                  text: 'Aktif',
                                  color: SgColors.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            child.jenisKelamin == 'P'
                                ? 'Perempuan'
                                : 'Laki-laki',
                            style: AppTypography.body,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Update terakhir: ${child.latestMeasurementAt ?? '-'}',
                            style: AppTypography.caption.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: SgColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            HealthCard(
              color: const Color(0xFFF1FAF4),
              borderColor: SgColors.secondary,
              child: Column(
                children: [
                  const Text('Punya anak lain?', style: AppTypography.h3),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Tambah Anak',
                    icon: Icons.add_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).push(fadeRoute(const AddChildScreen())),
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
