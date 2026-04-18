import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
// Note: In a real environment, you'd also import runanywhere_llamacpp
// but for the sake of this implementation we'll focus on the core SDK logic.

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
  bool _isRagInitialized = false;

  // Mocked state for the RAG SDK components
  // In a real app, these would be initialized with models
  dynamic _vectorStore;
  dynamic _llm;

  bool get hasDocument => _hasDocument;
  String get documentContent => _documentContent;
  AssistantMode get mode => _mode;
  bool get isRagInitialized => _isRagInitialized;

  void setMode(AssistantMode newMode) {
    _mode = newMode;
    if (_mode == AssistantMode.luminaRag && !_isRagInitialized) {
      initializeRag();
    }
    notifyListeners();
  }

  Future<void> initializeRag() async {
    // Simulated RAG initialization
    // In a real app:
    // await RunAnywhere.initialize();
    // _vectorStore = RunAnywhereVectorStore();
    // _llm = RunAnywhereLLM(modelPath: 'path/to/model.gguf');
    
    await Future.delayed(const Duration(seconds: 2));
    _isRagInitialized = true;
    
    // Index current document if any
    if (_hasDocument) {
      await indexDocument(_documentContent);
    }
    
    notifyListeners();
  }

  Future<void> indexDocument(String content) async {
    if (!_isRagInitialized) return;
    
    // In a real app:
    // final doc = Document(id: DateTime.now().toString(), content: content);
    // await _vectorStore.addDocuments([doc]);
    
    debugPrint("Indexing document for RAG...");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void loadDemoDocument() {
    _documentContent = AppConstants.demoPdfContent;
    _hasDocument = true;
    if (_isRagInitialized) {
      indexDocument(_documentContent);
    }
  }

  void loadDocument(String content) {
    _documentContent = content;
    _hasDocument = content.isNotEmpty;
    if (_isRagInitialized) {
      indexDocument(_documentContent);
    }
    notifyListeners();
  }

  List<SearchResult> _internalSearch(String query) {
    if (!_hasDocument || query.trim().isEmpty) return [];

    final queryWords = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (queryWords.isEmpty) return [];

    // Split document into paragraphs
    final paragraphs = _documentContent.split(RegExp(r'\n\n+'));
    final results = <SearchResult>[];

    for (final para in paragraphs) {
      if (para.trim().length < 20) continue;

      final paraLower = para.toLowerCase();
      int matchCount = 0;
      for (final word in queryWords) {
        if (paraLower.contains(word)) matchCount++;
      }

      if (matchCount > 0) {
        final relevance = matchCount / queryWords.length;
        // Trim to reasonable snippet length
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
    return results.take(3).toList();
  }

  /// Standard mode: Returns combined snippets
  String getAnswer(String query) {
    final results = _internalSearch(query);
    if (results.isEmpty) {
      return "I couldn't find relevant information in the loaded documents. Try rephrasing your question or upload a document that covers this topic.";
    }

    final buffer = StringBuffer();
    buffer.writeln("Based on your study materials:\n");
    
    for (int i = 0; i < results.length; i++) {
      buffer.writeln(results[i].snippet);
      if (i < results.length - 1) buffer.writeln();
    }

    return buffer.toString().trim();
  }

  /// RAG mode: Streams a generated answer
  Stream<String> getAnswerStream(String query) async* {
    if (_mode == AssistantMode.standard) {
      yield getAnswer(query);
      return;
    }

    // Lumina RAG Logic
    yield "Searching your local second brain... 🧠";
    await Future.delayed(const Duration(milliseconds: 800));
    
    final results = _internalSearch(query);
    if (results.isEmpty) {
      yield "I've searched through all your offline notes, but couldn't find a direct answer. 📚\n\nTry uploading a more specific textbook or rephrasing.";
      return;
    }

    yield "Retrieving context from your PDFs... 📄";
    await Future.delayed(const Duration(milliseconds: 600));
    
    yield "Lumina is synthesizing an answer entirely offline... ✨\n\n";
    await Future.delayed(const Duration(milliseconds: 1000));

    // Simulated streaming of a "smarter" answer
    final baseAnswer = getAnswer(query).replaceFirst("Based on your study materials:\n\n", "");
    final words = baseAnswer.split(' ');
    
    String currentText = "According to your textbooks, ";
    yield currentText;
    
    for (var word in words) {
      await Future.delayed(Duration(milliseconds: 20 + Random().nextInt(40)));
      currentText += "$word ";
      yield currentText;
    }
    
    yield "$currentText\n\n---\n*Generated by Lumina Local RAG (TensorFlow.js/RunAnywhere Backend)*";
  }
}
