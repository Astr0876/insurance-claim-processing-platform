import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'package:runanywhere/runanywhere.dart';

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
  
  // SDK States
  bool _isInitialized = false;
  bool _isModelDownloaded = false;
  bool _isModelLoaded = false;
  double _downloadProgress = 0;
  String _statusMessage = 'Lumina is offline';

  // RunAnywhere Components
  final RunAnywhereVectorStore _vectorStore = RunAnywhereVectorStore();

  // Getters
  bool get hasDocument => _hasDocument;
  String get documentContent => _documentContent;
  AssistantMode get mode => _mode;
  bool get isInitialized => _isInitialized;
  bool get isModelDownloaded => _isModelDownloaded;
  bool get isModelLoaded => _isModelLoaded;
  double get downloadProgress => _downloadProgress;
  String get statusMessage => _statusMessage;

  void setMode(AssistantMode newMode) {
    _mode = newMode;
    if (_mode == AssistantMode.luminaRag && !_isInitialized) {
      setupLumina();
    }
    notifyListeners();
  }

  /// Initial Setup (Registration & Init)
  Future<void> setupLumina() async {
    try {
      _statusMessage = 'Registering Lumina Engine...';
      notifyListeners();

      // 1. Register LlamaCpp Backend
      LlamaCpp.register();

      // 2. Add Model Metadata
      LlamaCpp.addModel(
        id: 'smollm2-360m',
        name: 'SmolLM2 360M',
        url: 'https://huggingface.co/runanywhere/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q8_0.gguf',
        memoryRequirement: 500 * 1024 * 1024, // 500MB
      );

      // 3. Initialize SDK
      await RunAnywhere.initialize(
        environment: SDKEnvironment.development,
      );

      _isInitialized = true;
      _statusMessage = 'Lumina Engine Ready';
      
      // Check if model is already downloaded
      final modelInfo = await RunAnywhere.getModelInfo('smollm2-360m');
      if (modelInfo != null && modelInfo.localPath != null) {
        _isModelDownloaded = true;
        _statusMessage = 'Model available locally';
        await loadLumina();
      } else {
        _statusMessage = 'Model download required';
      }
      
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Init Error: $e';
      debugPrint("Lumina Setup Error: $e");
      notifyListeners();
    }
  }

  /// Download Model
  Future<void> downloadLumina() async {
    if (!_isInitialized) await setupLumina();
    
    try {
      _statusMessage = 'Downloading local brain...';
      notifyListeners();

      RunAnywhere.downloadModel('smollm2-360m').listen(
        (progress) {
          _downloadProgress = progress;
          _statusMessage = 'Downloading: ${(_downloadProgress * 100).toStringAsFixed(1)}%';
          notifyListeners();
        },
        onDone: () async {
          _isModelDownloaded = true;
          _statusMessage = 'Download complete';
          notifyListeners();
          await loadLumina();
        },
        onError: (e) {
          _statusMessage = 'Download failed: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      _statusMessage = 'Download error: $e';
      notifyListeners();
    }
  }

  /// Load Model into Memory
  Future<void> loadLumina() async {
    try {
      _statusMessage = 'Loading brain into memory...';
      notifyListeners();

      final modelInfo = await RunAnywhere.getModelInfo('smollm2-360m');
      if (modelInfo != null && modelInfo.localPath != null) {
        await RunAnywhere.loadModel(modelInfo.localPath!);
        _isModelLoaded = true;
        _statusMessage = 'Lumina is Live & Local';
        
        // Index document if present
        if (_hasDocument) {
          await indexDocument(_documentContent);
        }
      }
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Load error: $e';
      notifyListeners();
    }
  }

  Future<void> indexDocument(String content) async {
    if (!_isModelLoaded) return;
    
    try {
      final doc = Document(
        id: 'user_notes_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        metadata: {'type': 'textbook'},
      );
      await _vectorStore.addDocuments([doc]);
    } catch (e) {
      debugPrint("Indexing Error: $e");
    }
  }

  void loadDemoDocument() {
    _documentContent = AppConstants.demoPdfContent;
    _hasDocument = true;
    if (_isModelLoaded) {
      indexDocument(_documentContent);
    }
  }

  void loadDocument(String content) {
    _documentContent = content;
    _hasDocument = content.isNotEmpty;
    if (_isModelLoaded) {
      indexDocument(_documentContent);
    }
    notifyListeners();
  }

  /// RAG mode: Streams a generated answer
  Stream<String> getAnswerStream(String query) async* {
    if (_mode == AssistantMode.standard) {
      yield getAnswer(query);
      return;
    }

    if (!_isModelLoaded) {
      yield "Lumina's local brain is not loaded. Please wait or check status. 🧠";
      if (!_isInitialized) await setupLumina();
      if (!_isModelDownloaded) {
        yield "Model download required. Starting download... ⬇️";
        await downloadLumina();
        return;
      }
      await loadLumina();
    }

    // 1. Retrieval
    yield "Searching your local notes... 🔍";
    List<Document> contextDocs = [];
    try {
      contextDocs = await _vectorStore.similaritySearch(query, k: 3);
    } catch (e) {
      debugPrint("Retrieval error: $e");
    }

    final contextText = contextDocs.map((d) => d.content).join('\n\n');

    // 2. Generation
    yield "Lumina is synthesizing an answer... ✨";

    final prompt = contextText.isNotEmpty 
      ? "Use this context: $contextText\n\nQuestion: $query\nAnswer:"
      : "Question: $query\nAnswer:";

    try {
      final streamResult = await RunAnywhere.generateStream(
        prompt,
        options: LLMGenerationOptions(
          maxTokens: 512,
          temperature: 0.7,
        ),
      );

      String accumulated = "";
      await for (final token in streamResult.stream) {
        accumulated += token;
        yield accumulated;
      }
      
      final finalResult = await streamResult.result;
      yield "$accumulated\n\n---\n*Speed: ${finalResult.tokensPerSecond?.toStringAsFixed(1)} tok/s | On-Device*";
    } catch (e) {
      // Small talk fallback for simple greetings
      final lower = query.toLowerCase().trim();
      if (lower == 'hi' || lower == 'hello') {
        yield "Hello! I'm Lumina. How can I help you with your studies today? 👋";
      } else {
        yield "Local generation error: $e\n\nFallback search:\n${getAnswer(query)}";
      }
    }
  }

  /// Fallback Search
  String getAnswer(String query) {
    final results = _internalSearch(query);
    if (results.isEmpty) return "No matches found in your notes. Try rephrasing!";
    final buffer = StringBuffer();
    buffer.writeln("Quick Search Results:\n");
    for (var res in results) buffer.writeln(res.snippet);
    return buffer.toString().trim();
  }

  List<SearchResult> _internalSearch(String query) {
    if (!_hasDocument || query.trim().isEmpty) return [];
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
        final relevance = matchCount / queryWords.length;
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
}
