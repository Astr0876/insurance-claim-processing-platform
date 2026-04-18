import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_button.dart';

class LaTeXPreviewScreen extends StatefulWidget {
  const LaTeXPreviewScreen({super.key});

  @override
  State<LaTeXPreviewScreen> createState() => _LaTeXPreviewScreenState();
}

class _LaTeXPreviewScreenState extends State<LaTeXPreviewScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final latex = appState.latex;
    final report = latex.currentReport;

    return Column(
      children: [
        // ── Info Bar ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: NBColors.white,
            border: Border(
              bottom: BorderSide(color: NBColors.black, width: 2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, size: 16),
              const SizedBox(width: 8),
              Text(
                'DOCUMENT SYNC',
                style: NBText.label.copyWith(fontSize: 10),
              ),
              const Spacer(),
              if (latex.isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: NBColors.black),
                )
              else
                GestureDetector(
                  onTap: () => latex.syncWithOverleaf(),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded, size: 16),
                      const SizedBox(width: 4),
                      Text('SYNC', style: NBText.label.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // PDF Info
        if (report != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: NBCard(
              padding: const EdgeInsets.all(12),
              fillColor: NBColors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.name,
                          style: NBText.heading3.copyWith(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Last compiled: ${_formatTime(report.lastUpdated)}',
                          style: NBText.bodySmall.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: NBColors.green,
                      border: Border.all(color: NBColors.black, width: 1.5),
                      borderRadius: NBRadius.softAll,
                    ),
                    child: Text(
                      report.status.toUpperCase(),
                      style: NBText.label.copyWith(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // PDF Viewer
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: NBColors.black, width: 3),
              borderRadius: NBRadius.softAll,
              boxShadow: NBShadows.large,
            ),
            child: ClipRRect(
              borderRadius: NBRadius.softAll,
              child: report != null
                  ? SfPdfViewer.network(
                      'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
                      key: _pdfViewerKey,
                    )
                  : const Center(
                      child: Text('No report data available'),
                    ),
            ),
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: NBButton(
            label: 'Open in Overleaf',
            fullWidth: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Redirecting to Overleaf...')),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
