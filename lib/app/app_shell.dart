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
import '../../core/widgets/nb_card.dart';
import '../../core/services/gemini_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0; 
  bool _hasStarted = false;

  // BOTTOM NAV ITEMS: The Core Student Journey
  static const _navItems = [
    (Icons.bolt_rounded,            'Pulse',        NBColors.primary),
    (Icons.psychology_rounded,      'Deep Work',    NBColors.blue),
    (Icons.auto_awesome_rounded,    'Second Brain', NBColors.purple),
    (Icons.groups_rounded,          'Squad',        NBColors.warning),
    (Icons.person_rounded,          'Profile',      NBColors.pink),
  ];

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

  @override
  Widget build(BuildContext context) {
    if (!_hasStarted) {
      return LetsGoScreen(onStart: () => setState(() => _hasStarted = true));
    }

    final tabItem = _navItems[_currentIndex];

    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: tabItem.$3,
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
              ),
              child: Icon(tabItem.$1, size: 14, color: NBColors.black),
            ),
            const SizedBox(width: 10),
            Text(tabItem.$2.toUpperCase(), style: NBText.heading3),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
              ),
              child: const Icon(Icons.menu_rounded, size: 18),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _showAISheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: NBColors.purple,
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                  boxShadow: NBShadows.small,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: NBColors.black),
                    const SizedBox(width: 4),
                    Text('ASK AI', style: NBText.label.copyWith(fontSize: 9)),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    );
  }

  void _showAISheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NBColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: NBColors.black, width: 2),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _LuminaAISheet(),
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
                _drawerItem(Icons.calendar_month_rounded, 'Stress Heatmap', NBColors.danger, () => _push(const CalendarHeatmapScreen())),
                _drawerItem(Icons.description_rounded, 'LaTeX Workspace', NBColors.warning, () => _push(const LaTeXPreviewScreen())),
                _drawerItem(Icons.payments_rounded, 'Expense Tracker', NBColors.pink, () => _push(const ExpenseScreen())),
                const SizedBox(height: 20),
                _drawerSection('Settings'),
                _drawerItem(Icons.logout_rounded, 'Logout', NBColors.danger, () {
                  Supabase.instance.client.auth.signOut();
                  Navigator.pop(context);
                }),
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

// ─────────────────────────────────────────────────────────────────────
//  Lumina AI Sheet — Bottom sheet with Gemini chat
// ─────────────────────────────────────────────────────────────────────

class _LuminaAISheet extends StatefulWidget {
  const _LuminaAISheet();

  @override
  State<_LuminaAISheet> createState() => _LuminaAISheetState();
}

class _LuminaAISheetState extends State<_LuminaAISheet> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMsg> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMsg(text, true));
      _controller.clear();
      _isLoading = true;
    });

    try {
      String response = '';
      final stream = GeminiService.instance.chatStream(text);
      _messages.add(_ChatMsg('', false));

      await for (final token in stream) {
        if (!mounted) break;
        response += token;
        setState(() {
          _messages.last = _ChatMsg(response, false);
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMsg('Error: $e', false));
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: NBColors.black, borderRadius: NBRadius.softAll),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: NBColors.purple,
                    border: Border.all(color: NBColors.black, width: 2),
                    borderRadius: NBRadius.softAll,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 16, color: NBColors.black),
                ),
                const SizedBox(width: 10),
                Text('LUMINA AI', style: NBText.heading3),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    GeminiService.instance.resetChat();
                    setState(() => _messages.clear());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: NBColors.black, width: 1.5),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Text('CLEAR', style: NBText.label.copyWith(fontSize: 8)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: NBColors.black, thickness: 1, height: 16),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text('Ask me anything about your studies!', style: NBText.bodySmall),
                        const SizedBox(height: 4),
                        Text('Attendance advice, study tips, note summaries...', 
                            style: NBText.bodySmall.copyWith(color: const Color(0xFF888888), fontSize: 11)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      return Align(
                        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: msg.isUser ? NBColors.primary : NBColors.white,
                            border: Border.all(color: NBColors.black, width: 2),
                            borderRadius: NBRadius.softAll,
                            boxShadow: NBShadows.small,
                          ),
                          child: Text(
                            msg.text.isEmpty ? '...' : msg.text,
                            style: NBText.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: NBColors.black, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: NBColors.white,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: TextField(
                      controller: _controller,
                      style: NBText.bodySmall,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask Lumina anything...',
                        hintStyle: TextStyle(color: Color(0xFF888888)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _send,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isLoading ? NBColors.black : NBColors.primary,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                      boxShadow: NBShadows.small,
                    ),
                    child: Icon(
                      _isLoading ? Icons.hourglass_top_rounded : Icons.send_rounded,
                      size: 20,
                      color: _isLoading ? NBColors.white : NBColors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final bool isUser;
  const _ChatMsg(this.text, this.isUser);
}
