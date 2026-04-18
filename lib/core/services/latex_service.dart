import 'package:flutter/material.dart';

class LaTeXReport {
  final String id;
  final String name;
  final String status; // 'Compiled', 'Compiling...', 'Error'
  final DateTime lastUpdated;
  final String previewUrl;
  final String author;
  final String rawContent;

  LaTeXReport({
    required this.id,
    required this.name,
    required this.status,
    required this.lastUpdated,
    required this.previewUrl,
    required this.author,
    required this.rawContent,
  });

  LaTeXReport copyWith({
    String? status,
    DateTime? lastUpdated,
    String? rawContent,
  }) {
    return LaTeXReport(
      id: id,
      name: name,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      previewUrl: previewUrl,
      author: author,
      rawContent: rawContent ?? this.rawContent,
    );
  }
}

class LaTeXService extends ChangeNotifier {
  LaTeXReport? _currentReport;
  LaTeXReport? get currentReport => _currentReport;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  void loadDemoData() {
    _currentReport = LaTeXReport(
      id: 'overleaf-123',
      name: 'Physics Lab Report - Group 4',
      status: 'Compiled',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      previewUrl: 'assets/demo_lab_report.pdf',
      author: 'Vatsal & Group',
      rawContent: r'''\documentclass{article}
\usepackage[utf8]{inputenc}

\title{Physics Lab 4: Pendulum Motion}
\author{Vatsal, Renee, Alex}
\date{\today}

\begin{document}

\maketitle

\section{Introduction}
This report details our findings regarding the simple harmonic motion of a pendulum.

\section{Data}
Trial 1: 1.2s \\
Trial 2: 1.1s \\
Trial 3: 1.25s

\end{document}''',
    );
    notifyListeners();
  }

  void updateContent(String newContent) {
    if (_currentReport != null) {
      _currentReport = _currentReport!.copyWith(rawContent: newContent);
      notifyListeners();
    }
  }

  Future<void> generateWithAI(String prompt) async {
    if (_currentReport == null) return;
    
    _isGenerating = true;
    _currentReport = _currentReport!.copyWith(status: 'AI Generating...');
    notifyListeners();

    // Simulate AI generation
    await Future.delayed(const Duration(seconds: 3));

    // Use raw string to avoid interpolation issues with $
    const aiSnippet = r'''

\section{AI Analysis}
Based on the provided data, the average period is 1.18s. 
The experimental value of $g$ calculated is approximately $9.75 m/s^2$.
The error margin is within 2.5% of the standard value.
''';

    final newContent = _currentReport!.rawContent.replaceFirst(
      '\\end{document}', 
      '$aiSnippet\n\\end{document}'
    );

    _currentReport = _currentReport!.copyWith(
      rawContent: newContent,
      status: 'Compiled',
      lastUpdated: DateTime.now(),
    );
    
    _isGenerating = false;
    notifyListeners();
  }

  Future<void> syncWithOverleaf() async {
    _isSyncing = true;
    notifyListeners();

    // Simulated Overleaf Webhook Delay
    await Future.delayed(const Duration(seconds: 2));

    if (_currentReport != null) {
      // Pulling "latest" PDF compilation from simulated webhook
      _currentReport = _currentReport!.copyWith(
        status: 'Compiled',
        lastUpdated: DateTime.now(),
      );
      
      // In a real app, this URL would come from the webhook payload.
      // We'll update it to a different (but valid) PDF to show it pulled something new.
      // Using a public sample PDF URL.
      _currentReport = LaTeXReport(
        id: _currentReport!.id,
        name: _currentReport!.name,
        status: 'Compiled',
        lastUpdated: DateTime.now(),
        previewUrl: 'https://cdn.syncfusion.com/content/PDFViewer/flutter-succinctly.pdf',
        author: _currentReport!.author,
        rawContent: _currentReport!.rawContent,
      );
    }

    _isSyncing = false;
    notifyListeners();
  }
}
