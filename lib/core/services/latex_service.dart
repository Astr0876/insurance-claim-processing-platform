import 'package:flutter/material.dart';

class LaTeXReport {
  final String id;
  final String name;
  final String status; // 'Compiled', 'Compiling...', 'Error'
  final DateTime lastUpdated;
  final String previewUrl;
  final String author;

  LaTeXReport({
    required this.id,
    required this.name,
    required this.status,
    required this.lastUpdated,
    required this.previewUrl,
    required this.author,
  });
}

class LaTeXService extends ChangeNotifier {
  LaTeXReport? _currentReport;
  LaTeXReport? get currentReport => _currentReport;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  void loadDemoData() {
    _currentReport = LaTeXReport(
      id: 'overleaf-123',
      name: 'Physics Lab Report - Group 4',
      status: 'Compiled',
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      previewUrl: 'assets/demo_lab_report.pdf', // Mock path
      author: 'Vatsal & Group',
    );
    notifyListeners();
  }

  Future<void> syncWithOverleaf() async {
    _isSyncing = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    _currentReport = LaTeXReport(
      id: 'overleaf-123',
      name: 'Physics Lab Report - Group 4',
      status: 'Compiled',
      lastUpdated: DateTime.now(),
      previewUrl: 'assets/demo_lab_report.pdf',
      author: 'Vatsal & Group',
    );

    _isSyncing = false;
    notifyListeners();
  }
}
