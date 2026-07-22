class QuickValidationService {
  Future<void> validateMeasurement({
    required int measurementId,
    required bool accepted,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (measurementId <= 0) {
      throw Exception('Data pengukuran tidak valid.');
    }
  }
}
