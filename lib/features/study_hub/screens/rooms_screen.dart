// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/screens/rooms_screen.dart
//  Rooms list + Create / Join dialogs — Neubrutalism UI only
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/widgets/nb_card.dart';
import '../../../core/widgets/nb_badge.dart';
import '../../../core/widgets/nb_button.dart';
import '../../../core/widgets/nb_input.dart';
import '../services/hub_service.dart';
import '../models/hub_models.dart';
import 'hub_room_screen.dart';

class StudyHubRoomsScreen extends StatefulWidget {
  const StudyHubRoomsScreen({super.key});

  @override
  State<StudyHubRoomsScreen> createState() => _StudyHubRoomsScreenState();
}

class _StudyHubRoomsScreenState extends State<StudyHubRoomsScreen> {
  // Accent colours per room (cycled)
  static const _accents = [
    NBColors.primary, NBColors.blue, NBColors.pink,
    NBColors.purple,  NBColors.green, NBColors.orange,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<HubService>();
      svc.connect();
      if (svc.myRooms.isEmpty) svc.loadDemoRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HubService>(
      builder: (context, svc, _) {
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
                        'COLLABORATIVE',
                        style: NBText.label.copyWith(
                          color: const Color(0xFF777777),
                          letterSpacing: 2,
                        ),
                      ),
                      Text('Study Hub', style: NBText.heading1),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          NBBadge(
                            label: '${svc.myRooms.length} Rooms',
                            fillColor: NBColors.black,
                            textColor: NBColors.white,
                          ),
                          const SizedBox(width: 8),
                          NBBadge(
                            label: svc.isConnected ? 'Connected' : 'Demo Mode',
                            fillColor: svc.isConnected ? NBColors.green : NBColors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Create + Join buttons ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: NBButton(
                          label: '+ Create Room',
                          fillColor: NBColors.primary,
                          onTap: () => _showCreateDialog(svc),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NBButton(
                          label: 'Join with Code',
                          fillColor: NBColors.blue,
                          labelColor: NBColors.black,
                          onTap: () => _showJoinDialog(svc),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Rooms list ───────────────────────────────────────
              if (svc.myRooms.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: NBCard(
                      child: Column(
                        children: [
                          const Text('📚', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No study rooms yet',
                              style: NBText.heading3),
                          const SizedBox(height: 4),
                          Text('Create or join one to get started',
                              style: NBText.body.copyWith(color: const Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final room   = svc.myRooms[i];
                        final accent = _accents[i % _accents.length];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RoomCard(
                            room: room,
                            accent: accent,
                            onTap: () {
                              svc.enterRoom(room);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HubRoomScreen()),
                              );
                            },
                          ),
                        );
                      },
                      childCount: svc.myRooms.length,
                    ),
                  ),
                ),

              // ── Tips card ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: NBCard(
                    fillColor: NBColors.purple,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HOW IT WORKS', style: NBText.label.copyWith(letterSpacing: 2)),
                        const SizedBox(height: 12),
                        ...[
                          ('💬', 'Real-time chat with typing indicators'),
                          ('📝', 'Shared collaborative document'),
                          ('🗳️', 'Quick polls & doubt voting'),
                          ('📌', 'Pin important notes & files'),
                          ('⏱️', 'Study session timer synced live'),
                        ].map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
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

  // ── Create room dialog ────────────────────────────────────────────

  void _showCreateDialog(HubService svc) {
    final nameCtrl = TextEditingController();
    final nameCtrl2 = TextEditingController(text: svc.userName);

    showModalBottomSheet(
      context: context,
      backgroundColor: NBColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: NBColors.black, width: 2),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, color: NBColors.black, margin: const EdgeInsets.only(bottom: 16))),
              Text('CREATE STUDY ROOM', style: NBText.heading2),
              const SizedBox(height: 20),
              NBInput(controller: nameCtrl2, label: 'Your Name', hintText: 'Enter your display name'),
              const SizedBox(height: 12),
              NBInput(controller: nameCtrl, label: 'Room Name', hintText: 'e.g. DS Exam Prep'),
              const SizedBox(height: 20),
              NBButton(
                label: 'Create Room',
                fullWidth: true,
                onTap: () async {
                  if (nameCtrl.text.isEmpty) return;
                  svc.setIdentity(svc.userId, nameCtrl2.text.isNotEmpty ? nameCtrl2.text : svc.userName);
                  Navigator.pop(ctx);
                  final room = await svc.createRoom(nameCtrl.text);
                  if (room != null && mounted) {
                    svc.enterRoom(room);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HubRoomScreen()));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Join room dialog ──────────────────────────────────────────────

  void _showJoinDialog(HubService svc) {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: svc.userName);

    showModalBottomSheet(
      context: context,
      backgroundColor: NBColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: NBColors.black, width: 2),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, color: NBColors.black, margin: const EdgeInsets.only(bottom: 16))),
              Text('JOIN A ROOM', style: NBText.heading2),
              const SizedBox(height: 20),
              NBInput(controller: nameCtrl, label: 'Your Name', hintText: 'Enter your display name'),
              const SizedBox(height: 12),
              NBInput(controller: codeCtrl, label: 'Room Code', hintText: 'e.g. ABC123'),
              const SizedBox(height: 20),
              NBButton(
                label: 'Join Room',
                fillColor: NBColors.blue,
                labelColor: NBColors.black,
                fullWidth: true,
                onTap: () async {
                  if (codeCtrl.text.isEmpty) return;
                  svc.setIdentity(svc.userId, nameCtrl.text.isNotEmpty ? nameCtrl.text : svc.userName);
                  Navigator.pop(ctx);
                  final room = await svc.joinRoom(codeCtrl.text);
                  if (room != null && mounted) {
                    svc.enterRoom(room);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HubRoomScreen()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room not found. Check the code.')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Room Card
// ─────────────────────────────────────────────────────────────────

class _RoomCard extends StatelessWidget {
  final StudyRoom room;
  final Color accent;
  final VoidCallback onTap;

  const _RoomCard({required this.room, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NBCard(
      onTap: onTap,
      fillColor: accent,
      shadows: NBShadows.medium,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: NBText.heading3),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people_rounded, size: 14, color: NBColors.black),
                    const SizedBox(width: 4),
                    Text(
                      '${room.members.length} member${room.members.length == 1 ? '' : 's'}',
                      style: NBText.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 12, color: NBColors.black),
                    const SizedBox(width: 4),
                    Text('Code: ${room.code}', style: NBText.monoSmall.copyWith(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NBColors.black,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: NBColors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
