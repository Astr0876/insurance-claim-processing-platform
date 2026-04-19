import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_button.dart';

class LetsGoScreen extends StatelessWidget {
  final VoidCallback onStart;

  const LetsGoScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final nextClass = state.timetable.getNextClass();
        final stressLevel = state.stressLabel;
        final stressColor = state.stressColor;
        
        return Scaffold(
          backgroundColor: NBColors.bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'GOOD MORNING,\nRENEE.',
                    style: NBText.heading1.copyWith(fontSize: 48, height: 0.9),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NBColors.primary,
                      border: Border.all(color: NBColors.black, width: 2),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Text(
                      'YOUR PROACTIVE SIDEKICK IS READY',
                      style: NBText.label.copyWith(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  
                  // Pulse Summary
                  NBCard(
                    fillColor: NBColors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _summaryRow(
                          icon: Icons.monitor_heart_rounded,
                          label: 'STRESS LEVEL',
                          value: stressLevel.toUpperCase(),
                          color: stressColor,
                        ),
                        const Divider(height: 32, thickness: 2, color: NBColors.black),
                        _summaryRow(
                          icon: Icons.schedule_rounded,
                          label: 'NEXT CLASS',
                          value: nextClass?.subject.toUpperCase() ?? 'NONE REMAINING',
                          color: NBColors.blue,
                        ),
                        const Divider(height: 32, thickness: 2, color: NBColors.black),
                        _summaryRow(
                          icon: Icons.fact_check_rounded,
                          label: 'BUNK BUDGET',
                          value: '${state.attendance.totalSafeBunks} CLASSES',
                          color: NBColors.green,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // The big "LET'S GO" button
                  Hero(
                    tag: 'lets_go_btn',
                    child: NBButton(
                      label: 'LET\'S GO',
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      fullWidth: true,
                      onTap: onStart,
                      fillColor: NBColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Ready to optimize your academic life?',
                      style: NBText.bodySmall.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: NBColors.black, width: 2),
            borderRadius: NBRadius.softAll,
          ),
          child: Icon(icon, size: 20, color: NBColors.black),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: NBText.label.copyWith(fontSize: 10, color: const Color(0xFF777777))),
              Text(value, style: NBText.heading3.copyWith(fontSize: 18)),
            ],
          ),
        ),
      ],
    );
  }
}
