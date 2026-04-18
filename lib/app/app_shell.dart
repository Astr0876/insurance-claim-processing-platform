import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/assistant/assistant_screen.dart';
import '../../features/study_hub/screens/rooms_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  // Nav items: icon + label + accent colour
  static const _navItems = [
    (Icons.dashboard_rounded,       'Home',     NBColors.primary),
    (Icons.calendar_month_rounded,  'Schedule', NBColors.blue),
    (Icons.fact_check_rounded,      'Attend',   NBColors.green),
    (Icons.psychology_rounded,      'Focus',    NBColors.purple),
    (Icons.smart_toy_rounded,       'Ask AI',   NBColors.pink),
    (Icons.groups_rounded,          'Hub',      NBColors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onNavigate: _onNavigate),
          const TimetableScreen(),
          const AttendanceScreen(),
          const FocusScreen(),
          const AssistantScreen(),
          const StudyHubRoomsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: NBColors.white,
        border: Border(
          top: BorderSide(color: NBColors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(color: NBColors.black, offset: Offset(0, -3), blurRadius: 0),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              return _navItem(i, _navItems[i].$1, _navItems[i].$2, _navItems[i].$3);
            }),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color accent) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 10 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? accent : Colors.transparent,
          border: isActive ? Border.all(color: NBColors.black, width: 2) : null,
          borderRadius: NBRadius.softAll,
          boxShadow: isActive ? NBShadows.small : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: NBColors.black, size: 20),
            if (isActive) ...[
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: NBText.label.copyWith(fontSize: 8, letterSpacing: 0.8),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
