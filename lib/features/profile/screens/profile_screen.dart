import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../../../core/services/ai_model_service.dart';
import '../../auth/screens/auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        title: const Text('PROFILE'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user, state),
            const SizedBox(height: 32),
            Text('AI MODELS & SETTINGS', style: NBText.heading3),
            const SizedBox(height: 16),
            _buildModelSettings(context, state),
            const SizedBox(height: 32),
            _buildAccountActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NBColors.white,
        border: Border.all(color: NBColors.black, width: 2),
        borderRadius: NBRadius.softAll,
        boxShadow: NBShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NBColors.primary,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: const Icon(Icons.person_rounded, size: 40, color: NBColors.black),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(state.studentName.toUpperCase(), style: NBText.heading2),
                Text(user?.email ?? '', style: NBText.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSettings(BuildContext context, AppState state) {
    return Column(
      children: AIModelType.values.map((type) {
        final status = state.aiModels.modelStatuses[type]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NBColors.white,
            border: Border.all(color: NBColors.black, width: 2),
            borderRadius: NBRadius.softAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.label.toUpperCase(), style: NBText.label),
                        const SizedBox(height: 4),
                        Text(type.description, style: NBText.bodySmall.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  if (status.isDownloaded)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!status.isLoaded)
                          IconButton(
                            icon: const Icon(Icons.play_circle_outline_rounded, color: NBColors.primary),
                            onPressed: () => state.aiModels.loadModel(type),
                            tooltip: 'Load into memory',
                          ),
                        const Icon(Icons.check_circle_rounded, color: NBColors.safe),
                      ],
                    )
                  else if (status.isDownloading)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: status.progress,
                        strokeWidth: 3,
                        color: NBColors.primary,
                        backgroundColor: NBColors.bg,
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => state.aiModels.downloadModel(type),
                    ),
                ],
              ),
              if (status.isDownloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: status.progress,
                  backgroundColor: NBColors.bg,
                  color: NBColors.primary,
                  minHeight: 8,
                ),
                const SizedBox(height: 4),
                Text(
                  'Downloading... ${(status.progress * 100).toInt()}%',
                  style: NBText.bodySmall.copyWith(fontSize: 10),
                ),
              ],
              if (status.isDownloaded) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => state.aiModels.deleteModel(type),
                  child: Text(
                    'DELETE MODEL',
                    style: NBText.bodySmall.copyWith(
                      color: NBColors.danger,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: NBColors.danger,
              foregroundColor: NBColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: NBColors.black, width: 2),
              shape: RoundedRectangleBorder(borderRadius: NBRadius.softAll),
              elevation: 4,
            ),
            child: Text('LOGOUT', style: NBText.label.copyWith(color: NBColors.white)),
          ),
        ),
      ],
    );
  }
}
