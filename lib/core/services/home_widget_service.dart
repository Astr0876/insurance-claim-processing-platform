import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../providers/app_state.dart';

class HomeWidgetService {
  static const String _androidWidgetName = 'HomeWidgetProvider';
  static const String _iosWidgetName = 'HomeWidget';

  static Future<void> updateWidget(HomeWidgetSnapshot snapshot) async {
    try {
      debugPrint('DEBUG: HomeWidgetService.updateWidget called');
      await HomeWidget.saveWidgetData<String>('next_class_label', snapshot.nextClassLabel);
      await HomeWidget.saveWidgetData<String>('next_class_time', snapshot.nextClassTime);
      await HomeWidget.saveWidgetData<double>('attendance_percentage', snapshot.attendancePercentage);
      await HomeWidget.saveWidgetData<String>('risk_label', snapshot.riskLabel);
      await HomeWidget.saveWidgetData<int>('upcoming_deadlines_count', snapshot.upcomingDeadlinesCount);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
      debugPrint('DEBUG: HomeWidgetService.updateWidget completed');
    } catch (e) {
      debugPrint('DEBUG: HomeWidgetService error: $e');
    }
  }

  static Future<void> setupBackground() async {
  }
}
