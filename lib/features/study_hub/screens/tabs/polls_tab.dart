// ─────────────────────────────────────────────────────────────────
//  lib/features/study_hub/screens/tabs/polls_tab.dart
//  Polls + Doubt Voting + Room Insights tab
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../../core/theme/neubrut_tokens.dart';
import '../../../../core/widgets/nb_card.dart';
import '../../../../core/widgets/nb_badge.dart';
import '../../../../core/widgets/nb_button.dart';
import '../../services/hub_service.dart';
import '../../models/hub_models.dart';

class PollsTab extends StatefulWidget {
  final HubService svc;
  const PollsTab({super.key, required this.svc});

  @override
  State<PollsTab> createState() => _PollsTabState();
}

class _PollsTabState extends State<PollsTab> {
  final _pollCtrl = TextEditingController();

  @override
  void dispose() {
    _pollCtrl.dispose();
    super.dispose();
  }

  void _createPoll() {
    final q = _pollCtrl.text.trim();
    if (q.isEmpty) return;
    widget.svc.createPoll(q);
    _pollCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.svc;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Room Insights ──────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildInsights(svc),
        ),

        // ── Create poll ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: NBCard(
              fillColor: NBColors.pink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ASK A QUESTION', style: NBText.label.copyWith(letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: NBColors.white,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: TextField(
                      controller: _pollCtrl,
                      style: NBText.body,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Should we revise Unit 4?',
                        hintStyle: TextStyle(color: Color(0xFF888888), fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onSubmitted: (_) => _createPoll(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  NBButton(
                    label: '🗳️ Post Poll',
                    fullWidth: true,
                    onTap: _createPoll,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Polls list ─────────────────────────────────────────────
        if (svc.polls.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: NBCard(
                child: Column(
                  children: [
                    const Text('🗳️', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text('No polls yet', style: NBText.heading3),
                    Text('Ask a question to get everyone voting!',
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
                  final poll = svc.polls.reversed.toList()[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PollCard(
                      poll: poll,
                      myId: svc.userId,
                      onVote: (v) => svc.votePoll(poll.id, v),
                    ),
                  );
                },
                childCount: svc.polls.length,
              ),
            ),
          ),

        // ── Pinned items ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(width: 4, height: 18, color: NBColors.primary, margin: const EdgeInsets.only(right: 8)),
                Text('PINNED ITEMS'.toUpperCase(), style: NBText.label.copyWith(fontSize: 11, letterSpacing: 2)),
              ],
            ),
          ),
        ),

        if (svc.pinnedItems.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: NBCard(
                child: Text('Nothing pinned yet. Long-press a message to pin it.',
                    style: NBText.bodySmall.copyWith(color: const Color(0xFF666666))),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final pin = svc.pinnedItems[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: NBCard(
                      fillColor: NBColors.primary,
                      shadows: NBShadows.small,
                      child: Row(
                        children: [
                          const Text('📌', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pin.label, style: NBText.label.copyWith(fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(pin.content, style: NBText.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: svc.pinnedItems.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildInsights(HubService svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: NBCard(
        fillColor: NBColors.purple,
        shadows: NBShadows.medium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ROOM INSIGHTS', style: NBText.label.copyWith(letterSpacing: 2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statBlock('Most Active', svc.mostActiveUser, NBColors.primary)),
                Container(width: 2, height: 40, color: NBColors.black, margin: const EdgeInsets.symmetric(horizontal: 12)),
                Expanded(child: _statBlock('Messages', '${svc.totalMessages}', NBColors.blue)),
                Container(width: 2, height: 40, color: NBColors.black, margin: const EdgeInsets.symmetric(horizontal: 12)),
                Expanded(child: _statBlock('Online', '${svc.presence.where((p) => p.status == 'active').length}', NBColors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(String label, String value, Color accent) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: accent,
          child: Text(
            value.length > 8 ? '${value.substring(0, 8)}…' : value,
            style: NBText.monoSmall.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(label.toUpperCase(), style: NBText.label.copyWith(fontSize: 8)),
      ],
    );
  }
}

// ── Poll card ─────────────────────────────────────────────────────

class _PollCard extends StatelessWidget {
  final HubPoll poll;
  final String myId;
  final Function(String) onVote;

  const _PollCard({required this.poll, required this.myId, required this.onVote});

  @override
  Widget build(BuildContext context) {
    final hasVoted = poll.hasVoted(myId);
    final total = poll.totalVotes == 0 ? 1 : poll.totalVotes;
    final yesPct = poll.yes.length / total;
    final noPct  = poll.no.length / total;

    return NBCard(
      shadows: NBShadows.medium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🗳️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Text(poll.question, style: NBText.body.copyWith(fontWeight: FontWeight.w700))),
              NBBadge(label: '${poll.totalVotes} votes'),
            ],
          ),
          const SizedBox(height: 12),

          // Yes bar
          _VoteBar(label: 'Yes', count: poll.yes.length, pct: yesPct, color: NBColors.green),
          const SizedBox(height: 6),
          _VoteBar(label: 'No', count: poll.no.length, pct: noPct, color: NBColors.danger),
          const SizedBox(height: 12),

          if (!hasVoted)
            Row(
              children: [
                Expanded(
                  child: NBButton(
                    label: '👍  Yes',
                    fillColor: NBColors.green,
                    onTap: () => onVote('yes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NBButton(
                    label: '👎  No',
                    fillColor: NBColors.danger,
                    labelColor: NBColors.white,
                    onTap: () => onVote('no'),
                  ),
                ),
              ],
            )
          else
            Center(
              child: NBBadge(
                label: poll.yes.contains(myId) ? '✓ You voted Yes' : '✓ You voted No',
                fillColor: poll.yes.contains(myId) ? NBColors.green : NBColors.danger,
                textColor: NBColors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;

  const _VoteBar({required this.label, required this.count, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 28, child: Text(label, style: NBText.label.copyWith(fontSize: 10))),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(height: 14, color: color.withValues(alpha: 0.15)),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(height: 14, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 20, child: Text('$count', style: NBText.monoSmall.copyWith(fontSize: 11))),
      ],
    );
  }
}
