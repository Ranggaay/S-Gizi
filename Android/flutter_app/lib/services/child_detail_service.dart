import 'package:s_gizi/models/child_detail_model.dart';
import 'package:s_gizi/services/child_monitoring_service.dart';

class ChildDetailService {
  ChildDetailService({ChildMonitoringService? monitoringService})
    : _monitoringService = monitoringService ?? ChildMonitoringService();

  final ChildMonitoringService _monitoringService;

  Future<ChildDetailModel> getChildDetail(int childId) {
    return _monitoringService.getChildDetail(childId);
  }
}
