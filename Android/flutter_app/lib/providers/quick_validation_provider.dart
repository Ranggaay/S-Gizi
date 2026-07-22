import 'package:flutter/foundation.dart';

import 'package:s_gizi/services/quick_validation_service.dart';

class QuickValidationProvider extends ChangeNotifier {
  QuickValidationProvider({QuickValidationService? service})
    : _service = service ?? QuickValidationService();

  final QuickValidationService _service;
  bool isSaving = false;
  String? errorMessage;

  Future<bool> validate({
    required int measurementId,
    required bool accepted,
    String? note,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.validateMeasurement(
        measurementId: measurementId,
        accepted: accepted,
        note: note,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
