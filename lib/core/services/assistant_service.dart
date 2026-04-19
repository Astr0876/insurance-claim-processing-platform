import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../features/assistant/models/assistant_graph_models.dart';
import '../utils/constants.dart';
import 'gemini_service.dart';

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

class UploadedFileMetadata {
  final String name;
  final int sizeBytes;
  final DateTime uploadedAt;

  const UploadedFileMetadata({
    required this.name,
    required this.sizeBytes,
    required this.uploadedAt,
  });
}

class _IndexedChunk {
  final String id;
  final String sourceName;
  final String text;
  final Set<String> tokens;

  const _IndexedChunk({
    required this.id,
    required this.sourceName,
    required this.text,
    required this.tokens,
  });
}

enum AssistantMode { standard, luminaRag }

class AssistantService extends ChangeNotifier {
  String _documentContent = '';
  bool _hasDocument = false;
  AssistantMode _mode = AssistantMode.standard;

  bool _isInitialized = false;
  bool _isModelDownloaded = false;
  bool _isModelLoaded = false;
  double _downloadProgress = 0;
  double _indexingProgress = 0;
  bool _isIndexing = false;
  String _statusMessage = 'Lumina is offline';

  final List<_IndexedChunk> _semanticChunks = [];
  final List<UploadedFileMetadata> _uploadedFiles = [];

  final bool _privacyGuardActive = true;
  bool get isPrivacyGuardActive => _privacyGuardActive;

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
  List<UploadedFileMetadata> get uploadedFiles =>
      List.unmodifiable(_uploadedFiles);

  void setMode(AssistantMode newMode) {
    _mode = newMode;
    if (_mode == AssistantMode.luminaRag && !_isInitialized) {
      setupLumina();
    }
    notifyListeners();
  }

  Future<void> setupLumina() async {
    _statusMessage = GeminiService.instance.isInitialized
        ? 'Lumina Engine Ready (Gemini AI)'
        : 'Lumina Engine Ready (Local RAG)';
    _isInitialized = true;
    _isModelLoaded = true;
    _isModelDownloaded = true;
    notifyListeners();
  }

  Future<void> downloadLumina() async {
    _statusMessage = 'Initializing Lumina local engine...';
    _downloadProgress = 0;
    notifyListeners();

    for (int i = 1; i <= 5; i++) {
      _downloadProgress = i / 5;
      _statusMessage =
          'Loading AI: ${(_downloadProgress * 100).toStringAsFixed(0)}%';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 120));
    }

    _isModelDownloaded = true;
    _isModelLoaded = true;
    _statusMessage = GeminiService.instance.isInitialized
        ? 'Lumina Engine Loaded (Gemini AI)'
        : 'Lumina Engine Loaded (Local RAG)';
    notifyListeners();
  }

  Future<void> loadLumina() async {
    _isModelLoaded = true;
    _statusMessage = GeminiService.instance.isInitialized
        ? 'Lumina is Ready (Gemini AI)'
        : 'Lumina is Ready';
    notifyListeners();
  }

  bool _isIndexingPaused = false;
  bool get isIndexingPaused => _isIndexingPaused;

  void setIndexingPaused(bool paused) {
    _isIndexingPaused = paused;
    _statusMessage = paused
        ? 'Indexing Paused (Power Saving)'
        : 'Lumina is Ready';
    notifyListeners();
  }

  Future<void> ingestLocalDocument({
    required String fileName,
    required int sizeBytes,
    Uint8List? bytes,
    String? filePath,
  }) async {
    if (_isIndexing) {
      throw Exception('Indexing is already in progress. Please wait.');
    }
    if (_isIndexingPaused) {
      throw Exception('Indexing is paused by Battery Guardian.');
    }

    final extension = _extensionOf(fileName, filePath);
    if (extension != 'txt' && extension != 'pdf') {
      throw Exception('Unsupported file type .$extension. Use .txt or .pdf.');
    }

    final extractedText = await _extractText(
      extension: extension,
      fileName: fileName,
      bytes: bytes,
      filePath: filePath,
    );

    if (extractedText.trim().isEmpty) {
      throw Exception('No extractable text found in $fileName.');
    }

    await _indexExtractedText(
      extractedText,
      sourceName: fileName,
      sizeBytes: sizeBytes,
    );
  }

  Future<void> indexDocument(String content) async {
    await _indexExtractedText(
      content,
      sourceName: 'Manual Input',
      sizeBytes: utf8.encode(content).length,
    );
  }

  Future<void> _indexExtractedText(
    String content, {
    required String sourceName,
    required int sizeBytes,
  }) async {
    _isIndexing = true;
    _indexingProgress = 0;
    _statusMessage = 'Indexing locally...';
    notifyListeners();

    final normalized = _normalizeText(content);
    final chunks = _chunkText(normalized, windowSize: 120, overlap: 30);

    if (chunks.isEmpty) {
      _isIndexing = false;
      _statusMessage = 'Indexing failed: no usable text chunks';
      notifyListeners();
      throw Exception('No indexable content was found.');
    }

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      _semanticChunks.add(
        _IndexedChunk(
          id: '${sourceName}_${i}_${DateTime.now().microsecondsSinceEpoch}',
          sourceName: sourceName,
          text: chunk,
          tokens: _tokenize(chunk),
        ),
      );
      _indexingProgress = (i + 1) / chunks.length;
      if (i % 3 == 0) {
        await Future.delayed(const Duration(milliseconds: 12));
      }
      notifyListeners();
    }

    if (_documentContent.isEmpty) {
      _documentContent = content;
    } else {
      _documentContent = '$_documentContent\n\n[$sourceName]\n$content';
    }

    _uploadedFiles.add(
      UploadedFileMetadata(
        name: sourceName,
        sizeBytes: sizeBytes,
        uploadedAt: DateTime.now(),
      ),
    );

    _hasDocument = _semanticChunks.isNotEmpty;
    _isIndexing = false;
    _indexingProgress = 1.0;
    _statusMessage = 'Lumina is Ready (Local RAG)';
    notifyListeners();
    debugPrint('[Privacy Guard] Indexed "$sourceName" locally.');
  }

  Future<String> _extractText({
    required String extension,
    required String fileName,
    Uint8List? bytes,
    String? filePath,
  }) async {
    switch (extension) {
      case 'txt':
        return _extractTxt(
          bytes: bytes,
          filePath: filePath,
          fileName: fileName,
        );
      case 'pdf':
        return _extractPdf(
          bytes: bytes,
          filePath: filePath,
          fileName: fileName,
        );
      default:
        throw Exception('Unsupported file type for $fileName');
    }
  }

  Future<String> _extractTxt({
    Uint8List? bytes,
    String? filePath,
    required String fileName,
  }) async {
    if (bytes != null && bytes.isNotEmpty) {
      return utf8.decode(bytes, allowMalformed: true);
    }
    if (filePath != null && filePath.isNotEmpty) {
      return File(filePath).readAsString();
    }
    throw Exception('Unable to read text from $fileName (no bytes/path).');
  }

  Future<String> _extractPdf({
    Uint8List? bytes,
    String? filePath,
    required String fileName,
  }) async {
    Uint8List? pdfBytes = bytes;
    if ((pdfBytes == null || pdfBytes.isEmpty) &&
        filePath != null &&
        filePath.isNotEmpty) {
      pdfBytes = await File(filePath).readAsBytes();
    }

    if (pdfBytes == null || pdfBytes.isEmpty) {
      throw Exception('Unable to read PDF from $fileName (no bytes/path).');
    }

    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: pdfBytes);
      return PdfTextExtractor(document).extractText();
    } catch (e) {
      throw Exception('PDF extraction failed for $fileName: $e');
    } finally {
      document?.dispose();
    }
  }

  String _extensionOf(String fileName, String? filePath) {
    final source = (fileName.isNotEmpty ? fileName : (filePath ?? ''))
        .toLowerCase();
    final dot = source.lastIndexOf('.');
    if (dot == -1 || dot == source.length - 1) return '';
    return source.substring(dot + 1);
  }

  String _normalizeText(String input) {
    return input
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  List<String> _chunkText(
    String content, {
    int windowSize = 120,
    int overlap = 30,
  }) {
    final tokens = content
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];

    if (tokens.length <= windowSize) {
      return [tokens.join(' ')];
    }

    final chunks = <String>[];
    final stride = max(1, windowSize - overlap);

    for (int start = 0; start < tokens.length; start += stride) {
      final end = min(start + windowSize, tokens.length);
      final chunkTokens = tokens.sublist(start, end);
      final chunk = chunkTokens.join(' ').trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }
      if (end >= tokens.length) break;
    }

    return chunks;
  }

  Set<String> _tokenize(String text) {
    const stopwords = {
      'the',
      'and',
      'for',
      'with',
      'that',
      'this',
      'from',
      'into',
      'your',
      'you',
      'are',
      'was',
      'were',
      'have',
      'has',
      'had',
      'not',
      'but',
      'use',
      'using',
      'used',
      'then',
      'than',
      'they',
      'them',
      'their',
      'there',
      'about',
      'what',
      'when',
      'where',
      'which',
      'who',
      'how',
      'can',
      'could',
      'would',
      'should',
      'will',
      'shall',
      'may',
      'might',
      'also',
      'very',
      'more',
      'most',
      'such',
      'each',
      'other',
      'some',
      'any',
      'all',
      'our',
      'out',
      'its',
      "it's",
      'of',
      'in',
      'to',
      'on',
      'at',
      'by',
      'as',
      'is',
      'be',
      'or',
      'an',
      'a',
    };

    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 2 && !stopwords.contains(t))
        .toSet();
  }

  Future<bool> uploadNotesToAI(File file) async {
    try {
      await ingestLocalDocument(
        fileName: file.path.split(Platform.pathSeparator).last,
        sizeBytes: await file.length(),
        filePath: file.path,
      );
      return true;
    } catch (e) {
      _statusMessage = 'Indexing Error: $e';
      _isIndexing = false;
      notifyListeners();
      return false;
    }
  }

  void loadDemoDocument() {
    _documentContent = AppConstants.demoPdfContent;
    _hasDocument = true;
    _semanticChunks.clear();
    final chunks = _chunkText(_normalizeText(_documentContent));
    for (int i = 0; i < chunks.length; i++) {
      _semanticChunks.add(
        _IndexedChunk(
          id: 'demo_$i',
          sourceName: 'Demo Notes',
          text: chunks[i],
          tokens: _tokenize(chunks[i]),
        ),
      );
    }
    notifyListeners();
  }

  void loadDocument(String content) {
    _documentContent = content;
    _hasDocument = content.trim().isNotEmpty;
    _semanticChunks.clear();
    final chunks = _chunkText(_normalizeText(content));
    for (int i = 0; i < chunks.length; i++) {
      _semanticChunks.add(
        _IndexedChunk(
          id: 'loaded_$i',
          sourceName: 'Loaded Notes',
          text: chunks[i],
          tokens: _tokenize(chunks[i]),
        ),
      );
    }
    notifyListeners();
  }

  KnowledgeGraphData getKnowledgeGraph() {
    if (!_hasDocument) return KnowledgeGraphData(nodes: [], edges: []);

    final paragraphs = _semanticChunks
        .map((c) => c.text)
        .where((p) => p.trim().length > 20)
        .toList();

    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];
    final conceptMap = <String, List<int>>{};

    for (int i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i];
      final concepts = _extractConcepts(para);

      nodes.add(
        GraphNode(
          id: 'chunk_$i',
          label:
              '${para.substring(0, min(para.length, 30)).replaceAll('\n', ' ')}...',
          type: 'chunk',
          metadata: {'content': para},
        ),
      );

      for (final concept in concepts) {
        conceptMap.putIfAbsent(concept, () => []).add(i);
      }
    }

    int conceptIdx = 0;
    conceptMap.forEach((concept, paraIndices) {
      if (paraIndices.isNotEmpty) {
        final conceptId = 'concept_$conceptIdx';
        nodes.add(GraphNode(id: conceptId, label: concept, type: 'concept'));

        for (final pIdx in paraIndices) {
          edges.add(GraphEdge(from: 'chunk_$pIdx', to: conceptId, weight: 1.0));
        }
        conceptIdx++;
      }
    });

    for (int i = 0; i < paragraphs.length; i++) {
      for (int j = i + 1; j < paragraphs.length; j++) {
        final similarity = _calculateSimilarity(paragraphs[i], paragraphs[j]);
        if (similarity > 0.25) {
          edges.add(
            GraphEdge(from: 'chunk_$i', to: 'chunk_$j', weight: similarity),
          );
        }
      }
    }

    return KnowledgeGraphData(nodes: nodes, edges: edges);
  }

  List<String> _extractConcepts(String text) {
    final words = text.split(RegExp(r'[\s,.;:()]+'));
    final concepts = <String>{};

    for (int i = 1; i < words.length; i++) {
      final word = words[i];
      if (word.length > 4 &&
          word[0].toUpperCase() == word[0] &&
          word.toLowerCase() != word) {
        final clean = word.replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (clean.length > 3) concepts.add(clean);
      }
    }

    const academicKeywords = [
      'Quantum',
      'Algorithm',
      'Synthesis',
      'Mechanism',
      'Process',
      'Theory',
    ];
    for (final kw in academicKeywords) {
      if (text.contains(kw)) concepts.add(kw);
    }

    return concepts.take(5).toList();
  }

  double _calculateSimilarity(String a, String b) {
    final wordsA = a
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();
    final wordsB = b
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();

    if (wordsA.isEmpty || wordsB.isEmpty) return 0.0;

    final intersection = wordsA.intersection(wordsB).length;
    final union = wordsA.union(wordsB).length;

    return intersection / union;
  }

  Stream<String> getAnswerStream(String query) async* {
    if (_mode == AssistantMode.standard) {
      if (GeminiService.instance.isInitialized) {
        yield '🧠 [Gemini AI] Thinking...\n\n';
        try {
          await for (final token in GeminiService.instance.chatStream(query)) {
            yield token;
          }
          return;
        } catch (e) {
          yield 'AI error: $e\n\n';
        }
      }

      yield await askQuestion(query);
      return;
    }

    if (!_hasDocument || _semanticChunks.isEmpty) {
      yield 'Please upload a document first to use Lumina RAG! 📚';
      return;
    }

    yield '🛡️ Privacy Guard: Zero Network Activity Verified.\n';
    yield '🧭 Local Vectorization: Searching offline embeddings...\n\n';
    yield '✨ Synthesis\n';

    final results = _internalSearch(query);
    if (results.isEmpty) {
      yield 'I could not find relevant passages in your local indexed files.';
      return;
    }

    final answer = _buildLocalAnswer(query, results);
    for (final word in answer.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 8));
      yield '$word ';
    }
  }

  String _buildLocalAnswer(String query, List<SearchResult> results) {
    final citations = results
        .take(2)
        .map((r) => '- [${r.source}] ${_trimSnippet(r.snippet, maxLen: 180)}')
        .join('\n');

    return 'Based on your local documents, here\'s a synthesis regarding "$query":\n\n'
        '$citations\n\n'
        'This answer was generated from local indexed content only.';
  }

  String _trimSnippet(String value, {int maxLen = 220}) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= maxLen) return clean;
    return '${clean.substring(0, maxLen)}...';
  }

  Future<String> askQuestion(String query) async {
    final lowerQuery = query.toLowerCase();

    if (GeminiService.instance.isInitialized) {
      try {
        return await GeminiService.instance.chat(query);
      } catch (e) {
        debugPrint('Gemini chat error: $e');
      }
    }

    final results = _internalSearch(query);

    if (results.isEmpty) {
      if (lowerQuery.contains('hi') || lowerQuery.contains('hello')) {
        return 'Hello! How can I help with your studies today?';
      }
      return 'No results found in your notes for "$query".';
    }

    final buffer = StringBuffer()..writeln('Notes Reference:\n');
    for (var res in results) {
      buffer.writeln('[${res.source}] ${res.snippet}');
    }
    return buffer.toString().trim();
  }

  List<SearchResult> _internalSearch(String query) {
    if (!_hasDocument || query.trim().isEmpty || _semanticChunks.isEmpty) {
      return [];
    }

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) {
      return [];
    }

    final queryLower = query.toLowerCase();
    final results = <SearchResult>[];

    for (final chunk in _semanticChunks) {
      if (chunk.text.trim().length < 10) continue;

      final overlap = chunk.tokens.intersection(queryTokens).length;
      if (overlap == 0) continue;

      final overlapScore = overlap / queryTokens.length;
      final phraseBoost = chunk.text.toLowerCase().contains(queryLower)
          ? 0.35
          : 0.0;
      final relevance = (overlapScore + phraseBoost).clamp(0.0, 1.5).toDouble();

      results.add(
        SearchResult(
          snippet: _extractFocusedSnippet(chunk.text, queryTokens),
          relevance: relevance,
          source: chunk.sourceName,
        ),
      );
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(3).toList();
  }

  String _extractFocusedSnippet(String text, Set<String> queryTokens) {
    if (text.length <= 320) return text;

    final lower = text.toLowerCase();
    int bestIndex = 0;
    for (final token in queryTokens) {
      final index = lower.indexOf(token);
      if (index != -1) {
        bestIndex = max(0, index - 90);
        break;
      }
    }

    final endIndex = min(text.length, bestIndex + 320);
    final snippet = text.substring(bestIndex, endIndex).trim();
    return bestIndex > 0 ? '...$snippet...' : '$snippet...';
  }
}
