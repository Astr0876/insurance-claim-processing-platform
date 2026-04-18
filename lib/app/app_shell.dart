import 'package:flutter/material.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/kanban/kanban_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/assistant/assistant_screen.dart';

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

  // Nav items: icon + label
  static const _navItems = [
    (Icons.dashboard_rounded,       'Home'),
    (Icons.calendar_month_rounded,  'Schedule'),
    (Icons.view_kanban_rounded,     'Kanban'),
    (Icons.fact_check_rounded,      'Attend'),
    (Icons.psychology_rounded,      'Focus'),
    (Icons.smart_toy_rounded,       'Ask AI'),
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
          const KanbanScreen(),
          const AttendanceScreen(),
          const FocusScreen(),
          const AssistantScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: NBColors.white,
        border: const Border(
          top: BorderSide(color: NBColors.black, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: NBColors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              return _navItem(i, _navItems[i].$1, _navItems[i].$2);
            }),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? NBColors.primary : Colors.transparent,
          border: isActive
              ? Border.all(color: NBColors.black, width: 2)
              : null,
          borderRadius: NBRadius.softAll,
          boxShadow: isActive ? NBShadows.small : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: NBColors.black,
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: NBText.label.copyWith(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
