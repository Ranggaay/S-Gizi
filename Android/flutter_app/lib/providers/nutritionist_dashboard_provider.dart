import 'package:flutter/foundation.dart';

import 'package:s_gizi/models/dashboard_nutritionist_model.dart';
import 'package:s_gizi/services/nutritionist_dashboard_service.dart';

class NutritionistDashboardProvider extends ChangeNotifier {
  NutritionistDashboardProvider({NutritionistDashboardService? service})
    : _service = service ?? NutritionistDashboardService();

  final NutritionistDashboardService _service;
  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  DashboardNutritionistModel? dashboardData;

  Future<void> fetchDashboard() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      dashboardData = await _service.getDashboard();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    isRefreshing = true;
    errorMessage = null;
    notifyListeners();
    try {
      dashboardData = await _service.getDashboard();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }
}
