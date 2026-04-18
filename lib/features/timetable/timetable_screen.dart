import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_badge.dart';
import '../../core/services/timetable_service.dart';
import '../shared/widgets.dart';
import 'import_review_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isImporting = false;
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final _fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  // Accent colours per day (for visual variety)
  static const _dayColors = [
    NBColors.blue,
    NBColors.pink,
    NBColors.primary,
    NBColors.purple,
    NBColors.green,
  ];

  @override
  void initState() {
    super.initState();
    int todayIdx = DateTime.now().weekday - 1;
    if (todayIdx > 4) todayIdx = 0;
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: todayIdx,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: NBColors.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SCHEDULE',
                        style: NBText.label.copyWith(
                          color: const Color(0xFF777777),
                          letterSpacing: 2,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Timetable', style: NBText.heading1),
                          ),
                          _buildImportButton(state),
                          const SizedBox(width: 8),
                          _buildAddButton(state),
                        ],
                      ),
                      Text(
                        'Week at a glance',
                        style: NBText.body.copyWith(
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Day Tabs ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: NBColors.white,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                      boxShadow: NBShadows.small,
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: NBColors.primary,
                        border: const Border(
                          right: BorderSide(color: NBColors.black, width: 1),
                          left: BorderSide(color: NBColors.black, width: 1),
                        ),
                        borderRadius: NBRadius.softAll,
                      ),
                      labelColor: NBColors.black,
                      unselectedLabelColor: const Color(0xFF888888),
                      labelStyle: NBText.label.copyWith(fontSize: 11),
                      unselectedLabelStyle: NBText.label.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: _days.map((d) => Tab(text: d)).toList(),
                      onTap: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),

              // ── Schedule ────────────────────────────────────────
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return _buildDaySchedule(
                      state,
                      _fullDays[_tabController.index],
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton(AppState state) {
    return GestureDetector(
      onTap: () => _showAddClassDialog(state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: NBColors.primary,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: NBShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: NBColors.black, size: 18),
            const SizedBox(width: 4),
            Text('ADD CLASS', style: NBText.label.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(AppState state) {
    return GestureDetector(
      onTap: _isImporting ? null : () => _pickAndImportTimetable(state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: NBColors.blue,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: NBShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isImporting
                  ? Icons.hourglass_top_rounded
                  : Icons.upload_file_rounded,
              color: NBColors.black,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              _isImporting ? 'IMPORTING' : 'IMPORT',
              style: NBText.label.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule(AppState state, String day) {
    final daySchedule = state.timetable.schedule
        .where((s) => s.day == day)
        .toList();

    if (daySchedule.isEmpty || daySchedule.first.classes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: NBCard(
          fillColor: NBColors.white,
          child: Column(
            children: [
              const Icon(
                Icons.weekend_rounded,
                color: NBColors.black,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'No classes scheduled',
                style: NBText.body.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Enjoy your free day!',
                style: NBText.bodySmall.copyWith(
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final classes = daySchedule.first.classes;
    final isToday = day == _getCurrentDay();
    final dayIdx = _fullDays.indexOf(day);
    final dayColor = dayIdx >= 0 ? _dayColors[dayIdx] : NBColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (isToday)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: NBColors.green,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Text(
                    'TODAY',
                    style: NBText.label.copyWith(
                      color: NBColors.green,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ...classes.asMap().entries.map((entry) {
            final idx = entry.key;
            final cls = entry.value;
            final attendanceData = state.attendance.records[cls.subject];
            final pct = attendanceData?.percentage ?? 100.0;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + idx * 80),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - val)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: _buildClassCard(
                  cls.subject,
                  cls.time,
                  cls.room,
                  cls.durationMinutes,
                  pct,
                  state,
                  dayColor,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    String subject,
    String time,
    String room,
    int duration,
    double attendance,
    AppState state,
    Color accentColor,
  ) {
    final statusColor = NBColors.statusColor(attendance);
    return NBCard(
      shadows: NBShadows.small,
      child: Row(
        children: [
          // Day-accent bar
          Container(
            width: 5,
            height: 64,
            color: accentColor,
            margin: const EdgeInsets.only(right: NBSpacing.md),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: NBText.heading3),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  children: [
                    _chip(Icons.access_time_rounded, time),
                    _chip(Icons.room_rounded, room),
                    _chip(Icons.timer_outlined, '${duration}m'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              NBBadge(
                label: '${attendance.toStringAsFixed(0)}%',
                fillColor: statusColor,
                textColor: NBColors.white,
                fontSize: 11,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniBtn(
                    Icons.check_rounded,
                    NBColors.green,
                    () => state.markAttended(subject),
                  ),
                  const SizedBox(width: 4),
                  _miniBtn(
                    Icons.close_rounded,
                    NBColors.danger,
                    () => state.markAbsent(subject),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
        ),
        child: Icon(icon, color: NBColors.black, size: 14),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF666666), size: 13),
        const SizedBox(width: 3),
        Text(
          text,
          style: NBText.bodySmall.copyWith(color: const Color(0xFF555555)),
        ),
      ],
    );
  }

  String _getCurrentDay() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[DateTime.now().weekday - 1];
  }

  void _showAddClassDialog(AppState state) {
    final subjectCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final roomCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: NBColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: NBColors.black, width: 2),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  color: NBColors.black,
                  margin: const EdgeInsets.only(bottom: 16),
                ),
              ),
              Text('ADD NEW CLASS', style: NBText.heading2),
              const SizedBox(height: NBSpacing.xl),
              TextField(
                controller: subjectCtrl,
                style: NBText.body,
                decoration: const InputDecoration(
                  hintText: 'Subject Name',
                  prefixIcon: Icon(Icons.book_rounded, color: NBColors.black),
                ),
              ),
              const SizedBox(height: NBSpacing.md),
              TextField(
                controller: timeCtrl,
                style: NBText.body,
                decoration: const InputDecoration(
                  hintText: 'Time (e.g. 9:00 AM)',
                  prefixIcon: Icon(
                    Icons.access_time_rounded,
                    color: NBColors.black,
                  ),
                ),
              ),
              const SizedBox(height: NBSpacing.md),
              TextField(
                controller: roomCtrl,
                style: NBText.body,
                decoration: const InputDecoration(
                  hintText: 'Room',
                  prefixIcon: Icon(Icons.room_rounded, color: NBColors.black),
                ),
              ),
              const SizedBox(height: NBSpacing.xl),
              // NB-style button
              GestureDetector(
                onTap: () {
                  if (subjectCtrl.text.isNotEmpty) {
                    state.addManualClass(
                      _fullDays[_tabController.index],
                      TimetableEntry(
                        subject: subjectCtrl.text,
                        time: timeCtrl.text.isEmpty ? '9:00 AM' : timeCtrl.text,
                        room: roomCtrl.text.isEmpty ? 'TBA' : roomCtrl.text,
                        durationMinutes: 60,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: NBColors.primary,
                    border: Border.all(color: NBColors.black, width: 2),
                    borderRadius: NBRadius.softAll,
                    boxShadow: NBShadows.medium,
                  ),
                  child: Center(
                    child: Text(
                      'ADD CLASS',
                      style: NBText.label.copyWith(
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndImportTimetable(AppState state) async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        return;
      }

      final file = result.files.single;
      final ext = file.extension?.toLowerCase();
      final importType = ext == 'pdf'
          ? TimetableImportType.pdf
          : TimetableImportType.image;

      final importResult = await state.importTimetableFile(
        filePath: file.path!,
        type: importType,
      );

      if (!mounted) return;
      if (!importResult.isSuccess) {
        _showImportFailure(importResult);
        return;
      }

      final reviewed = await Navigator.of(context).push<List<ParsedClassSlot>>(
        MaterialPageRoute(
          builder: (_) => TimetableImportReviewScreen(
            initialSlots: importResult.slots,
            issues: importResult.issues,
            rawText: importResult.rawText,
          ),
        ),
      );

      if (!mounted || reviewed == null || reviewed.isEmpty) return;
      state.applyImportedTimetable(reviewed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${reviewed.length} class slots.')),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportFailure(TimetableImportResult result) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NBColors.bg,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import Failed', style: NBText.heading3),
              const SizedBox(height: 8),
              Text(result.errorMessage ?? 'Unknown error', style: NBText.body),
              if (result.issues.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Parser issues: ${result.issues.length}',
                  style: NBText.label,
                ),
              ],
              if (result.rawText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  result.rawText.length > 500
                      ? '${result.rawText.substring(0, 500)}...'
                      : result.rawText,
                  style: NBText.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
