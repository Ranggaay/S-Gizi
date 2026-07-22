class NutritionistNoteService {
  Future<void> saveNote({required int childId, required String note}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (note.trim().isEmpty) {
      throw Exception('Catatan tidak boleh kosong.');
    }
  }
}
