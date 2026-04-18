import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_badge.dart';
import '../shared/widgets.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  bool _isTracking = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final focusScore  = state.focus.todayFocusScore;
        final studyMins   = state.focus.todayStudyMinutes;
        final appSwitches = state.focus.todayAppSwitches;
        final distractions = state.focus.todayDistractions;
        final weeklyScores = state.focus.weeklyScores;
        final focusColor   = NBColors.statusColor(focusScore);

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
                        'PRODUCTIVITY',
                        style: NBText.label.copyWith(
                          color: const Color(0xFF777777),
                          letterSpacing: 2,
                        ),
                      ),
                      Text('Focus Tracker', style: NBText.heading1),
                      Text(
                        'Monitor your study patterns',
                        style: NBText.body.copyWith(
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Focus score hero ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: NBCard(
                    fillColor: focusColor,
                    shadows: NBShadows.large,
                    child: Column(
                      children: [
                        // Score ring
                        AnimatedPercentageRing(
                          percentage: focusScore,
                          size: 130,
                          color: NBColors.black,
                          strokeWidth: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${focusScore.round()}',
                                style: NBText.mono.copyWith(fontSize: 40),
                              ),
                              Text(
                                'FOCUS',
                                style: NBText.label.copyWith(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: NBSpacing.xl),

                        // Stat chips row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StatChip(
                              icon: Icons.timer_rounded,
                              label: 'Study Time',
                              value: TimeHelper.formatDuration(studyMins),
                              color: NBColors.primary,
                            ),
                            StatChip(
                              icon: Icons.swap_horiz_rounded,
                              label: 'App Switches',
                              value: '$appSwitches',
                              color: NBColors.orange,
                            ),
                            StatChip(
                              icon: Icons.notifications_active_rounded,
                              label: 'Distractions',
                              value: '$distractions',
                              color: NBColors.danger,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Start / Stop session button ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: _SessionButton(
                    isTracking: _isTracking,
                    onToggle: () {
                      setState(() => _isTracking = !_isTracking);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isTracking
                                ? 'Focus session ended!'
                                : 'Focus session started! Stay focused 🎯',
                          ),
                          backgroundColor: NBColors.black,
                          behavior: SnackBarBehavior.floating,
                          shape: const RoundedRectangleBorder(
                            borderRadius: NBRadius.softAll,
                            side: BorderSide(color: NBColors.black, width: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Weekly chart ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: NBCard(
                    shadows: NBShadows.medium,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEEKLY FOCUS TREND',
                          style: NBText.label.copyWith(letterSpacing: 2),
                        ),
                        const SizedBox(height: NBSpacing.lg),
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => NBColors.black,
                                  getTooltipItem: (group, _, rod, __) {
                                    return BarTooltipItem(
                                      '${rod.toY.round()}%',
                                      NBText.label.copyWith(
                                        color: NBColors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx >= 0 && idx < weeklyScores.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            weeklyScores[idx].key,
                                            style: NBText.label.copyWith(
                                              fontSize: 9,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: weeklyScores.asMap().entries.map((entry) {
                                final score = entry.value.value;
                                final barColor = NBColors.statusColor(score);
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: score,
                                      width: 22,
                                      borderRadius: BorderRadius.zero, // sharp NB bars
                                      color: barColor,
                                      borderSide: const BorderSide(
                                        color: NBColors.black,
                                        width: 2,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Today's sessions header ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: const SectionHeader(title: "Today's Sessions"),
                ),
              ),

              // ── Session list ─────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = state.focus.todaySessions[index];
                    final sColor  = NBColors.statusColor(session.focusScore);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      child: NBCard(
                        shadows: NBShadows.small,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: sColor,
                                border: Border.all(
                                    color: NBColors.black, width: 2),
                                borderRadius: NBRadius.softAll,
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: NBColors.black,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: NBSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.label,
                                    style: NBText.body.copyWith(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${TimeHelper.formatDuration(session.durationMinutes)} • ${session.appSwitches} switches',
                                    style: NBText.bodySmall.copyWith(
                                        color: const Color(0xFF666666)),
                                  ),
                                ],
                              ),
                            ),
                            NBBadge(
                              label: '${session.focusScore.round()}%',
                              fillColor: sColor,
                              textColor: NBColors.white,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: state.focus.todaySessions.length,
                ),
              ),

              // ── Weekly summary card ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: NBCard(
                    fillColor: NBColors.purple,
                    shadows: NBShadows.medium,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _weekStat(
                          'WEEKLY AVG',
                          '${state.focus.weeklyAverageFocusScore.round()}%',
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: NBColors.black,
                        ),
                        _weekStat(
                          'TOTAL STUDY',
                          TimeHelper.formatDuration(
                              state.focus.totalStudyMinutesWeek),
                        ),
                        Container(
                          width: 2,
                          height: 40,
                          color: NBColors.black,
                        ),
                        _weekStat(
                          'SESSIONS',
                          '${state.focus.sessions.length}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _weekStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: NBText.mono.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          label,
          style: NBText.label.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

/// Tactile Start / Stop session button
class _SessionButton extends StatefulWidget {
  final bool isTracking;
  final VoidCallback onToggle;

  const _SessionButton({
    required this.isTracking,
    required this.onToggle,
  });

  @override
  State<_SessionButton> createState() => _SessionButtonState();
}

class _SessionButtonState extends State<_SessionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final fill = widget.isTracking ? NBColors.danger : NBColors.green;

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() { _pressed = false; widget.onToggle(); }),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: _pressed
            ? Matrix4.translationValues(4, 4, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: _pressed ? NBShadows.pressed : NBShadows.medium,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isTracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: NBColors.black,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              (widget.isTracking
                      ? 'End Focus Session'
                      : 'Start Focus Session')
                  .toUpperCase(),
              style: NBText.label.copyWith(fontSize: 13, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
