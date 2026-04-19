import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_badge.dart';
import '../timetable/timetable_screen.dart';
import '../attendance/attendance_screen.dart';

class EngineScreen extends StatefulWidget {
  const EngineScreen({super.key});

  @override
  State<EngineScreen> createState() => _EngineScreenState();
}

class _EngineScreenState extends State<EngineScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NBColors.bg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: const BoxDecoration(
              color: NBColors.white,
              border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings_input_component_rounded, color: NBColors.black),
                    const SizedBox(width: 12),
                    Text('THE ENGINE', style: NBText.heading2),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Automated scheduling, attendance, and bunk optimization.',
                  style: NBText.bodySmall,
                ),
              ],
            ),
          ),

          // ── Tab Bar ──────────────────────────────────────────────
          Container(
            height: 48,
            decoration: const BoxDecoration(
              color: NBColors.white,
              border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: NBColors.black,
              unselectedLabelColor: const Color(0xFF888888),
              indicator: const BoxDecoration(
                color: NBColors.primary,
                border: Border(
                  left: BorderSide(color: NBColors.black, width: 1),
                  right: BorderSide(color: NBColors.black, width: 1),
                  bottom: BorderSide(color: NBColors.black, width: 4),
                ),
              ),
              labelStyle: NBText.label.copyWith(fontSize: 10),
              tabs: const [
                Tab(text: 'TODAY'),
                Tab(text: 'SCHEDULE'),
                Tab(text: 'ATTENDANCE'),
              ],
            ),
          ),

          // ── Tab Views ───────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TodayAgendaView(),
                const TimetableScreen(),
                const AttendanceScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayAgendaView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final today = state.timetable.getTodaySchedule();
        final overallPct = state.attendance.overallPercentage;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Bunk Health Summary
            NBCard(
              fillColor: NBColors.statusColor(overallPct),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BUNK STATUS', style: NBText.label),
                      NBBadge(
                        label: '${overallPct.toStringAsFixed(1)}%',
                        fillColor: NBColors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    overallPct >= 75 
                      ? 'You can safely bunk ${state.attendance.totalSafeBunks} more classes today.'
                      : 'You need to attend ${state.attendance.classesToRecover} more classes to reach 75%.',
                    style: NBText.heading3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Today's classes
            Row(
              children: [
                Container(width: 4, height: 18, color: NBColors.black, margin: const EdgeInsets.only(right: 8)),
                Text('TODAY\'S AGENDA', style: NBText.label.copyWith(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            
            if (today == null || today.classes.isEmpty)
              NBCard(
                child: Center(
                  child: Column(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text('No classes scheduled for today.', style: NBText.body),
                    ],
                  ),
                ),
              )
            else
              ...today.classes.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NBCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(c.time.split(' ')[0], style: NBText.heading3),
                          Text(c.time.split(' ')[1], style: NBText.label.copyWith(fontSize: 9)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(width: 2, height: 30, color: NBColors.black.withValues(alpha: 0.1)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.subject, style: NBText.heading3.copyWith(fontSize: 15)),
                            Text(c.room, style: NBText.bodySmall),
                          ],
                        ),
                      ),
                      _ClassStatusIcon(entry: c, state: state),
                    ],
                  ),
                ),
              )),
          ],
        );
      },
    );
  }
}

class _ClassStatusIcon extends StatelessWidget {
  final dynamic entry;
  final AppState state;
  const _ClassStatusIcon({required this.entry, required this.state});

  @override
  Widget build(BuildContext context) {
    // Determine if class is past or upcoming
    return const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFFCCCCCC), size: 20);
  }
}
