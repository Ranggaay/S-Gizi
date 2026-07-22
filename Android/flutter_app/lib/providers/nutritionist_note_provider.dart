import 'package:flutter/foundation.dart';

import 'package:s_gizi/services/nutritionist_note_service.dart';

class NutritionistNoteProvider extends ChangeNotifier {
  NutritionistNoteProvider({NutritionistNoteService? service})
    : _service = service ?? NutritionistNoteService();

  final NutritionistNoteService _service;
  bool isSaving = false;
  String? errorMessage;

  Future<bool> saveNote({required int childId, required String note}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.saveNote(childId: childId, note: note);
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
