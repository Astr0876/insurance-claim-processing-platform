// ─────────────────────────────────────────────────────────────────
//  lib/features/calendar/calendar_heatmap_screen.dart
//  Gmail & Calendar Heatmap — Real calendar layout + event list
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

class _CalendarHeatmapScreenState extends State<CalendarHeatmapScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final calendar = state.calendar;
        final stressColor = state.stressColor;
        final heatmap = calendar.deadlineHeatmap;

        // Events for selected day
        final dayEvents = _selectedDay != null ? calendar.eventsForDay(_selectedDay!) : <CalendarEvent>[];
        final dayDeadlines = _selectedDay != null ? calendar.deadlinesForDay(_selectedDay!) : <AcademicDeadline>[];

        return Scaffold(
          backgroundColor: NBColors.bg,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('STRESS HEATMAP', style: NBText.heading3),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: calendar.isSyncing ? null : () => calendar.syncGmail(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: calendar.isSyncing ? NBColors.orange : NBColors.green,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          calendar.isSyncing ? Icons.sync : Icons.cloud_sync_rounded,
                          size: 14,
                          color: NBColors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          calendar.isSyncing ? 'SYNCING' : 'SYNC',
                          style: NBText.label.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Stress Summary Strip ───────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: _stressStateBg(calendar.stressState),
                  child: Row(
                    children: [
                      AnimatedPercentageRing(
                        percentage: state.stressLevel,
                        size: 56,
                        color: stressColor,
                        strokeWidth: 6,
                        child: Text(
                          '${state.stressLevel.round()}',
                          style: NBText.mono.copyWith(fontSize: 16, color: stressColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(state.stressLabel, style: NBText.heading3.copyWith(color: stressColor)),
                            const SizedBox(height: 2),
                            Text(
                              '${calendar.deadlines.length} deadlines • ${calendar.calendarEvents.length} events',
                              style: NBText.bodySmall.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (calendar.emailsScanned > 0)
                        Column(
                          children: [
                            Text('${calendar.emailsScanned}', style: NBText.mono.copyWith(fontSize: 18)),
                            Text('EMAILS', style: NBText.label.copyWith(fontSize: 7)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // ── Calendar ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: NBCard(
                    fillColor: NBColors.white,
                    shadows: NBShadows.medium,
                    child: Column(
                      children: [
                        _buildCalendarHeader(),
                        const SizedBox(height: 12),
                        _buildDayHeaders(),
                        const SizedBox(height: 4),
                        _buildCalendarGrid(heatmap),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Legend ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendItem(NBColors.green.withValues(alpha: 0.3), 'Clear'),
                      const SizedBox(width: 12),
                      _legendItem(NBColors.primary, '1–2 items'),
                      const SizedBox(width: 12),
                      _legendItem(NBColors.orange, '3 items'),
                      const SizedBox(width: 12),
                      _legendItem(NBColors.danger, '4+ items'),
                    ],
                  ),
                ),
              ),

              // ── Selected Day Detail ────────────────────────────
              if (_selectedDay != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: NBColors.black,
                        borderRadius: NBRadius.softAll,
                      ),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM').format(_selectedDay!).toUpperCase(),
                            style: NBText.label.copyWith(color: NBColors.white, letterSpacing: 1.5),
                          ),
                          const Spacer(),
                          Text(
                            '${dayEvents.length + dayDeadlines.length} items',
                            style: NBText.bodySmall.copyWith(color: NBColors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (dayEvents.isEmpty && dayDeadlines.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: NBCard(
                        fillColor: NBColors.green,
                        child: Row(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Text('Nothing scheduled!', style: NBText.body.copyWith(fontWeight: FontWeight.w700)),
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
                          if (i < dayEvents.length) {
                            return _buildEventCard(dayEvents[i]);
                          } else {
                            return _buildDeadlineCard(dayDeadlines[i - dayEvents.length]);
                          }
                        },
                        childCount: dayEvents.length + dayDeadlines.length,
                      ),
                    ),
                  ),
              ],

              // ── Gmail Scan Section ─────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: NBCard(
                    fillColor: NBColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: NBColors.danger,
                                border: Border.all(color: NBColors.black, width: 2),
                                borderRadius: NBRadius.softAll,
                              ),
                              child: const Icon(Icons.email_rounded, color: NBColors.white, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'GMAIL DEADLINE SCANNER',
                                style: NBText.label.copyWith(letterSpacing: 1.5),
                              ),
                            ),
                            if (calendar.syncError != null)
                              const Icon(Icons.warning_amber_rounded, color: NBColors.orange, size: 18),
                          ],
                        ),
                        const SizedBox(height: 10),
                        NBButton(
                          label: calendar.isSyncing ? '⏳ SCANNING...' : '📧 SYNC GMAIL + CALENDAR',
                          fullWidth: true,
                          fillColor: calendar.isSyncing ? NBColors.black : NBColors.primary,
                          labelColor: calendar.isSyncing ? NBColors.white : NBColors.black,
                          onTap: calendar.isSyncing ? null : () => calendar.syncGmail(),
                        ),
                        if (calendar.syncError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Note: ${calendar.syncError!.contains("ApiRequestError") ? "Some API permissions needed. Demo data loaded." : calendar.syncError!}',
                            style: NBText.bodySmall.copyWith(fontSize: 9, color: NBColors.orange),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _syncStat(Icons.email_outlined, '${calendar.emailsScanned}', 'Emails'),
                            const SizedBox(width: 12),
                            _syncStat(Icons.event, '${calendar.eventsFound}', 'Events'),
                            const SizedBox(width: 12),
                            _syncStat(Icons.warning_amber_rounded, '${calendar.deadlines.length}', 'Deadlines'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Upcoming Deadlines ─────────────────────────────
              if (calendar.deadlines.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Container(width: 4, height: 18, color: NBColors.danger, margin: const EdgeInsets.only(right: 8)),
                        Text('UPCOMING DEADLINES', style: NBText.label.copyWith(letterSpacing: 2)),
                        const Spacer(),
                        NBBadge(label: '${calendar.deadlines.length}', fillColor: NBColors.danger, textColor: NBColors.white),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildDeadlineCard(calendar.deadlines[i]),
                      childCount: calendar.deadlines.length,
                    ),
                  ),
                ),
              ],

              // ── Upcoming Events ────────────────────────────────
              if (calendar.calendarEvents.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Container(width: 4, height: 18, color: NBColors.blue, margin: const EdgeInsets.only(right: 8)),
                        Text('CALENDAR EVENTS', style: NBText.label.copyWith(letterSpacing: 2)),
                        const Spacer(),
                        NBBadge(label: '${calendar.calendarEvents.length}', fillColor: NBColors.blue),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _buildEventCard(calendar.calendarEvents[i]),
                      childCount: calendar.calendarEvents.length,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  // ── Calendar Header (month nav) ─────────────────────────────────
  Widget _buildCalendarHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
          }),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 18),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedMonth).toUpperCase(),
              style: NBText.heading3.copyWith(letterSpacing: 2),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
          }),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: const Icon(Icons.chevron_right_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  // ── Day headers (Mon Tue Wed...) ────────────────────────────────
  Widget _buildDayHeaders() {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: days.map((d) => Expanded(
        child: Center(
          child: Text(d, style: NBText.label.copyWith(fontSize: 9, color: const Color(0xFF888888))),
        ),
      )).toList(),
    );
  }

  // ── Calendar Grid ───────────────────────────────────────────────
  Widget _buildCalendarGrid(Map<DateTime, double> heatmap) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 1, so offset is (weekday - 1)
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;

              if (dayNum < 1 || dayNum > daysInMonth) {
                return Expanded(child: SizedBox(height: 42));
              }

              final date = DateTime(year, month, dayNum);
              final dateOnly = DateTime(date.year, date.month, date.day);
              final intensity = heatmap[dateOnly] ?? 0.0;
              final isToday = dateOnly.year == today.year && dateOnly.month == today.month && dateOnly.day == today.day;
              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == date.year &&
                  _selectedDay!.month == date.month &&
                  _selectedDay!.day == date.day;
              final isPast = date.isBefore(DateTime(today.year, today.month, today.day));

              Color cellColor;
              if (intensity >= 0.7) {
                cellColor = NBColors.danger;
              } else if (intensity >= 0.4) {
                cellColor = NBColors.orange;
              } else if (intensity > 0) {
                cellColor = NBColors.primary;
              } else {
                cellColor = isPast
                    ? const Color(0xFFF0F0F0)
                    : NBColors.green.withValues(alpha: 0.2);
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 42,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected ? NBColors.black : cellColor,
                      border: Border.all(
                        color: isToday ? NBColors.primary : (isSelected ? NBColors.black : NBColors.black.withValues(alpha: 0.15)),
                        width: isToday ? 3 : 1,
                      ),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: NBText.label.copyWith(
                            fontSize: 12,
                            color: isSelected ? NBColors.white : (isPast ? const Color(0xFF999999) : NBColors.black),
                          ),
                        ),
                        if (intensity > 0)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? NBColors.primary : NBColors.black,
                              shape: BoxShape.circle,
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
      }),
    );
  }

  // ── Event Card ──────────────────────────────────────────────────
  Widget _buildEventCard(CalendarEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NBCard(
        fillColor: NBColors.blue,
        shadows: NBShadows.small,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: NBColors.black,
                borderRadius: NBRadius.softAll,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: NBText.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: NBColors.black),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('hh:mm a, dd MMM').format(event.start),
                        style: NBText.monoSmall.copyWith(fontSize: 10),
                      ),
                      if (event.location != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 11, color: NBColors.black),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            event.location!,
                            style: NBText.bodySmall.copyWith(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            NBBadge(
              label: event.source == 'Google Calendar' ? 'GCAL' : event.source.toUpperCase(),
              fillColor: NBColors.white,
              fontSize: 7,
            ),
          ],
        ),
      ),
    );
  }

  // ── Deadline Card ───────────────────────────────────────────────
  Widget _buildDeadlineCard(AcademicDeadline deadline) {
    final daysLeft = deadline.date.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: NBCard(
        fillColor: isUrgent ? NBColors.danger : NBColors.white,
        shadows: NBShadows.small,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUrgent ? NBColors.white : NBColors.primary,
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('dd').format(deadline.date), style: NBText.mono.copyWith(fontSize: 14)),
                  Text(DateFormat('MMM').format(deadline.date).toUpperCase(), style: NBText.label.copyWith(fontSize: 7)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deadline.title,
                    style: NBText.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isUrgent ? NBColors.white : NBColors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      NBBadge(label: deadline.keyword.toUpperCase(), fillColor: NBColors.purple, fontSize: 7),
                      const SizedBox(width: 6),
                      NBBadge(
                        label: deadline.source.toUpperCase(),
                        fillColor: isUrgent ? NBColors.white : NBColors.black,
                        textColor: isUrgent ? NBColors.black : NBColors.white,
                        fontSize: 7,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  daysLeft <= 0 ? 'NOW' : '${daysLeft}d',
                  style: NBText.mono.copyWith(
                    fontSize: 18,
                    color: isUrgent ? NBColors.white : NBColors.black,
                  ),
                ),
                Text('LEFT', style: NBText.label.copyWith(fontSize: 7, color: isUrgent ? NBColors.white : const Color(0xFF888888))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _syncStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: NBColors.bg,
          border: Border.all(color: NBColors.black.withValues(alpha: 0.1)),
          borderRadius: NBRadius.softAll,
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: NBColors.black),
            Text(value, style: NBText.mono.copyWith(fontSize: 14)),
            Text(label.toUpperCase(), style: NBText.label.copyWith(fontSize: 7)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NBColors.black.withValues(alpha: 0.3), width: 1),
            borderRadius: NBRadius.softAll,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: NBText.label.copyWith(fontSize: 8)),
      ],
    );
  }

  Color _stressStateBg(StressState state) {
    switch (state) {
      case StressState.red: return const Color(0xFFFFEAEA);
      case StressState.yellow: return const Color(0xFFFFF8E1);
      case StressState.green: return const Color(0xFFE8F5E9);
    }
  }
}
