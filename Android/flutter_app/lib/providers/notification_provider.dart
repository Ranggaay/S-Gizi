import 'package:flutter/foundation.dart';

import 'package:s_gizi/models/notification_model.dart';
import 'package:s_gizi/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service})
    : _service = service ?? NotificationService();

  final NotificationService _service;
  bool isLoading = false;
  String? errorMessage;
  String selectedFilter = 'all';
  List<NotificationModel> notifications = const [];

  Future<void> fetchNotifications() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      notifications = await _service.getNotifications(filter: selectedFilter);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    fetchNotifications();
  }

  Future<void> markRead(int id) async {
    await _service.markRead(id);
    notifications = [
      for (final item in notifications)
        item.id == id
            ? NotificationModel.fromJson({...item.toJson(), 'is_read': true})
            : item,
    ];
    notifyListeners();
  }
}
