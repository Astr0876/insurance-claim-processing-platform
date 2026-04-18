import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_badge.dart';
import '../shared/widgets.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimations = List.generate(5, (i) {
      final start = i * 0.12;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (!state.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: NBColors.black),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(state)),

            // ── Stress card ────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimations[0],
                child: _buildStressCard(state),
              ),
            ),

            // ── Stats row ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimations[1],
                child: _buildStatsRow(state),
              ),
            ),

            // ── Upcoming class ─────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimations[2],
                child: _buildUpcomingClass(state),
              ),
            ),

            // ── Quick actions ──────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimations[3],
                child: _buildQuickActions(),
              ),
            ),

            // ── Bunk calculator ────────────────────────────────────
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimations[4],
                child: _buildBunkSummary(state),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────

  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
      color: NBColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TimeHelper.greeting().toUpperCase(),
            style: NBText.label.copyWith(
              color: const Color(0xFF777777),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text('LUMINA', style: NBText.heading1),
              ),
              // Profile badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NBColors.primary,
                  border: Border.all(color: NBColors.black, width: 2),
                  borderRadius: NBRadius.softAll,
                  boxShadow: NBShadows.small,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: NBColors.black,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: NBColors.black,
            child: Text(
              'Your Proactive Student Sidekick',
              style: NBText.label.copyWith(
                color: NBColors.white,
                letterSpacing: 1.5,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stress card ───────────────────────────────────────────────────

  Widget _buildStressCard(AppState state) {
    final stressColor = state.stressColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: NBCard(
        fillColor: NBColors.white,
        shadows: NBShadows.medium,
        child: Row(
          children: [
            // Ring
            AnimatedPercentageRing(
              percentage: state.stressLevel,
              size: 72,
              color: stressColor,
              strokeWidth: 7,
              child: Text(
                '${state.stressLevel.round()}',
                style: NBText.monoSmall.copyWith(color: stressColor),
              ),
            ),
            const SizedBox(width: NBSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STRESS LEVEL',
                    style: NBText.label.copyWith(
                      color: const Color(0xFF777777),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        state.stressLabel,
                        style: NBText.heading3.copyWith(color: stressColor),
                      ),
                      const SizedBox(width: 8),
                      NBBadge(
                        label: '${state.stressLevel.round()}',
                        fillColor: stressColor,
                        textColor: NBColors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Hard progress bar
                  ClipRRect(
                    borderRadius: NBRadius.softAll,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: state.stressLevel / 100),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              color: stressColor.withValues(alpha: 0.15),
                            ),
                            FractionallySizedBox(
                              widthFactor: value,
                              child: Container(height: 8, color: stressColor),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────

  Widget _buildStatsRow(AppState state) {
    final attendance = state.attendance.overallPercentage;
    final focusScore = state.focus.todayFocusScore;
    final studyMins  = state.focus.todayStudyMinutes;
    final attColor   = NBColors.statusColor(attendance);
    final focusColor = NBColors.statusColor(focusScore);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          // Attendance
          Expanded(
            child: NBCard(
              onTap: () => widget.onNavigate?.call(2),
              shadows: NBShadows.medium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fact_check_rounded, color: attColor, size: 18),
                      const Spacer(),
                      NBBadge(
                        label: '${attendance.toStringAsFixed(1)}%',
                        fillColor: attColor,
                        textColor: NBColors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: NBSpacing.md),
                  AnimatedPercentageRing(
                    percentage: attendance,
                    size: 80,
                    color: attColor,
                    strokeWidth: 8,
                    child: Text(
                      '${attendance.round()}%',
                      style: NBText.monoSmall.copyWith(color: attColor, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: NBSpacing.sm),
                  Text(
                    'ATTENDANCE',
                    style: NBText.label.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Focus
          Expanded(
            child: NBCard(
              onTap: () => widget.onNavigate?.call(3),
              shadows: NBShadows.medium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: focusColor, size: 18),
                      const Spacer(),
                      NBBadge(
                        label: TimeHelper.formatDuration(studyMins),
                        fillColor: NBColors.blue,
                        textColor: NBColors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: NBSpacing.md),
                  AnimatedPercentageRing(
                    percentage: focusScore,
                    size: 80,
                    color: focusColor,
                    strokeWidth: 8,
                    child: Text(
                      '${focusScore.round()}',
                      style: NBText.monoSmall.copyWith(color: focusColor, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: NBSpacing.sm),
                  Text(
                    'FOCUS SCORE',
                    style: NBText.label.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upcoming class ────────────────────────────────────────────────

  Widget _buildUpcomingClass(AppState state) {
    final nextClass = state.timetable.getNextClass();
    final todayCount = state.timetable.totalClassesToday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: NBCard(
        fillColor: NBColors.primary,
        shadows: NBShadows.medium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: NBColors.black, size: 20),
                const SizedBox(width: 8),
                Text('UP NEXT', style: NBText.label.copyWith(letterSpacing: 2)),
                const Spacer(),
                NBBadge(
                  label: '$todayCount classes today',
                  fillColor: NBColors.black,
                  textColor: NBColors.white,
                ),
              ],
            ),
            const SizedBox(height: NBSpacing.md),
            if (nextClass != null) ...[
              Text(
                nextClass.subject,
                style: NBText.heading2,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: NBSpacing.md,
                children: [
                  _infoChip(Icons.access_time_rounded, nextClass.time),
                  _infoChip(Icons.room_rounded, nextClass.room),
                  _infoChip(Icons.timer_rounded, '${nextClass.durationMinutes}min'),
                ],
              ),
            ] else
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: NBColors.green,
                    child: Text(
                      'No more classes today! 🎉',
                      style: NBText.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: NBColors.black, size: 14),
        const SizedBox(width: 4),
        Text(text, style: NBText.bodySmall),
      ],
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      (Icons.calendar_month_rounded, 'Timetable',  NBColors.blue,   1),
      (Icons.fact_check_rounded,     'Attendance', NBColors.green,  2),
      (Icons.psychology_rounded,     'Focus',      NBColors.purple, 3),
      (Icons.smart_toy_rounded,      'Ask AI',     NBColors.pink,   4),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 8),
          Row(
            children: actions.map((a) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: a.$4 < 4 ? 8 : 0,
                  ),
                  child: _actionButton(
                    icon:  a.$1,
                    label: a.$2,
                    color: a.$3,
                    onTap: () => widget.onNavigate?.call(a.$4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NBCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: NBSpacing.md),
      fillColor: color,
      shadows: NBShadows.small,
      child: Column(
        children: [
          Icon(icon, color: NBColors.black, size: 26),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: NBText.label.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Bunk summary ──────────────────────────────────────────────────

  Widget _buildBunkSummary(AppState state) {
    final safeBunks       = state.attendance.totalSafeBunks;
    final classesToRecover = state.attendance.classesToRecover;
    final overallPct      = state.attendance.overallPercentage;
    final statusColor     = NBColors.statusColor(overallPct);
    final isGood          = overallPct >= 75;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: NBCard(
        fillColor: isGood ? NBColors.green : NBColors.danger,
        shadows: NBShadows.large,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_rounded, color: NBColors.black, size: 20),
                const SizedBox(width: 8),
                Text(
                  'BUNK CALCULATOR',
                  style: NBText.label.copyWith(letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: NBSpacing.md),
            if (isGood) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$safeBunks',
                    style: NBText.mono.copyWith(fontSize: 48),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'classes you can safely\nbunk without dropping below 75%',
                        style: NBText.bodySmall,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$classesToRecover',
                    style: NBText.mono.copyWith(
                      fontSize: 48,
                      color: NBColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'consecutive classes needed\nto reach 75% attendance',
                        style: NBText.bodySmall.copyWith(color: NBColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
