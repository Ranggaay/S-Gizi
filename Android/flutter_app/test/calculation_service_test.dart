import 'package:flutter_test/flutter_test.dart';
import 'package:s_gizi/models/child_model.dart';
import 'package:s_gizi/services/calculation_service.dart';
import 'package:s_gizi/services/data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChildModel', () {
    test('normalizes gender, position, and adjusted height correctly', () {
      const child = ChildModel(
        ageInMonths: 18,
        weightKg: 10.2,
        heightCm: 78,
        gender: 'L',
        measurementPosition: 'berdiri',
      );

      expect(child.normalizedGender, 'male');
      expect(child.normalizedPosition, 'standing');
      expect(child.weightForHeightIndicator, 'wfl');
      expect(child.adjustedHeightCm, closeTo(78.7, 0.0001));
    });
  });

  group('CalculationService', () {
    final service = CalculationService(dataService: DataService.instance);

    test('matches WHO sample calculation for male child', () async {
      const child = ChildModel(
        ageInMonths: 18,
        weightKg: 10.2,
        heightCm: 78,
        gender: 'male',
        measurementPosition: 'standing',
      );

      final result = await service.calculate(child);

      expect(result.weightForHeightIndicator, 'wfl');
      expect(result.adjustedHeightCm, closeTo(78.7, 0.0001));
      expect(result.bbU, closeTo(-0.6282, 0.0001));
      expect(result.tbU, closeTo(-1.5789, 0.0001));
      expect(result.bbTb, closeTo(-0.0123, 0.0001));
    });

    test('matches WHO sample calculation for female child', () async {
      const child = ChildModel(
        ageInMonths: 30,
        weightKg: 12.4,
        heightCm: 91.3,
        gender: 'perempuan',
        measurementPosition: 'recumbent',
      );

      final result = await service.calculate(child);

      expect(result.weightForHeightIndicator, 'wfh');
      expect(result.adjustedHeightCm, closeTo(91.3, 0.0001));
      expect(result.bbU, closeTo(-0.1941, 0.0001));
      expect(result.tbU, closeTo(0.1757, 0.0001));
      expect(result.bbTb, closeTo(-0.5064, 0.0001));
    });
  });
}
