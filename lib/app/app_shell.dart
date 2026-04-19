import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/lets_go_screen.dart';
import '../../features/engine/engine_screen.dart';
import '../../features/kanban/kanban_screen.dart';
import '../../features/focus/focus_screen.dart';
import '../../features/assistant/assistant_screen.dart';
import '../../features/study_hub/screens/rooms_screen.dart';
import '../../features/latex/latex_preview_screen.dart';
import '../../features/expenses/screens/expense_screen.dart';
import '../../features/calendar/calendar_heatmap_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../core/providers/app_state.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/nb_card.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0; 
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _setupHomeWidget();
    _fetchProfile();
  }

  void _fetchProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Supabase.instance.client
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
      // Logic for deep link
    }
  }

  void _onNavigate(int index) {
    setState(() => _currentIndex = index);
  }

  void _showAIDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LuminaAIDialog(),
    );
  }

  // BOTTOM NAV ITEMS: The Core Student Journey
  static const _navItems = [
    (Icons.bolt_rounded,            'Pulse',        NBColors.primary),
    (Icons.psychology_rounded,      'Deep Work',    NBColors.blue),
    (Icons.auto_awesome_rounded,    'Second Brain', NBColors.purple),
    (Icons.groups_rounded,          'Squad',        NBColors.warning),
    (Icons.person_rounded,          'Profile',      NBColors.pink),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return LetsGoScreen(onStart: () => setState(() => _hasStarted = true));
    }

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
          const FocusScreen(),
          const AssistantScreen(),
          const StudyHubRoomsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 2 ? null : FloatingActionButton(
        onPressed: () => _showAIDialog(context),
        backgroundColor: NBColors.primary,
        child: const Icon(Icons.smart_toy_rounded, color: NBColors.black),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: NBColors.white,
        border: Border(top: BorderSide(color: NBColors.black, width: 3)),
      ),
      child: Row(
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isSelected = _currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onNavigate(index),
              child: Container(
                color: isSelected ? item.$3.withValues(alpha: 0.1) : Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? item.$3 : Colors.transparent,
                        border: isSelected ? Border.all(color: NBColors.black, width: 2) : null,
                        borderRadius: NBRadius.softAll,
                      ),
                      child: Icon(
                        item.$1,
                        color: NBColors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2.toUpperCase(),
                      style: NBText.label.copyWith(
                        fontSize: 8,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
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
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _drawerSection('Core Tools'),
                _drawerItem(Icons.settings_input_component_rounded, 'The Engine', NBColors.primary, () => _push(const EngineScreen())),
                _drawerItem(Icons.view_kanban_rounded, 'Kanban Board', NBColors.blue, () => _push(const KanbanScreen())),
                _drawerItem(Icons.description_rounded, 'LaTeX Workspace', NBColors.warning, () => _push(const LaTeXPreviewScreen())),
                _drawerItem(Icons.payments_rounded, 'Expense Tracker', NBColors.pink, () => _push(const ExpenseScreen())),
                _drawerItem(Icons.calendar_month_rounded, 'Stress Heatmap', NBColors.danger, () => _push(const CalendarHeatmapScreen())),
                const SizedBox(height: 20),
                _drawerSection('Settings'),
                _drawerItem(Icons.cloud_download_rounded, 'AI Models', NBColors.purple, () {}),
                _drawerItem(Icons.logout_rounded, 'Logout', NBColors.danger, () => Supabase.instance.client.auth.signOut()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _push(Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        color: NBColors.primary,
        border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 40),
            const SizedBox(height: 8),
            Text('LUMINA', style: NBText.heading2.copyWith(letterSpacing: 4)),
          ],
        ),
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title.toUpperCase(), style: NBText.label.copyWith(fontSize: 10, color: const Color(0xFF777777))),
    );
  }

  Widget _drawerItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: NBCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          fillColor: NBColors.white,
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Text(label.toUpperCase(), style: NBText.label.copyWith(fontSize: 12)),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class LuminaAIDialog extends StatefulWidget {
  const LuminaAIDialog({super.key});

  @override
  State<LuminaAIDialog> createState() => _LuminaAIDialogState();
}

class _LuminaAIDialogState extends State<LuminaAIDialog> {
  final TextEditingController _controller = TextEditingController();
  String _result = "";
  bool _isLoading = false;
  bool _isStreaming = false;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final aiModels = state.aiModels;

    return Dialog(
      backgroundColor: NBColors.bg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                Text('LUMINA AI', style: NBText.heading3),
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
              style: NBText.bodySmall,
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
                  label: _isStreaming ? 'STREAMING...' : 'GENERATE',
                  color: NBColors.primary,
                  onPressed: () async {
                    if (_isStreaming || _controller.text.trim().isEmpty) return;
                    setState(() {
                      _isLoading = true;
                      _isStreaming = true;
                      _result = "";
                    });
                    
                    try {
                      final stream = aiModels.generateTextStream(_controller.text);
                      await for (final token in stream) {
                        if (!mounted) break;
                        setState(() {
                          _result += token;
                          _isLoading = false;
                        });
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                          _isStreaming = false;
                        });
                      }
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.mic_rounded,
                  label: 'LISTEN',
                  color: const Color(0xFF64B5F6),
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NBColors.white,
                    border: Border.all(color: NBColors.black, width: 2),
                    borderRadius: NBRadius.softAll,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RESULT:', style: NBText.label.copyWith(fontSize: 10)),
                      const SizedBox(height: 4),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Text(_result, style: NBText.bodySmall),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Result saved locally.')),
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
                          const Spacer(),
                          if (_isStreaming)
                            const Icon(Icons.sync_rounded, size: 16, color: NBColors.primary),
                        ],
                      ),
                    ],
                  ),
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
