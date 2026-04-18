import 'package:home_widget/home_widget.dart';
import '../providers/app_state.dart';

class HomeWidgetService {
  static const String _groupId = 'group.lockin.widget'; // Placeholder
  static const String _androidWidgetName = 'HomeWidgetProvider';
  static const String _iosWidgetName = 'HomeWidget';

  static Future<void> updateWidget(HomeWidgetSnapshot snapshot) async {
    try {
      print('DEBUG: HomeWidgetService.updateWidget called');
      await HomeWidget.saveWidgetData<String>('next_class_label', snapshot.nextClassLabel);
      await HomeWidget.saveWidgetData<String>('next_class_time', snapshot.nextClassTime);
      await HomeWidget.saveWidgetData<double>('attendance_percentage', snapshot.attendancePercentage);
      await HomeWidget.saveWidgetData<String>('risk_label', snapshot.riskLabel);

      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iosWidgetName,
      );
      print('DEBUG: HomeWidgetService.updateWidget completed');
    } catch (e) {
      print('DEBUG: HomeWidgetService error: $e');
    }
  }

  static Future<void> setupBackground() async {
  }
}
