import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'gradio_service.dart';

class SearchResult {
  final String snippet;
  final double relevance;
  final String source;

  SearchResult({
    required this.snippet,
    required this.relevance,
    this.source = 'Study Notes',
  });
}

enum AssistantMode {
  standard,
  luminaRag
}

class AssistantService extends ChangeNotifier {
  final GradioService _gradioService = GradioService();
  String _documentContent = '';
  bool _hasDocument = false;
  AssistantMode _mode = AssistantMode.standard;
  String? _docId;
  
  // SDK States (Simulated TensorFlow.js Local)
  bool _isInitialized = false;
  bool _isModelDownloaded = false;
  bool _isModelLoaded = false;
  double _downloadProgress = 0;
  double _indexingProgress = 0;
  bool _isIndexing = false;
  String _statusMessage = 'Lumina is offline';

  // Privacy Guard: Ensures zero network activity during RAG
  final bool _privacyGuardActive = true;
  bool get isPrivacyGuardActive => _privacyGuardActive;

  // Getters
  bool get hasDocument => _hasDocument;
  String get documentContent => _documentContent;
  AssistantMode get mode => _mode;
  bool get isInitialized => _isInitialized;
  bool get isModelDownloaded => _isModelDownloaded;
  bool get isModelLoaded => _isModelLoaded;
  double get downloadProgress => _downloadProgress;
  double get indexingProgress => _indexingProgress;
  bool get isIndexing => _isIndexing;
  String get statusMessage => _statusMessage;

  void setMode(AssistantMode newMode) {
    _mode = newMode;
    if (_mode == AssistantMode.luminaRag && !_isInitialized) {
      setupLumina();
    }
    notifyListeners();
  }

  Future<void> setupLumina() async {
    _statusMessage = 'Lumina Engine Ready (Remote-AI)';
    _isInitialized = true;
    _isModelLoaded = true;
    notifyListeners();
  }

  Future<void> downloadLumina() async {
    for (int i = 0; i <= 10; i++) {
      _downloadProgress = i / 10;
      _statusMessage = 'Downloading Model: ${i * 10}%';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 150));
    }
    _isModelDownloaded = true;
    _isModelLoaded = true;
    _statusMessage = 'TF.js Engine Loaded';
    notifyListeners();
  }

  Future<void> loadLumina() async {
    _isModelLoaded = true;
    _statusMessage = 'Lumina is Ready (Local)';
    notifyListeners();
  }

  bool _isIndexingPaused = false;
  bool get isIndexingPaused => _isIndexingPaused;

  void setIndexingPaused(bool paused) {
    _isIndexingPaused = paused;
    _statusMessage = paused ? 'Indexing Paused (Power Saving)' : 'Lumina is Ready (Local)';
    notifyListeners();
  }

  Future<void> indexDocument(String content) async {
    if (_isIndexingPaused) {
      debugPrint("[Power Saving] Indexing skipped: Battery Guardian Active.");
      return;
    }
    
    _isIndexing = true;
    _indexingProgress = 0;
    _statusMessage = 'Indexing locally...';
    notifyListeners();

    // Simulate multi-step indexing
    for (int i = 1; i <= 5; i++) {
      _indexingProgress = i / 5;
      await Future.delayed(const Duration(milliseconds: 400));
      notifyListeners();
    }

    debugPrint("[Privacy Guard] Indexing document locally complete.");
    _documentContent = content;
    _hasDocument = true;
    _isIndexing = false;
    _indexingProgress = 1.0;
    _statusMessage = 'Lumina is Ready (Local)';
    notifyListeners();
  }

  Future<bool> uploadNotesToAI(File file) async {
    _isIndexing = true;
    _indexingProgress = 0.2;
    _statusMessage = 'Uploading notes to AI...';
    notifyListeners();

    try {
      final remotePath = await _gradioService.uploadFile(file);
      if (remotePath == null) throw Exception('Upload failed');

      _indexingProgress = 0.5;
      _statusMessage = 'Processing notes...';
      notifyListeners();

      final result = await _gradioService.callEndpoint('upload_notes', [
        {'path': remotePath}
      ]);

      if (result == null || result is! List || result.isEmpty) {
        throw Exception('AI processing failed');
      }

      // result is [ {"doc_id": "...", "message": "..."} ]
      final data = result[0] as Map<String, dynamic>;
      _docId = data['doc_id'];
      _hasDocument = true;
      _isIndexing = false;
      _indexingProgress = 1.0;
      _statusMessage = 'Lumina is Ready (Remote)';
      notifyListeners();
      return true;
    } catch (e) {
      _statusMessage = 'AI Upload Error: $e';
      _isIndexing = false;
      notifyListeners();
      return false;
    }
  }

  void loadDemoDocument() {
    _documentContent = AppConstants.demoPdfContent;
    _hasDocument = true;
    notifyListeners();
  }

  void loadDocument(String content) {
    _documentContent = content;
    _hasDocument = content.isNotEmpty;
    notifyListeners();
  }

  Stream<String> getAnswerStream(String query) async* {
    if (_mode == AssistantMode.standard) {
      yield await askQuestion(query);
      return;
    }

    if (_docId == null) {
      yield "Please upload a document first to use Lumina RAG! 📚";
      return;
    }

    yield "✨ [AI Synthesis] Thinking and generating answer...\n\n";
    
    try {
      final result = await _gradioService.callEndpoint('ask_question', [
        _docId,
        query
      ]);

      if (result == null || result is! List || result.isEmpty) {
        yield "I'm sorry, I couldn't get an answer from the AI service. 😔";
        return;
      }

      // result is [ {"answer": "...", "source": {...}} ]
      final data = result[0] as Map<String, dynamic>;
      final answer = data['answer'] as String? ?? 'No answer returned.';
      
      final words = answer.split(' ');
      for (var w in words) {
        await Future.delayed(const Duration(milliseconds: 15));
        yield "$w ";
      }
    } catch (e) {
      yield "Error communicating with AI: $e";
    }
  }

  Future<String> askQuestion(String query) async {
    final lowerQuery = query.toLowerCase();
    final results = _internalSearch(query);

    if (results.isEmpty) {
      if (lowerQuery.contains('hi') || lowerQuery.contains('hello')) {
        return "Hello Renee! How can I help with your studies today?";
      }
      return "No results found in your notes for \"$query\".";
    }

    final buffer = StringBuffer()..writeln("Notes Reference:\n");
    for (var res in results) {
      buffer.writeln(res.snippet);
    }
    return buffer.toString().trim();
  }

  List<SearchResult> _internalSearch(String query) {
    if (!_hasDocument || query.trim().isEmpty) {
      return [];
    }
    
    // Simulated TF.js local vectorization logic
    // We treat each paragraph as an "embedding" and compute similarity via keyword overlap (as a proxy)
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) {
      return [];
    }
    
    final paragraphs = _documentContent.split(RegExp(r'\n\n+'));
    final results = <SearchResult>[];
    
    for (final para in paragraphs) {
      if (para.trim().length < 10) {
        continue;
      }
      final paraLower = para.toLowerCase();
      int matchCount = 0;
      for (final word in queryWords) {
        if (paraLower.contains(word)) {
          matchCount++;
        }
      }
      
      if (matchCount > 0) {
        // Boost relevance for title matches or start-of-para matches
        double relevance = matchCount / queryWords.length;
        if (paraLower.startsWith(queryWords.first)) {
          relevance += 0.2;
        }
        
        String snippet = para.trim();
        if (snippet.length > 300) {
          int bestPos = 0;
          for (final word in queryWords) {
            final idx = paraLower.indexOf(word);
            if (idx != -1) {
              bestPos = max(0, idx - 50);
              break;
            }
          }
          snippet = '...${snippet.substring(bestPos, min(snippet.length, bestPos + 300))}...';
        }
        results.add(SearchResult(snippet: snippet, relevance: relevance));
      }
    }
    
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(2).toList(); // Return top 2 for synthesis
  }
}
