// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/screens/hub_room_screen.dart
//  Main room screen: header + 4 tabs (Chat, Canvas, Files, Activity)
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../services/hub_service.dart';
import '../models/hub_models.dart';
import 'tabs/chat_tab.dart';
import 'tabs/canvas_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/polls_tab.dart';

class HubRoomScreen extends StatefulWidget {
  const HubRoomScreen({super.key});

  @override
  State<HubRoomScreen> createState() => _HubRoomScreenState();
}

class _HubRoomScreenState extends State<HubRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _tabLabels = ['Chat', 'Canvas', 'Polls', 'Activity'];
  static const _tabIcons  = [
    Icons.chat_bubble_outline_rounded,
    Icons.draw_outlined,
    Icons.poll_outlined,
    Icons.timeline_rounded,
  ];
  static const _tabColors = [
    NBColors.primary,
    NBColors.blue,
    NBColors.pink,
    NBColors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HubService>(
      builder: (context, svc, _) {
        final room = svc.currentRoom;
        if (room == null) return const SizedBox.shrink();

        return Scaffold(
          backgroundColor: NBColors.bg,
          body: Column(
            children: [
              // ── Room Header ──────────────────────────────────────
              _buildHeader(svc, room.name),

              // ── Study Session Banner ─────────────────────────────
              if (svc.studySession != null)
                _SessionBanner(svc: svc),

              // ── Tab Bar ──────────────────────────────────────────
              _buildTabBar(),

              // ── Tab Views ────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ChatTab(svc: svc),
                    CanvasTab(svc: svc),
                    PollsTab(svc: svc),
                    ActivityTab(svc: svc),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ───────────────────────────────────────────────────────

  Widget _buildHeader(HubService svc, String roomName) {
    final activeCount = svc.presence.where((p) => p.status == 'active').length;
    final room = svc.currentRoom!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      decoration: const BoxDecoration(
        color: NBColors.white,
        border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back
              GestureDetector(
                onTap: () {
                  svc.leaveRoom();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: NBColors.black, width: 2),
                    borderRadius: NBRadius.softAll,
                    boxShadow: NBShadows.small,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: NBColors.black, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roomName, style: NBText.heading3, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Container(width: 8, height: 8, color: NBColors.green, margin: const EdgeInsets.only(right: 4)),
                        Text(
                          '$activeCount active • ${room.members.length} members',
                          style: NBText.label.copyWith(fontSize: 9, color: const Color(0xFF555555)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Session timer button
              GestureDetector(
                onTap: () => svc.studySession != null ? svc.stopSession() : svc.startSession(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: svc.studySession != null ? NBColors.green : NBColors.primary,
                    border: Border.all(color: NBColors.black, width: 2),
                    borderRadius: NBRadius.softAll,
                    boxShadow: NBShadows.small,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        svc.studySession != null ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: NBColors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        svc.studySession != null ? svc.sessionDisplay : 'START',
                        style: NBText.monoSmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Presence avatars row
          if (svc.presence.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ...svc.presence.take(5).map((p) => _presenceAvatar(p)),
                if (svc.presence.length > 5)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Text('+${svc.presence.length - 5}', style: NBText.label.copyWith(fontSize: 9)),
                  ),
                const Spacer(),
                // Room code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: NBColors.black,
                    borderRadius: NBRadius.softAll,
                  ),
                  child: Text(
                    'CODE: ${svc.currentRoom?.code ?? ''}',
                    style: NBText.monoSmall.copyWith(color: NBColors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _presenceAvatar(PresenceInfo p) {
    Color statusColor;
    switch (p.status) {
      case 'active':  statusColor = NBColors.green;  break;
      case 'idle':    statusColor = NBColors.orange; break;
      default:        statusColor = const Color(0xFF999999);
    }
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: NBColors.primary,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: Center(
              child: Text(
                p.userName.substring(0, 1).toUpperCase(),
                style: NBText.label.copyWith(fontSize: 12),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                border: Border.all(color: NBColors.black, width: 1.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: NBColors.bg,
        border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
      ),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = _tabs.index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabs.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: isActive ? _tabColors[i] : Colors.transparent,
                  border: Border(
                    right: i < 3
                        ? const BorderSide(color: NBColors.black, width: 1)
                        : BorderSide.none,
                    bottom: isActive
                        ? const BorderSide(color: NBColors.black, width: 3)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_tabIcons[i], size: 16, color: NBColors.black),
                    const SizedBox(width: 4),
                    Text(
                      _tabLabels[i].toUpperCase(),
                      style: NBText.label.copyWith(fontSize: 10),
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
}

// ─────────────────────────────────────────────────────────────────
//  Session Banner
// ─────────────────────────────────────────────────────────────────

class _SessionBanner extends StatelessWidget {
  final HubService svc;
  const _SessionBanner({required this.svc});

  @override
  Widget build(BuildContext context) {
    final session = svc.studySession!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: NBColors.green,
        border: Border(bottom: BorderSide(color: NBColors.black, width: 2)),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10, color: NBColors.black, margin: const EdgeInsets.only(right: 8)),
          Text(
            '${session.activeUsers.length} ${session.activeUsers.length == 1 ? 'person' : 'people'} studying',
            style: NBText.label.copyWith(fontSize: 11),
          ),
          const Text(' • ', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(svc.sessionDisplay, style: NBText.monoSmall.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
