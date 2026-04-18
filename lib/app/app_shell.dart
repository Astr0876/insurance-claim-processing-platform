import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/timetable/timetable_screen.dart';
import '../../features/kanban/kanban_screen.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/assistant/assistant_screen.dart';
import '../../features/study_hub/screens/rooms_screen.dart';
import '../../features/latex/latex_preview_screen.dart';
import '../../features/expenses/screens/expense_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0; 

  @override
  void initState() {
    super.initState();
    _setupHomeWidget();
  }

  void _setupHomeWidget() {
    HomeWidget.setAppGroupId('group.lockin.widget');
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetClick);
    HomeWidget.widgetClicked.listen(_handleWidgetClick);
  }

  void _handleWidgetClick(Uri? uri) {
    if (uri != null && (uri.scheme == 'homewidget' || uri.scheme == 'homeWidget') && uri.host == 'log_spend') {
      setState(() => _currentIndex = 8); // Expenses screen
    }
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  // Nav items: icon + label + accent colour
  static const _navItems = [
    (Icons.dashboard_rounded,       'Home',      AppColors.primary),
    (Icons.calendar_month_rounded,  'Schedule',  AppColors.accent),
    (Icons.view_kanban_rounded,     'Kanban',    AppColors.warning),
    (Icons.fact_check_rounded,      'Attend',    AppColors.safe),
    (Icons.psychology_rounded,      'Focus',     AppColors.primary),
    (Icons.smart_toy_rounded,       'RAG Assistant', AppColors.accent),
    (Icons.groups_rounded,          'Study Hub', AppColors.warning),
    (Icons.description_rounded,     'LaTeX Workspace', AppColors.primary),
    (Icons.account_balance_wallet_rounded, 'Expenses', AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        title: Text(_navItems[_currentIndex].$2.toUpperCase()),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onNavigate: _onNavigate),
          const TimetableScreen(),
          const KanbanScreen(),
          const AttendanceScreen(),
          const FocusScreen(),
          const AssistantScreen(),
          const StudyHubRoomsScreen(),
          const LaTeXPreviewScreen(),
          const ExpenseScreen(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: NBColors.bg,
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: NBColors.black, width: 2),
      ),
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: NBColors.primary,
              border: Border(
                bottom: BorderSide(color: NBColors.black, width: 2),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NBColors.white,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                      boxShadow: NBShadows.small,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: NBColors.black,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'LUMINA',
                    style: NBText.heading2.copyWith(letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _navItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _currentIndex == index;
                final isRag = index == 5;
                
                return GestureDetector(
                  onTap: () {
                    _onNavigate(index);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive 
                          ? item.$3 
                          : (isRag ? const Color(0xFFF3E5F5) : NBColors.white),
                      border: Border.all(
                        color: NBColors.black, 
                        width: isRag && !isActive ? 2.5 : 2,
                      ),
                      borderRadius: NBRadius.softAll,
                      boxShadow: isActive ? NBShadows.small : NBShadows.small,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.$1,
                          color: NBColors.black,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.$2.toUpperCase(),
                            style: NBText.label.copyWith(
                              fontSize: 14,
                              fontWeight: isActive || isRag ? FontWeight.w900 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isRag && !isActive)
                          const Icon(Icons.star_rounded, color: Colors.purple, size: 18),
                        if (isActive) ...[
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: NBColors.black, width: 2),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: NBColors.primary,
                  child: Icon(Icons.person_outline_rounded, color: NBColors.black),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Name', style: NBText.label),
                    Text('View Profile', style: NBText.bodySmall.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
