import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:s_gizi/models/child_monitoring_model.dart';
import 'package:s_gizi/services/child_monitoring_service.dart';

class ChildMonitoringProvider extends ChangeNotifier {
  ChildMonitoringProvider({ChildMonitoringService? service})
    : _service = service ?? ChildMonitoringService();

  final ChildMonitoringService _service;
  Timer? _debounce;

  bool isLoading = false;
  bool isRefreshing = false;
  String? errorMessage;
  ChildMonitoringSummary summary = ChildMonitoringSummary.empty;
  List<ChildMonitoringModel> children = const [];
  String selectedFilter = 'all';
  String searchQuery = '';

  Future<void> fetchChildren() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _service.getChildren(
        search: searchQuery,
        filter: selectedFilter,
      );
      summary = response.summary;
      children = response.children;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshChildren() async {
    isRefreshing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _service.getChildren(
        search: searchQuery,
        filter: selectedFilter,
      );
      summary = response.summary;
      children = response.children;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  void setFilter(String value) {
    if (selectedFilter == value) return;
    selectedFilter = value;
    fetchChildren();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), fetchChildren);
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
