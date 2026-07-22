import 'package:flutter/material.dart';

import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/features/dashboard/screens/family_dashboard_screen.dart';
import 'package:s_gizi/features/dashboard/screens/main_dashboard_screen.dart';

/// Tab Home: 1 anak → dashboard utama; 2+ anak → overview keluarga.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onChangeTab,
    required this.onOverviewChanged,
  });

  final ValueChanged<int> onChangeTab;
  final ValueChanged<bool> onOverviewChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _appState = SgiziAppState.instance;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_rebuild);
  }

  @override
  void dispose() {
    _appState.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final children = _appState.children;
    if (children.isNotEmpty && _appState.showFamilyOverviewOnHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOverviewChanged(true);
      });
      return FamilyDashboardScreen(
        onChangeTab: widget.onChangeTab,
        onOpenDashboard: (child) {
          _appState.setActiveChild(child.id);
        },
      );
    }

    if (children.length <= 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOverviewChanged(false);
      });
      final child =
          _appState.activeChild ??
          (children.isNotEmpty ? children.first : null);
      if (child != null && _appState.activeChildId != child.id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _appState.setActiveChild(child.id);
        });
      }
      return MainDashboardScreen(
        onChangeTab: widget.onChangeTab,
        onShowFamilyOverview: () => widget.onOverviewChanged(true),
      );
    }

    if (_appState.showFamilyOverviewOnHome || _appState.activeChild == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOverviewChanged(true);
      });
      return FamilyDashboardScreen(
        onChangeTab: widget.onChangeTab,
        onOpenDashboard: (child) {
          _appState.setActiveChild(child.id);
        },
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onOverviewChanged(false);
    });
    return MainDashboardScreen(
      onChangeTab: widget.onChangeTab,
      onShowFamilyOverview: () => widget.onOverviewChanged(true),
    );
  }
}
