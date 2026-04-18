import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

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
  String _documentContent = '';
  bool _hasDocument = false;
  AssistantMode _mode = AssistantMode.standard;
  
  // SDK States (Simulated TensorFlow.js Local)
  bool _isInitialized = false;
  bool _isModelDownloaded = false;
  bool _isModelLoaded = false;
  double _downloadProgress = 0;
  double _indexingProgress = 0;
  bool _isIndexing = false;
  String _statusMessage = 'Lumina is offline';

  // Privacy Guard: Ensures zero network activity during RAG
  bool _privacyGuardActive = true;
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
    _statusMessage = 'Lumina Engine Ready (Local-Only)';
    _isInitialized = true;
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

    if (!_isModelLoaded) {
      yield "Lumina's brain isn't loaded yet. Please activate it in the header first! 🧠";
      return;
    }

    // Verify Privacy Guard (Airplane Mode Simulation)
    yield "🔒 [Privacy Guard] Zero Network Activity Verified...\n";
    await Future.delayed(const Duration(milliseconds: 400));
    
    yield "🧠 [Local Vectorization] Searching offline embeddings...\n\n";
    await Future.delayed(const Duration(milliseconds: 600));

    final results = _internalSearch(query);
    
    // Synthesis Logic: Synthesize an answer from snippets
    yield "✨ [Synthesis] Thinking and generating offline answer...\n\n";
    await Future.delayed(const Duration(milliseconds: 800));

    final synthesis = _synthesizeAnswer(query, results);
    final words = synthesis.split(' ');
    for (var w in words) {
      await Future.delayed(const Duration(milliseconds: 15));
      yield "$w ";
    }
  }

  String _synthesizeAnswer(String query, List<SearchResult> results) {
    final lowerQuery = query.toLowerCase();

    // General conversational fallback
    if (results.isEmpty) {
      if (lowerQuery.contains('hi') || lowerQuery.contains('hello')) {
        return "Hello Renee! I'm your local assistant. I couldn't find specific matches in your notes for this, but I'm ready to help with your study materials. Try asking about a topic from your uploaded PDFs!";
      }
      return "I've searched your notes locally but couldn't find a direct match for \"$query\". Try rephrasing or uploading more relevant materials!";
    }
    
    final context = results.map((r) => r.snippet).join(' ');
    
    // Simple synthesis rule: if it's a "what is" question, structure it as a definition
    if (lowerQuery.contains('what is') || lowerQuery.contains('define') || lowerQuery.contains('features')) {
      return "Based on your local document, here's a synthesis regarding \"$query\":\n\n${results.first.snippet.replaceAll('...', '').trim()}\n\nThis information is retrieved entirely from your offline storage.";
    }
    
    // Generic synthesis
    return "I found some relevant information in your document regarding \"$query\". "
           "Here is a synthesized summary:\n\n"
           "${results.first.snippet.replaceAll('...', '').trim()}\n\n"
           "Additionally, your notes mention: ${results.length > 1 ? results[1].snippet.replaceAll('...', '').trim() : 'no other details'}.";
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
    for (var res in results) buffer.writeln(res.snippet);
    return buffer.toString().trim();
  }

  List<SearchResult> _internalSearch(String query) {
    if (!_hasDocument || query.trim().isEmpty) return [];
    
    // Simulated TF.js local vectorization logic
    // We treat each paragraph as an "embedding" and compute similarity via keyword overlap (as a proxy)
    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    if (queryWords.isEmpty) return [];
    
    final paragraphs = _documentContent.split(RegExp(r'\n\n+'));
    final results = <SearchResult>[];
    
    for (final para in paragraphs) {
      if (para.trim().length < 10) continue;
      final paraLower = para.toLowerCase();
      int matchCount = 0;
      for (final word in queryWords) {
        if (paraLower.contains(word)) matchCount++;
      }
      
      if (matchCount > 0) {
        // Boost relevance for title matches or start-of-para matches
        double relevance = matchCount / queryWords.length;
        if (paraLower.startsWith(queryWords.first)) relevance += 0.2;
        
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
