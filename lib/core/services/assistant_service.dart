import 'dart:math';
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

class AssistantService {
  String _documentContent = '';
  bool _hasDocument = false;

  bool get hasDocument => _hasDocument;
  String get documentContent => _documentContent;

  void loadDemoDocument() {
    _documentContent = AppConstants.demoPdfContent;
    _hasDocument = true;
  }

  void loadDocument(String content) {
    _documentContent = content;
    _hasDocument = content.isNotEmpty;
  }

  List<SearchResult> search(String query) {
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
          // Try to find the best starting position
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

    // Sort by relevance
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(3).toList();
  }

  /// Generate a natural-sounding answer from search results
  String getAnswer(String query) {
    final results = search(query);
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
}
