import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/auth_screen.dart';
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
import '../../features/profile/screens/profile_screen.dart';
import '../../core/providers/app_state.dart';
import 'package:provider/provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0; 
  Future<Map<String, dynamic>?>? _profileFuture;

  @override
  void initState() {
    super.initState();
    _setupHomeWidget();
    _fetchProfile();
  }

  void _fetchProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _profileFuture = Supabase.instance.client
          .from('profiles')
          .select('student_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRunAnywhereDialog(context),
        backgroundColor: NBColors.primary,
        child: const Icon(Icons.bolt_rounded, color: NBColors.black),
      ),
    );
  }

  void _showRunAnywhereDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RunAnywhereDialog(),
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
          FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: NBColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final user = Supabase.instance.client.auth.currentUser;
              final profile = snapshot.data;
              final studentName = profile?['student_name'] as String? ?? 
                                 user?.email?.split('@')[0] ?? 
                                 'Student';
              final avatarUrl = profile?['avatar_url'] as String?;

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: NBColors.white,
                    border: Border(
                      top: BorderSide(color: NBColors.black, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: NBColors.primary,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null 
                            ? const Icon(Icons.person_outline_rounded, color: NBColors.black) 
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName, 
                              style: NBText.label, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis
                            ),
                            Text(
                              'View Profile', 
                              style: NBText.bodySmall.copyWith(
                                fontSize: 10, 
                                color: NBColors.primary, 
                                decoration: TextDecoration.underline
                              )
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: NBColors.black),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class RunAnywhereDialog extends StatefulWidget {
  const RunAnywhereDialog({super.key});

  @override
  State<RunAnywhereDialog> createState() => _RunAnywhereDialogState();
}

class _RunAnywhereDialogState extends State<RunAnywhereDialog> {
  final TextEditingController _controller = TextEditingController();
  String _result = "";
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final aiModels = state.aiModels;

    return Dialog(
      backgroundColor: NBColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: NBRadius.softAll,
        side: const BorderSide(color: NBColors.black, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('RUN ANYWHERE', style: NBText.heading3),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                filled: true,
                fillColor: NBColors.white,
                border: OutlineInputBorder(
                  borderRadius: NBRadius.softAll,
                  borderSide: const BorderSide(color: NBColors.black, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'GENERATE',
                  color: NBColors.primary,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    final res = await aiModels.generateText(_controller.text);
                    setState(() {
                      _result = res;
                      _isLoading = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.mic_rounded,
                  label: 'LISTEN',
                  color: NBColors.blue,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    final res = await aiModels.listen();
                    _controller.text = res;
                    setState(() => _isLoading = false);
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.volume_up_rounded,
                  label: 'SPEAK',
                  color: NBColors.warning,
                  onPressed: () {
                    aiModels.speak(_result.isEmpty ? _controller.text : _result);
                  },
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator(color: NBColors.primary)),
            ],
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: NBColors.white,
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESULT:', style: NBText.label.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(_result, style: NBText.bodySmall),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        // Mock download
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading result as text file...')),
                        );
                      },
                      child: Text(
                        'DOWNLOAD RESULT',
                        style: NBText.bodySmall.copyWith(
                          color: NBColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NBColors.black, width: 2),
            borderRadius: NBRadius.softAll,
            boxShadow: NBShadows.small,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: NBColors.black),
              const SizedBox(height: 4),
              Text(label, style: NBText.label.copyWith(fontSize: 8)),
            ],
          ),
        ),
      ),
    );
  }
}
