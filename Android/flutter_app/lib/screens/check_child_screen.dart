import 'package:flutter/material.dart';

import '../app_design.dart';
import '../app_state.dart';
import '../services/api_service.dart';
import 'add_child_screen.dart';
import 'app_shell.dart';

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
    final children = await _api.getChildren();
    SgiziAppState.instance.setChildren(children);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      fadeRoute(
        children.isEmpty
            ? const AddChildScreen(isFirstSetup: true)
            : const AppShell(),
      ),
    );
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
              onRetry: () => setState(() => _future = _load()),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: SgColors.primary),
          );
        },
      ),
    );
  }
}
