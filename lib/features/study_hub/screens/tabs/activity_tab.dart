// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/screens/tabs/activity_tab.dart
//  Activity feed — timeline of room events
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/theme/neubrut_tokens.dart';
import '../../../../core/widgets/nb_card.dart';
import '../../../../core/widgets/nb_badge.dart';
import '../../services/hub_service.dart';
import '../../models/hub_models.dart';

class ActivityTab extends StatelessWidget {
  final HubService svc;
  const ActivityTab({super.key, required this.svc});

  static const _actionColors = {
    'member_joined':   NBColors.green,
    'message_sent':    NBColors.blue,
    'doc_edited':      NBColors.purple,
    'poll_created':    NBColors.pink,
    'item_pinned':     NBColors.primary,
    'session_started': NBColors.orange,
    'room_created':    NBColors.black,
  };

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Presence list ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: NBCard(
              fillColor: NBColors.primary,
              shadows: NBShadows.medium,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LIVE PRESENCE', style: NBText.label.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 10),
                  ...svc.presence.map((p) => _PresenceRow(presence: p)),
                  if (svc.presence.isEmpty)
                    Text('No one online yet', style: NBText.bodySmall.copyWith(color: const Color(0xFF666666))),
                ],
              ),
            ),
          ),
        ),

        // ── Activity header ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(width: 4, height: 18, color: NBColors.black, margin: const EdgeInsets.only(right: 8)),
                Text('ACTIVITY FEED', style: NBText.label.copyWith(fontSize: 11, letterSpacing: 2)),
                const Spacer(),
                NBBadge(label: '${svc.activities.length} events'),
              ],
            ),
          ),
        ),

        // ── Activity items ─────────────────────────────────────────
        if (svc.activities.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: NBCard(
                child: Column(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    Text('No activity yet', style: NBText.heading3),
                    Text('Actions in the room will appear here',
                        style: NBText.bodySmall.copyWith(color: const Color(0xFF666666))),
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
                  final item = svc.activities[i];
                  final color = _actionColors[item.action] ?? NBColors.black;
                  final time = _formatTime(item.timestamp);
                  final isLast = i == svc.activities.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline line + dot
                        SizedBox(
                          width: 32,
                          child: Column(
                            children: [
                              Container(
                                width: 14, height: 14,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(color: NBColors.black, width: 2),
                                  borderRadius: NBRadius.softAll,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: NBColors.black.withValues(alpha: 0.15),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                            child: NBCard(
                              padding: const EdgeInsets.all(10),
                              shadows: NBShadows.small,
                              child: Row(
                                children: [
                                  Text(item.icon, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(item.description, style: NBText.bodySmall),
                                  ),
                                  Text(time, style: NBText.monoSmall.copyWith(fontSize: 9, color: const Color(0xFF888888))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: svc.activities.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}

class _PresenceRow extends StatelessWidget {
  final dynamic presence;
  const _PresenceRow({required this.presence});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (presence.status as String) {
      case 'active':
        statusColor = NBColors.green;
        statusLabel = 'ACTIVE';
        break;
      case 'idle':
        statusColor = NBColors.orange;
        statusLabel = 'IDLE';
        break;
      default:
        statusColor = const Color(0xFF999999);
        statusLabel = 'OFFLINE';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: NBColors.white,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: Center(
              child: Text(
                (presence.userName as String).substring(0, 1).toUpperCase(),
                style: NBText.label.copyWith(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(presence.userName as String, style: NBText.body.copyWith(fontWeight: FontWeight.w700)),
          ),
          NBBadge(
            label: statusLabel,
            fillColor: statusColor,
            textColor: NBColors.black,
            fontSize: 9,
          ),
        ],
      ),
    );
  }
}
