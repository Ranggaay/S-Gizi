import 'package:flutter/foundation.dart';

import 'package:s_gizi/models/child_detail_model.dart';
import 'package:s_gizi/services/child_detail_service.dart';

class ChildDetailProvider extends ChangeNotifier {
  ChildDetailProvider({ChildDetailService? service})
    : _service = service ?? ChildDetailService();

  final ChildDetailService _service;

  bool isLoading = false;
  String? errorMessage;
  ChildDetailModel? childDetail;

  Future<void> fetchChildDetail(int childId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      childDetail = await _service.getChildDetail(childId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
