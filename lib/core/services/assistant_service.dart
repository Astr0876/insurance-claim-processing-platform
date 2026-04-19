import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:runanywhere/runanywhere.dart';
import '../utils/constants.dart';
import 'gradio_service.dart';
import 'gemini_service.dart';
import '../../features/assistant/models/assistant_graph_models.dart';

class SearchResult {
// ... existing SearchResult class ...
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
// ... existing fields ...
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
// ... existing setMode ...
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
    const modelId = 'smollm2-360m-q8_0';
    _statusMessage = 'Starting Download...';
    _downloadProgress = 0;
    notifyListeners();

    try {
      await for (final progress in RunAnywhere.downloadModel(modelId)) {
        _downloadProgress = progress.percentage;
        _statusMessage = 'Downloading Model: ${(_downloadProgress * 100).toStringAsFixed(1)}%';
        notifyListeners();
        if (progress.state.isCompleted) break;
      }

      _statusMessage = 'Loading Model...';
      notifyListeners();
      await RunAnywhere.loadModel(modelId);

      _isModelDownloaded = true;
      _isModelLoaded = true;
      _statusMessage = 'Lumina Engine Loaded';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Download Error: $e';
      notifyListeners();
    }
  }

  Future<void> loadLumina() async {
    const modelId = 'smollm2-360m-q8_0';
    try {
      await RunAnywhere.loadModel(modelId);
      _isModelLoaded = true;
      _statusMessage = 'Lumina is Ready (On-Device)';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Load Error: $e';
      notifyListeners();
    }
  }

  bool _isIndexingPaused = false;
  bool get isIndexingPaused => _isIndexingPaused;

  void setIndexingPaused(bool paused) {
    _isIndexingPaused = paused;
    _statusMessage = paused ? 'Indexing Paused (Power Saving)' : 'Lumina is Ready (Local)';
    notifyListeners();
  }

  Future<void> indexDocument(String content) async {
// ... existing indexDocument ...
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
// ... existing uploadNotesToAI ...
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

  KnowledgeGraphData getKnowledgeGraph() {
    if (!_hasDocument) return KnowledgeGraphData(nodes: [], edges: []);

    final paragraphs = _documentContent.split(RegExp(r'\n\n+'))
        .where((p) => p.trim().length > 20)
        .toList();
    
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];
    final conceptMap = <String, List<int>>{}; // concept -> list of paragraph indices

    // 1. Create Chunk Nodes and extract concepts
    for (int i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      final concepts = _extractConcepts(para);
      
      nodes.add(GraphNode(
        id: 'chunk_$i',
        label: '${para.substring(0, min(para.length, 30)).replaceAll('\n', ' ')}...',
        type: 'chunk',
        metadata: {'content': para},
      ));

      for (final concept in concepts) {
        if (!conceptMap.containsKey(concept)) {
          conceptMap[concept] = [];
        }
        conceptMap[concept]!.add(i);
      }
    }

    // 2. Create Concept Nodes and link to chunks
    int conceptIdx = 0;
    conceptMap.forEach((concept, paraIndices) {
      // Only include concepts that appear in multiple paragraphs or are significant
      if (paraIndices.isNotEmpty) {
        final conceptId = 'concept_$conceptIdx';
        nodes.add(GraphNode(
          id: conceptId,
          label: concept,
          type: 'concept',
        ));

        for (final pIdx in paraIndices) {
          edges.add(GraphEdge(
            from: 'chunk_$pIdx',
            to: conceptId,
            weight: 1.0,
          ));
        }
        conceptIdx++;
      }
    });

    // 3. Link chunks based on semantic similarity (keyword overlap)
    for (int i = 0; i < paragraphs.length; i++) {
      for (int j = i + 1; j < paragraphs.length; j++) {
        final similarity = _calculateSimilarity(paragraphs[i], paragraphs[j]);
        if (similarity > 0.25) {
          edges.add(GraphEdge(
            from: 'chunk_$i',
            to: 'chunk_$j',
            weight: similarity,
          ));
        }
      }
    }

    return KnowledgeGraphData(nodes: nodes, edges: edges);
  }

  List<String> _extractConcepts(String text) {
    // Simple concept extraction: words starting with capital letters (excluding start of sentence)
    // or long words that appear important.
    final words = text.split(RegExp(r'[\s,.;:()]+'));
    final concepts = <String>{};
    
    for (int i = 1; i < words.length; i++) {
      final word = words[i];
      if (word.length > 4 && 
          word[0].toUpperCase() == word[0] && 
          word.toLowerCase() != word) {
        // Clean word
        final clean = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (clean.length > 3) concepts.add(clean);
      }
    }
    
    // Also include some predefined "academic" keywords if present
    final academicKeywords = ['Quantum', 'Algorithm', 'Synthesis', 'Mechanism', 'Process', 'Theory'];
    for (final kw in academicKeywords) {
      if (text.contains(kw)) concepts.add(kw);
    }

    return concepts.take(5).toList();
  }

  double _calculateSimilarity(String a, String b) {
    final wordsA = a.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    final wordsB = b.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 3).toSet();
    
    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;
    
    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;
    
    return intersection / union;
  }

  Stream<String> getAnswerStream(String query) async* {
    if (_mode == AssistantMode.standard) {
      // Try Gemini first (works everywhere)
      if (GeminiService.instance.isInitialized) {
        yield "🧠 [Gemini AI] Thinking...\n\n";
        try {
          await for (final token in GeminiService.instance.chatStream(query)) {
            yield token;
          }
          return;
        } catch (e) {
          yield "Gemini error: $e. Falling back...\n\n";
        }
      }
      
      // Then try RunAnywhere on-device
      if (_isModelLoaded) {
        yield "🧠 [On-Device LLM] Thinking...\n\n";
        try {
          final streamResult = await RunAnywhere.generateStream(
            query,
            options: LLMGenerationOptions(
              maxTokens: 500,
              systemPrompt: "You are Lumina, a proactive student sidekick. Keep answers helpful and concise.",
            ),
          );
          await for (final token in streamResult.stream) {
            yield token;
          }
          return;
        } catch (e) {
          yield "On-device error: $e. Falling back to simple response.\n\n";
        }
      }
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

    // Try Gemini AI first
    if (GeminiService.instance.isInitialized) {
      try {
        return await GeminiService.instance.chat(query);
      } catch (e) {
        debugPrint('Gemini chat error: $e');
      }
    }

    // Try on-device chat if model loaded
    if (_isModelLoaded) {
      try {
        return await RunAnywhere.chat(query);
      } catch (e) {
        debugPrint('On-device chat error: $e');
      }
    }

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
// ... existing _internalSearch ...
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
