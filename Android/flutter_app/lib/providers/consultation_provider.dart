import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:s_gizi/models/chat_message_model.dart';
import 'package:s_gizi/models/child_chat_detail_model.dart';
import 'package:s_gizi/models/consultation_model.dart';
import 'package:s_gizi/services/consultation_service.dart';

class ConsultationProvider extends ChangeNotifier {
  ConsultationProvider({ConsultationService? service})
    : _service = service ?? ConsultationService();

  final ConsultationService _service;
  Timer? _debounce;
  bool isLoading = false;
  bool isSending = false;
  String? errorMessage;
  String searchQuery = '';
  String selectedFilter = 'all';
  List<ConsultationModel> consultations = const [];
  List<ChatMessageModel> messages = const [];
  ChildChatDetailModel? childDetail;

  Future<void> fetchConsultations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      consultations = await _service.getConsultations(
        search: searchQuery,
        filter: selectedFilter,
      );
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), fetchConsultations);
  }

  void setFilter(String value) {
    selectedFilter = value;
    fetchConsultations();
  }

  Future<void> fetchMessages(int consultationId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      messages = await _service.getChatMessages(consultationId);
      childDetail = await _service.getChildDetailFromChat(consultationId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(int consultationId, String message) async {
    if (message.trim().isEmpty) return false;
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.sendMessage(
        consultationId: consultationId,
        message: message.trim(),
      );
      messages = await _service.getChatMessages(consultationId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<bool> closeConsultation(int consultationId) async {
    try {
      await _service.closeConsultation(consultationId);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveNote({
    required int consultationId,
    required String category,
    required String note,
  }) async {
    try {
      await _service.saveNote(
        consultationId: consultationId,
        category: category,
        note: note,
      );
      childDetail = await _service.getChildDetailFromChat(consultationId);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
