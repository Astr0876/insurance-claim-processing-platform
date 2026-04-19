import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'gemini_service.dart';

enum AIModelType {
  llm('Lumina LLM', 'Gemini 2.0 Flash (Cloud)'),
  stt('Speech-to-Text', 'Platform STT'),
  tts('Text-to-Speech', 'Platform TTS'),
  srl('SRL Model', 'Semantic Role Labeling Model');

  final String label;
  final String description;
  const AIModelType(this.label, this.description);
}

class AIModelStatus {
  final bool isDownloaded;
  final bool isDownloading;
  final bool isLoaded;
  final double progress;

  AIModelStatus({
    this.isDownloaded = false,
    this.isDownloading = false,
    this.isLoaded = false,
    this.progress = 0.0,
  });

  AIModelStatus copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    bool? isLoaded,
    double? progress,
  }) {
    return AIModelStatus(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      isLoaded: isLoaded ?? this.isLoaded,
      progress: progress ?? this.progress,
    );
  }
}

class AIModelService extends ChangeNotifier {
  final Map<AIModelType, AIModelStatus> _modelStatuses = {
    for (var type in AIModelType.values) type: AIModelStatus(),
  };

  Map<AIModelType, AIModelStatus> get modelStatuses => _modelStatuses;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isInitialized = false;

  AIModelService() {
    _initSDK();
  }

  Future<void> _initSDK() async {
    if (_isInitialized) return;
    
    // Gemini is cloud-based, so it's always "ready" if API key is set
    if (GeminiService.instance.isInitialized) {
      _isInitialized = true;
      _modelStatuses[AIModelType.llm] = AIModelStatus(
        isDownloaded: true,
        isLoaded: true,
        progress: 1.0,
      );
      notifyListeners();
    }
  }

  Future<void> downloadModel(AIModelType type) async {
    // Gemini is cloud-based, no download needed
    _modelStatuses[type] = _modelStatuses[type]!.copyWith(
      isDownloading: true,
      progress: 0.0,
    );
    notifyListeners();

    // Simulate quick "download" for UI feedback
    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      _modelStatuses[type] = _modelStatuses[type]!.copyWith(
        progress: i / 5,
      );
      notifyListeners();
    }

    _modelStatuses[type] = _modelStatuses[type]!.copyWith(
      isDownloading: false,
      isDownloaded: true,
      isLoaded: true,
      progress: 1.0,
    );
    notifyListeners();
  }

  Future<void> loadModel(AIModelType type) async {
    _modelStatuses[type] = _modelStatuses[type]!.copyWith(isLoaded: true);
    notifyListeners();
  }

  Future<void> deleteModel(AIModelType type) async {
    _modelStatuses[type] = AIModelStatus();
    notifyListeners();
  }

  // AI Functionalities — powered by Gemini
  Future<String> generateText(String prompt) async {
    return GeminiService.instance.generateText(prompt);
  }

  Stream<String> generateTextStream(String prompt) {
    return GeminiService.instance.generateTextStream(prompt);
  }

  Future<void> speak(String text) async {
    // Using flutter_tts for text-to-speech (platform native)
    try {
      // For now, just log — flutter_tts is imported in the widget layer
      debugPrint('TTS: $text');
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Future<String> listen() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      
      if (!await _recorder.hasPermission()) return "Permission denied";

      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/recording.pcm';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      // Record for 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      
      final recordingPath = await _recorder.stop();
      if (recordingPath == null) return "Recording failed";

      // Use Gemini to process the intent (since we don't have on-device STT)
      return "Voice recording captured. Use the text input for now.";
    } catch (e) {
      return "STT Error: $e";
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }
}
