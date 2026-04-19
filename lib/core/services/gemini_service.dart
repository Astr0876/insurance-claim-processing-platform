import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Drop-in replacement for RunAnywhere's AI features using Gemini API.
/// Works on ALL platforms (iOS, Android, web, desktop) with zero native deps.
class GeminiService {
  static GeminiService? _instance;
  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;

  GeminiService._();
  
  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;

  /// Initialize with Gemini API key from .env
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('⚠️ GEMINI_API_KEY not set in .env — AI features disabled');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        systemInstruction: Content.text(
          'You are Lumina, a proactive AI study sidekick for college students. '
          'You help with study planning, note comprehension, attendance tracking advice, '
          'and general academic questions. Keep answers helpful, concise, and encouraging. '
          'Use emojis sparingly but effectively. Format responses in markdown when helpful.'
        ),
        generationConfig: GenerationConfig(
          maxOutputTokens: 1024,
          temperature: 0.7,
        ),
      );
      
      _chat = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ Gemini AI initialized successfully');
    } catch (e) {
      debugPrint('❌ Gemini init error: $e');
    }
  }

  /// Generate a one-shot text response
  Future<String> generateText(String prompt) async {
    if (!_isInitialized || _model == null) {
      return "AI not initialized. Add GEMINI_API_KEY to your .env file.";
    }

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? "No response generated.";
    } catch (e) {
      return "AI Error: $e";
    }
  }

  /// Stream text response token-by-token
  Stream<String> generateTextStream(String prompt) async* {
    if (!_isInitialized || _model == null) {
      yield "AI not initialized. Add GEMINI_API_KEY to your .env file.";
      return;
    }

    try {
      final response = _model!.generateContentStream([Content.text(prompt)]);
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) yield text;
      }
    } catch (e) {
      yield "AI Error: $e";
    }
  }

  /// Chat with context (remembers conversation)
  Future<String> chat(String message) async {
    if (!_isInitialized || _chat == null) {
      return "AI not initialized. Add GEMINI_API_KEY to your .env file.";
    }

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? "No response.";
    } catch (e) {
      return "Chat Error: $e";
    }
  }

  /// Stream chat response
  Stream<String> chatStream(String message) async* {
    if (!_isInitialized || _chat == null) {
      yield "AI not initialized. Add GEMINI_API_KEY to your .env file.";
      return;
    }

    try {
      final response = _chat!.sendMessageStream(Content.text(message));
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) yield text;
      }
    } catch (e) {
      yield "Chat Error: $e";
    }
  }

  /// Reset chat history
  void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  /// Summarize study notes
  Future<String> summarizeNotes(String content) async {
    return generateText(
      'Summarize the following study notes into key bullet points. '
      'Highlight the most important concepts:\n\n$content'
    );
  }

  /// Generate quiz questions from content
  Future<String> generateQuiz(String content) async {
    return generateText(
      'Create 5 multiple-choice quiz questions from these study notes. '
      'Include answers at the end:\n\n$content'
    );
  }

  /// Get study advice based on attendance
  Future<String> getAttendanceAdvice({
    required double percentage,
    required int safeBunks,
    required int classesToRecover,
  }) async {
    return generateText(
      'My attendance is $percentage%. I can safely skip $safeBunks more classes. '
      'I need to attend $classesToRecover classes to recover. '
      'Give me brief, actionable attendance advice.'
    );
  }
}
