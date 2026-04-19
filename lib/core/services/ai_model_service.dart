import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

enum AIModelType {
  llm('Lumina LLM', 'Local Large Language Model (SmolLM2-360M)'),
  stt('Speech-to-Text', 'Whisper Tiny English'),
  tts('Text-to-Speech', 'Piper US English (Lessac)'),
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
  final Map<AIModelType, String> _modelIds = {
    AIModelType.llm: 'smollm2-360m-q8_0',
    AIModelType.stt: 'sherpa-onnx-whisper-tiny.en',
    AIModelType.tts: 'vits-piper-en_US-lessac-medium',
    AIModelType.srl: 'srl-model-default',
  };

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
    try {
      await RunAnywhere.initialize();
      _isInitialized = true;

      await LlamaCpp.register();
      await Onnx.register();

      // Register Models
      LlamaCpp.addModel(
        id: _modelIds[AIModelType.llm]!,
        name: 'SmolLM2 360M Q8_0',
        url: 'https://huggingface.co/prithivMLmods/SmolLM2-360M-GGUF/resolve/main/SmolLM2-360M.Q8_0.gguf',
        memoryRequirement: 500000000,
      );

      Onnx.addModel(
        id: _modelIds[AIModelType.stt]!,
        name: 'Whisper Tiny English',
        url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/sherpa-onnx-whisper-tiny.en.tar.gz',
        modality: ModelCategory.speechRecognition,
      );

      Onnx.addModel(
        id: _modelIds[AIModelType.tts]!,
        name: 'Piper US English (Lessac)',
        url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/vits-piper-en_US-lessac-medium.tar.gz',
        modality: ModelCategory.speechSynthesis,
      );

      // SRL Model registration
      Onnx.addModel(
        id: _modelIds[AIModelType.srl]!,
        name: 'SRL Model',
        url: 'https://github.com/RunanywhereAI/models/releases/download/v1/srl-model.tar.gz',
        modality: ModelCategory.speechRecognition,
      );

      _isInitialized = true;
      await _checkExistingModels();
      notifyListeners();
    } catch (e) {
      debugPrint('RunAnywhere Init Error: $e');
    }
  }

  Future<void> _checkExistingModels() async {
    final available = await RunAnywhere.availableModels();
    for (var type in AIModelType.values) {
      final id = _modelIds[type];
      try {
        final model = available.firstWhere((m) => m.id == id);
        _modelStatuses[type] = _modelStatuses[type]!.copyWith(
          isDownloaded: model.isDownloaded,
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> downloadModel(AIModelType type) async {
    final id = _modelIds[type]!;
    
    _modelStatuses[type] = _modelStatuses[type]!.copyWith(isDownloading: true, progress: 0.0);
    notifyListeners();

    try {
      await for (final progress in RunAnywhere.downloadModel(id)) {
        _modelStatuses[type] = _modelStatuses[type]!.copyWith(progress: progress.percentage);
        notifyListeners();
        if (progress.state.isCompleted) break;
      }

      _modelStatuses[type] = _modelStatuses[type]!.copyWith(
        isDownloading: false,
        isDownloaded: true,
        progress: 1.0,
      );
    } catch (e) {
      _modelStatuses[type] = _modelStatuses[type]!.copyWith(isDownloading: false);
      debugPrint('Download Error for $type: $e');
    }
    notifyListeners();
  }

  Future<void> loadModel(AIModelType type) async {
    if (!_isInitialized) {
      debugPrint('SDK not initialized for loading $type');
      return;
    }
    final id = _modelIds[type]!;
    try {
      if (type == AIModelType.stt) {
        await RunAnywhere.loadSTTModel(id);
      } else if (type == AIModelType.tts) {
        await RunAnywhere.loadTTSVoice(id);
      } else {
        await RunAnywhere.loadModel(id);
      }
      _modelStatuses[type] = _modelStatuses[type]!.copyWith(isLoaded: true);
      notifyListeners();
    } catch (e) {
      debugPrint('Load Error for $type: $id - $e');
    }
  }

  Future<void> deleteModel(AIModelType type) async {
    // deleteModel is not supported via static RunAnywhere.
    // We just reset the local status.
    _modelStatuses[type] = AIModelStatus();
    notifyListeners();
  }

  // AI Functionalities
  Future<String> generateText(String prompt) async {
    if (!_isInitialized) return "SDK not initialized.";
    final type = AIModelType.llm;
    if (!_modelStatuses[type]!.isDownloaded) return "Model not downloaded.";
    if (!_modelStatuses[type]!.isLoaded) await loadModel(type);

    try {
      final result = await RunAnywhere.generate(
        prompt,
        options: LLMGenerationOptions(maxTokens: 500),
      );
      return result.text;
    } catch (e) {
      return "Generation Error: $e";
    }
  }

  Stream<String> generateTextStream(String prompt) async* {
    if (!_isInitialized) {
      yield "SDK not initialized.";
      return;
    }
    final type = AIModelType.llm;
    if (!_modelStatuses[type]!.isDownloaded) {
      yield "Model not downloaded.";
      return;
    }
    if (!_modelStatuses[type]!.isLoaded) await loadModel(type);

    try {
      final streamResult = await RunAnywhere.generateStream(
        prompt,
        options: LLMGenerationOptions(maxTokens: 500),
      );
      yield* streamResult.stream;
    } catch (e) {
      yield "Streaming Error: $e";
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) return;
    final type = AIModelType.tts;
    if (!_modelStatuses[type]!.isDownloaded) return;
    if (!_modelStatuses[type]!.isLoaded) await loadModel(type);

    try {
      final result = await RunAnywhere.synthesize(text);
      final bytes = _convertToWav(result.samples, result.sampleRate);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Future<String> listen() async {
    if (!_isInitialized) return "SDK not initialized.";
    final type = AIModelType.stt;
    if (!_modelStatuses[type]!.isDownloaded) return "Model not downloaded.";
    if (!_modelStatuses[type]!.isLoaded) await loadModel(type);

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

      // Wait for user to speak or manual stop
      // For simplicity in this tool, we'll record for 3 seconds
      await Future.delayed(const Duration(seconds: 4));
      
      final recordingPath = await _recorder.stop();
      if (recordingPath == null) return "Recording failed";

      final audioBytes = await File(recordingPath).readAsBytes();
      final text = await RunAnywhere.transcribe(audioBytes);
      return text;
    } catch (e) {
      return "STT Error: $e";
    }
  }

  Uint8List _convertToWav(Float32List samples, int sampleRate) {
    final int16Samples = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i];
      if (sample.isNaN || sample.isInfinite) {
        int16Samples[i] = 0;
      } else {
        int16Samples[i] = (sample * 32767).toInt().clamp(-32768, 32767);
      }
    }

    final dataSize = int16Samples.length * 2;
    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big);   // "RIFF"
    header.setUint32(4, 36 + dataSize, Endian.little);
    header.setUint32(8, 0x57415645, Endian.big);   // "WAVE"
    header.setUint32(12, 0x666d7420, Endian.big);  // "fmt "
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);         // PCM
    header.setUint16(22, 1, Endian.little);         // Mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint32(36, 0x64617461, Endian.big);  // "data"
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = Uint8List(44 + dataSize);
    wavBytes.setAll(0, header.buffer.asUint8List());
    wavBytes.setAll(44, int16Samples.buffer.asUint8List());
    return wavBytes;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }
}
