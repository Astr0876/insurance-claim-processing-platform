import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_badge.dart';
import '../../core/widgets/nb_button.dart';
import '../shared/widgets.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final records         = state.attendance.records;
        final overallPct      = state.attendance.overallPercentage;
        final safeBunks       = state.attendance.totalSafeBunks;
        final classesToRecover = state.attendance.classesToRecover;
        final statusColor     = NBColors.statusColor(overallPct);

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
                        'ATTENDANCE',
                        style: NBText.label.copyWith(
                          color: const Color(0xFF777777),
                          letterSpacing: 2,
                        ),
                      ),
                      Text('Track & Optimize', style: NBText.heading1),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: NBColors.primary,
                          border: Border.all(color: NBColors.black, width: 1.5),
                          borderRadius: NBRadius.softAll,
                        ),
                        child: Text(
                          'your attendance record',
                          style: NBText.label.copyWith(
                            color: NBColors.black,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Overall stats ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: NBCard(
                    fillColor: statusColor,
                    shadows: NBShadows.large,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Ring
                            AnimatedPercentageRing(
                              percentage: overallPct,
                              size: 100,
                              color: NBColors.black,
                              strokeWidth: 8,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${overallPct.toStringAsFixed(1)}%',
                                    style: NBText.monoSmall.copyWith(
                                      fontSize: 16,
                                      color: NBColors.black,
                                    ),
                                  ),
                                  Text(
                                    'OVERALL',
                                    style: NBText.label.copyWith(fontSize: 8),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: NBSpacing.xl),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (overallPct >= 75) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.celebration_rounded,
                                            color: NBColors.black, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Bunk $safeBunks class${safeBunks == 1 ? '' : 'es'}!',
                                            style: NBText.heading3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.warning_rounded,
                                            color: NBColors.black, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Attend $classesToRecover more!',
                                            style: NBText.heading3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    '${records.values.fold<int>(0, (s, r) => s + r.attended)} / '
                                    '${records.values.fold<int>(0, (s, r) => s + r.total)} classes',
                                    style: NBText.body,
                                  ),
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

              // ── Section header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: const SectionHeader(title: 'Subject Breakdown'),
                ),
              ),

              // ── Subject cards ─────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry  = records.entries.elementAt(index);
                    final record = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      child: _buildSubjectCard(record, state),
                    );
                  },
                  childCount: records.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  // ── Subject card ─────────────────────────────────────────────────

  Widget _buildSubjectCard(dynamic record, AppState state) {
    final pct           = record.percentage as double;
    final subject       = record.subject as String;
    final attended      = record.attended as int;
    final total         = record.total as int;
    final safeBunks     = record.safeBunks() as int;
    final classesNeeded = record.classesToReachTarget() as int;
    final statusColor   = NBColors.statusColor(pct);

    return NBCard(
      shadows: NBShadows.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ─────────────────────────────────────────────
          Row(
            children: [
              // Accent bar
              Container(
                width: 5,
                height: 44,
                color: statusColor,
                margin: const EdgeInsets.only(right: NBSpacing.md),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: NBText.heading3),
                    const SizedBox(height: 2),
                    Text(
                      '$attended / $total classes',
                      style: NBText.bodySmall.copyWith(
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              // Percentage badge
              NBBadge(
                label: '${pct.toStringAsFixed(1)}%',
                fillColor: statusColor,
                textColor: NBColors.white,
                fontSize: 12,
              ),
            ],
          ),
          const SizedBox(height: NBSpacing.md),

          // ── Raw progress bar ────────────────────────────────────
          Container(
            height: 6,
            width: double.infinity,
            color: statusColor.withValues(alpha: 0.12),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  widthFactor: value,
                  alignment: Alignment.centerLeft,
                  child: Container(color: statusColor),
                );
              },
            ),
          ),
          const SizedBox(height: NBSpacing.md),

          // ── Actions row ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  pct >= 75
                      ? '✅ Safe — can bunk $safeBunks more'
                      : '⚠️ Need $classesNeeded more classes',
                  style: NBText.bodySmall.copyWith(
                    color: pct >= 75 ? NBColors.green : NBColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionChip('Present', NBColors.green, () => state.markAttended(subject)),
                  const SizedBox(width: 6),
                  _actionChip('Absent', NBColors.danger, () => state.markAbsent(subject)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: NBColors.black, width: 2),
          borderRadius: NBRadius.softAll,
          boxShadow: NBShadows.small,
        ),
        child: Text(
          label.toUpperCase(),
          style: NBText.label.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
