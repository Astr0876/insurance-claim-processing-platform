// ─────────────────────────────────────────────────────────────────
//  lib/features/calendar/calendar_heatmap_screen.dart
//  Gmail & Calendar Heatmap Sync — Visual Stress Meter
//  PS Feature: "Gmail and Calendar Heatmap Sync"
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/services/calendar_service.dart';
import '../shared/widgets.dart';

class CalendarHeatmapScreen extends StatefulWidget {
  const CalendarHeatmapScreen({super.key});

  @override
  State<CalendarHeatmapScreen> createState() => _CalendarHeatmapScreenState();
}

class _CalendarHeatmapScreenState extends State<CalendarHeatmapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final calendar = state.calendar;
        final stressColor = state.stressColor;
        final heatmap = calendar.deadlineHeatmap;

        return Scaffold(
          backgroundColor: NBColors.bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 52, 16, 16),
                  decoration: const BoxDecoration(
                    color: NBColors.white,
                    border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: NBColors.black, width: 2),
                                borderRadius: NBRadius.softAll,
                                boxShadow: NBShadows.small,
                              ),
                              child: const Icon(Icons.arrow_back_rounded, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STRESS HEATMAP', style: NBText.heading2),
                                Text(
                                  'Gmail & Calendar Sync',
                                  style: NBText.bodySmall.copyWith(color: const Color(0xFF666666)),
                                ),
                              ],
                            ),
                          ),
                          NBBadge(
                            label: calendar.isSyncing ? 'SYNCING...' : 'SYNCED',
                            fillColor: calendar.isSyncing ? NBColors.orange : NBColors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stress Meter ────────────────────────────────────
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: NBCard(
                      fillColor: _stressStateColor(calendar.stressState),
                      shadows: NBShadows.large,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AnimatedPercentageRing(
                                percentage: state.stressLevel,
                                size: 80,
                                color: stressColor,
                                strokeWidth: 8,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${state.stressLevel.round()}',
                                      style: NBText.mono.copyWith(fontSize: 20, color: stressColor),
                                    ),
                                    Text('STRESS', style: NBText.label.copyWith(fontSize: 7)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CURRENT STATE', style: NBText.label.copyWith(fontSize: 9, letterSpacing: 2)),
                                    const SizedBox(height: 4),
                                    Text(state.stressLabel, style: NBText.heading2),
                                    const SizedBox(height: 8),
                                    _stressBar('Attendance Risk', (100 - state.attendance.overallPercentage).clamp(0, 100), NBColors.danger),
                                    const SizedBox(height: 4),
                                    _stressBar('Deadline Proximity', calendar.deadlineProximityScore, NBColors.orange),
                                    const SizedBox(height: 4),
                                    _stressBar('Cognitive Debt', (state.kanban.todoTasks.length * 12.0).clamp(0, 100), NBColors.purple),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Gmail Sync Button ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: NBCard(
                    fillColor: NBColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: NBColors.danger,
                                border: Border.all(color: NBColors.black, width: 2),
                                borderRadius: NBRadius.softAll,
                              ),
                              child: const Icon(Icons.email_rounded, color: NBColors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GMAIL DEADLINE SCANNER', style: NBText.label.copyWith(letterSpacing: 1.5)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Scans for: ${CalendarService.academicKeywords.join(", ")}',
                                    style: NBText.bodySmall.copyWith(fontSize: 9, color: const Color(0xFF888888)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        NBButton(
                          label: calendar.isSyncing ? '⏳ SCANNING GMAIL...' : '📧 SCAN GMAIL FOR DEADLINES',
                          fullWidth: true,
                          fillColor: calendar.isSyncing ? NBColors.black : NBColors.danger,
                          labelColor: NBColors.white,
                          onTap: calendar.isSyncing ? null : () => calendar.syncGmail(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Signs in with Google, scans recent emails for academic keywords, and auto-pushes deadlines to your Google Calendar.',
                          style: NBText.bodySmall.copyWith(fontSize: 10, color: const Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Calendar Heatmap ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: NBCard(
                    fillColor: NBColors.white,
                    shadows: NBShadows.medium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 4, height: 18, color: NBColors.black, margin: const EdgeInsets.only(right: 8)),
                            Text('30-DAY HEATMAP', style: NBText.label.copyWith(letterSpacing: 2)),
                            const Spacer(),
                            _legendDot(NBColors.green, 'Clear'),
                            const SizedBox(width: 8),
                            _legendDot(NBColors.orange, 'Busy'),
                            const SizedBox(width: 8),
                            _legendDot(NBColors.danger, 'Overload'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildHeatmapGrid(heatmap),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Deadlines List ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Container(width: 4, height: 18, color: NBColors.danger, margin: const EdgeInsets.only(right: 8)),
                      Text('UPCOMING DEADLINES', style: NBText.label.copyWith(letterSpacing: 2)),
                      const Spacer(),
                      NBBadge(label: '${calendar.deadlines.length} found'),
                    ],
                  ),
                ),
              ),

              if (calendar.deadlines.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: NBCard(
                      fillColor: NBColors.green,
                      child: Column(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 8),
                          Text('All clear!', style: NBText.heading3),
                          Text(
                            'No upcoming deadlines detected. Tap "Scan Gmail" to check.',
                            style: NBText.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final d = calendar.deadlines[i];
                        final daysLeft = d.date.difference(DateTime.now()).inDays;
                        final isUrgent = daysLeft <= 1;
                        final isSoon = daysLeft <= 3;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NBCard(
                            fillColor: isUrgent
                                ? NBColors.danger
                                : isSoon
                                    ? NBColors.orange
                                    : NBColors.white,
                            shadows: NBShadows.small,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isUrgent ? NBColors.white : NBColors.primary,
                                    border: Border.all(color: NBColors.black, width: 2),
                                    borderRadius: NBRadius.softAll,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('dd').format(d.date),
                                        style: NBText.mono.copyWith(fontSize: 16),
                                      ),
                                      Text(
                                        DateFormat('MMM').format(d.date).toUpperCase(),
                                        style: NBText.label.copyWith(fontSize: 8),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.title,
                                        style: NBText.heading3.copyWith(
                                          fontSize: 14,
                                          color: isUrgent ? NBColors.white : NBColors.black,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          NBBadge(
                                            label: d.source.toUpperCase(),
                                            fillColor: isUrgent ? NBColors.white : NBColors.black,
                                            textColor: isUrgent ? NBColors.black : NBColors.white,
                                            fontSize: 8,
                                          ),
                                          const SizedBox(width: 6),
                                          NBBadge(
                                            label: d.keyword.toUpperCase(),
                                            fillColor: NBColors.purple,
                                            fontSize: 8,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      daysLeft <= 0 ? 'TODAY' : '${daysLeft}d',
                                      style: NBText.mono.copyWith(
                                        fontSize: 20,
                                        color: isUrgent ? NBColors.white : NBColors.black,
                                      ),
                                    ),
                                    Text(
                                      'LEFT',
                                      style: NBText.label.copyWith(
                                        fontSize: 8,
                                        color: isUrgent ? NBColors.white : const Color(0xFF888888),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: calendar.deadlines.length,
                    ),
                  ),
                ),

              // ── Add Manual Deadline ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: NBCard(
                    fillColor: NBColors.purple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HOW IT WORKS', style: NBText.label.copyWith(letterSpacing: 2)),
                        const SizedBox(height: 12),
                        ...[
                          ('📧', 'Signs in with Google OAuth'),
                          ('🔍', 'Scans Gmail for academic keywords (Exam, Deadline, Lab, Viva...)'),
                          ('📅', 'Auto-pushes found deadlines to Google Calendar with ⚠️ prefix'),
                          ('🔥', 'Calculates Stress State: Green → Yellow → Red based on collisions'),
                          ('📊', 'Heatmap shows 30-day deadline density at a glance'),
                        ].map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.$1, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(t.$2, style: NBText.bodySmall)),
                            ],
                          ),
                        )),
                      ],
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

  // ── Heatmap grid (30 days) ──────────────────────────────────────
  Widget _buildHeatmapGrid(Map<DateTime, double> heatmap) {
    final today = DateTime.now();
    final cells = List.generate(30, (i) {
      final date = today.add(Duration(days: i - 15)); // 15 days before + 15 days after
      final dateOnly = DateTime(date.year, date.month, date.day);
      final intensity = heatmap[dateOnly] ?? 0.0;
      final isToday = dateOnly.year == today.year && dateOnly.month == today.month && dateOnly.day == today.day;

      Color cellColor;
      if (intensity >= 0.7) {
        cellColor = NBColors.danger;
      } else if (intensity >= 0.4) {
        cellColor = NBColors.orange;
      } else if (intensity > 0) {
        cellColor = NBColors.primary;
      } else {
        cellColor = NBColors.green.withValues(alpha: 0.3);
      }

      return Tooltip(
        message: '${DateFormat('dd MMM').format(date)}: ${intensity > 0 ? "Busy" : "Clear"}',
        child: Container(
          decoration: BoxDecoration(
            color: cellColor,
            border: Border.all(
              color: isToday ? NBColors.black : NBColors.black.withValues(alpha: 0.2),
              width: isToday ? 3 : 1,
            ),
            borderRadius: NBRadius.softAll,
          ),
          child: isToday
              ? Center(
                  child: Text(
                    DateFormat('d').format(date),
                    style: NBText.label.copyWith(fontSize: 8),
                  ),
                )
              : null,
        ),
      );
    });

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: cells,
    );
  }

  Widget _stressBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: NBText.label.copyWith(fontSize: 8), overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(height: 6, color: NBColors.black.withValues(alpha: 0.1)),
              FractionallySizedBox(
                widthFactor: (value / 100).clamp(0, 1),
                child: Container(height: 6, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(width: 24, child: Text('${value.round()}', style: NBText.monoSmall.copyWith(fontSize: 9))),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: NBText.label.copyWith(fontSize: 7)),
      ],
    );
  }

  Color _stressStateColor(StressState state) {
    switch (state) {
      case StressState.red: return const Color(0xFFFFEAEA);
      case StressState.yellow: return const Color(0xFFFFF8E1);
      case StressState.green: return const Color(0xFFE8F5E9);
    }
  }
}
