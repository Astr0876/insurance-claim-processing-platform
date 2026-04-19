import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/neubrut_tokens.dart';
import '../../core/widgets/nb_card.dart';
import '../../core/widgets/nb_button.dart';
import '../../core/services/latex_service.dart';

class LaTeXPreviewScreen extends StatefulWidget {
  const LaTeXPreviewScreen({super.key});

  @override
  State<LaTeXPreviewScreen> createState() => _LaTeXPreviewScreenState();
}

class _LaTeXPreviewScreenState extends State<LaTeXPreviewScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final TextEditingController _editorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final latex = Provider.of<AppState>(context, listen: false).latex;
      if (latex.currentReport != null) {
        _editorController.text = latex.currentReport!.rawContent;
      }
    });
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final latex = appState.latex;
    final report = latex.currentReport;

    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.description_rounded, size: 20),
            const SizedBox(width: 8),
            Text('LATEX WORKSPACE', style: NBText.heading3),
          ],
        ),
      ),
      body: DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // ── Tab Bar ───────────────────────────────────────────────
          Container(
            color: NBColors.white,
            child: TabBar(
              labelColor: NBColors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: NBColors.primary,
              indicatorWeight: 4,
              labelStyle: NBText.label.copyWith(fontSize: 12),
              tabs: const [
                Tab(text: 'EDITOR'),
                Tab(text: 'PREVIEW'),
              ],
            ),
          ),
          
          Expanded(
            child: TabBarView(
              children: [
                // ── Editor Tab ──────────────────────────────────────
                _buildEditor(latex),
                
                // ── Preview Tab ─────────────────────────────────────
                _buildPreview(latex, report),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEditor(LaTeXService latex) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: NBColors.white,
              border: Border.all(color: NBColors.black, width: 2),
              borderRadius: NBRadius.softAll,
            ),
            child: TextField(
              controller: _editorController,
              maxLines: null,
              expands: true,
              style: NBText.monoSmall.copyWith(fontSize: 13, height: 1.5),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: 'Type your LaTeX here...',
              ),
              onChanged: (val) => latex.updateContent(val),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showAiAssistDialog(latex),
            backgroundColor: NBColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: NBRadius.softAll,
              side: const BorderSide(color: NBColors.black, width: 2),
            ),
            label: Row(
              children: [
                if (latex.isGenerating)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: NBColors.black),
                  )
                else
                  const Icon(Icons.auto_awesome_rounded, color: NBColors.black, size: 20),
                const SizedBox(width: 8),
                Text('AI ASSIST', style: NBText.label.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(LaTeXService latex, LaTeXReport? report) {
    return Column(
      children: [
        // Info Bar
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
                'REMOTE COMPILE',
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
            padding: const EdgeInsets.all(16),
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
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              border: Border.all(color: NBColors.black, width: 3),
              borderRadius: NBRadius.softAll,
              boxShadow: NBShadows.large,
            ),
            child: ClipRRect(
              borderRadius: NBRadius.softAll,
              child: report != null
                  ? (report.previewUrl.startsWith('assets/')
                      ? SfPdfViewer.asset(
                          report.previewUrl,
                          key: _pdfViewerKey,
                        )
                      : SfPdfViewer.network(
                          report.previewUrl,
                          key: _pdfViewerKey,
                        ))
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
            label: 'Export to Overleaf',
            fullWidth: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing changes to Overleaf...')),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAiAssistDialog(LaTeXService latex) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NBColors.bg,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: NBColors.black, width: 3),
          borderRadius: NBRadius.softAll,
        ),
        title: Text('LUMINA AI ASSIST', style: NBText.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What should I help you with?', style: NBText.bodySmall),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: NBColors.white,
                border: Border.all(color: NBColors.black, width: 2),
                borderRadius: NBRadius.softAll,
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'e.g. Add a section for experimental analysis...',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: NBText.label.copyWith(color: Colors.grey)),
          ),
          NBButton(
            label: 'GENERATE',
            onTap: () async {
              final prompt = controller.text;
              Navigator.pop(context);
              await latex.generateWithAI(prompt);
              _editorController.text = latex.currentReport!.rawContent;
            },
          ),
        ],
      ),
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
