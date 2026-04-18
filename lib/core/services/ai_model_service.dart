import 'package:flutter/foundation.dart';

enum AIModelType {
  llm('Lumina LLM', 'Local Large Language Model for text generation'),
  tts('Text-to-Speech', 'Offline high-quality voice synthesis'),
  stt('Speech-to-Text', 'Local real-time speech recognition'),
  srl('SRL Model', 'Semantic Role Labeling for deep text analysis');

  final String label;
  final String description;
  const AIModelType(this.label, this.description);
}

class AIModelStatus {
  final bool isDownloaded;
  final bool isDownloading;
  final double progress;

  AIModelStatus({
    this.isDownloaded = false,
    this.isDownloading = false,
    this.progress = 0.0,
  });

  AIModelStatus copyWith({
    bool? isDownloaded,
    bool? isDownloading,
    double? progress,
  }) {
    return AIModelStatus(
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
    );
  }
}

class AIModelService extends ChangeNotifier {
  final Map<AIModelType, AIModelStatus> _modelStatuses = {
    for (var type in AIModelType.values) type: AIModelStatus(),
  };

  Map<AIModelType, AIModelStatus> get modelStatuses => _modelStatuses;

  bool isDownloaded(AIModelType type) => _modelStatuses[type]?.isDownloaded ?? false;
  bool isDownloading(AIModelType type) => _modelStatuses[type]?.isDownloading ?? false;
  double getProgress(AIModelType type) => _modelStatuses[type]?.progress ?? 0.0;

  Future<void> downloadModel(AIModelType type) async {
    if (isDownloaded(type) || isDownloading(type)) return;

    _modelStatuses[type] = _modelStatuses[type]!.copyWith(isDownloading: true, progress: 0.0);
    notifyListeners();

    // Simulate download
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      _modelStatuses[type] = _modelStatuses[type]!.copyWith(progress: i / 10);
      notifyListeners();
    }

    _modelStatuses[type] = _modelStatuses[type]!.copyWith(
      isDownloading: false,
      isDownloaded: true,
      progress: 1.0,
    );
    notifyListeners();
  }

  Future<void> deleteModel(AIModelType type) async {
    _modelStatuses[type] = AIModelStatus();
    notifyListeners();
  }

  // AI Functionalities (Mocked for now)
  Future<String> generateText(String prompt) async {
    if (!isDownloaded(AIModelType.llm)) return "Model not downloaded.";
    await Future.delayed(const Duration(seconds: 1));
    return "Synthesized response for: $prompt";
  }

  Future<void> speak(String text) async {
    if (!isDownloaded(AIModelType.tts)) return;
    debugPrint("Speaking: $text");
    // Mock TTS
  }

  Future<String> listen() async {
    if (!isDownloaded(AIModelType.stt)) return "Model not downloaded.";
    await Future.delayed(const Duration(seconds: 2));
    return "Recognized speech text";
  }
}
