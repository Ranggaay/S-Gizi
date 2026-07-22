import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/auth/widgets/auth_loading_widgets.dart';
import 'package:s_gizi/features/navigation/screens/app_shell.dart';
import 'package:s_gizi/features/dashboard/screens/child_empty_state_screen.dart';

class CheckChildScreen extends StatefulWidget {
  const CheckChildScreen({super.key});

  @override
  State<CheckChildScreen> createState() => _CheckChildScreenState();
}

class _CheckChildScreenState extends State<CheckChildScreen> {
  final _api = ApiService();
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    try {
      final profile = await _api.getProfile();
      SgiziAppState.instance.setProfileData(profile);
    } catch (_) {}

    final children = await _api.getChildren();
    final state = SgiziAppState.instance;
    state.setChildren(children);
    if (children.isNotEmpty) {
      state.setActiveChild(children.first.id);
      state.showFamilyOverview();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      fadeRoute(
        children.isEmpty ? const ChildEmptyStateScreen() : const AppShell(),
      ),
    );
  }

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              message:
                  'Data anak belum dapat dimuat. Coba ulangi koneksi ke server.',
              onRetry: _retry,
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 48)
                        .clamp(0, double.infinity)
                        .toDouble(),
                  ),
                  child: const Center(
                    child: AuthProgressCard(message: 'Mengecek data anak...'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
