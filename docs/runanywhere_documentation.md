Flutter SDK
Installation
Install the RunAnywhere Flutter SDK
​
Packages on pub.dev

The RunAnywhere Flutter SDK consists of three packages:
Package	Description	pub.dev
runanywhere	Core SDK with APIs and infrastructure	pub package
runanywhere_llamacpp	LLM text generation (GGUF models)	pub package
runanywhere_onnx	STT, TTS, VAD (ONNX models)	pub package
​
Add Dependencies

Add the packages you need to your pubspec.yaml:
LLM Only
STT/TTS Only
All Features
Add these dependencies to pubspec.yaml:
dependencies:
  runanywhere: ^0.16.0
  runanywhere_llamacpp: ^0.16.0
Then run:
flutter pub get
​
iOS Setup (Required)

After adding the packages, update your iOS configuration:
​
1. Update Podfile

Open ios/Podfile and update:
ios/Podfile
# Set minimum iOS version to 14.0
platform :ios, '14.0'

target 'Runner' do
  # REQUIRED: Add static linkage
  use_frameworks! :linkage => :static

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      # Required for microphone and speech recognition permissions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_SPEECH_RECOGNIZER=1',
      ]
    end
  end
end
Without use_frameworks! :linkage => :static, you will encounter “symbol not found” errors at runtime.
​
2. Add Microphone Permission

Add to ios/Runner/Info.plist (for STT/Voice features):
ios/Runner/Info.plist
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for speech recognition and voice commands.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses on-device speech recognition to transcribe your voice.</string>
​
3. Install Pods

cd ios && pod install && cd ..
​
Android Setup

Add required permissions to android/app/src/main/AndroidManifest.xml:
android/app/src/main/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
Also set android:usesCleartextTraffic="true" on the <application> tag if your app downloads models over HTTP or uses HTTP APIs (e.g., weather).
​
Android Build Configuration

The recommended Gradle configuration for optimal performance:
android/gradle.properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m
The higher JVM memory allocation (-Xmx8G) may be needed for native SDK compilation. Android requires Java 17 compatibility.
​
Verify Installation

Run your app to verify everything is set up correctly:
flutter run
​
Starter Example

Want to see a complete working example? Check out our official Flutter starter app:
Flutter Starter Example
Clone and run a complete example app with LLM, STT, TTS, and Voice Agent
git clone https://github.com/RunanywhereAI/flutter-starter-example.git
cd flutter-starter-example
flutter pub get
flutter run






Flutter SDK
Quick Start
Build your first AI feature in 5 minutes
Want a complete working app? Clone our Flutter Starter Example to get started immediately with a full-featured demo app.
​
Complete Example

Here’s a complete example to get you started with on-device text generation:
import 'package:flutter/material.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SDK
  await RunAnywhere.initialize();

  // 2. Register LlamaCpp backend
  await LlamaCpp.register();

  // 3. Add a model
  LlamaCpp.addModel(
    id: 'smollm2-360m-q8_0',
    name: 'SmolLM2 360M Q8_0',
    url: 'https://huggingface.co/prithivMLmods/SmolLM2-360M-GGUF/resolve/main/SmolLM2-360M.Q8_0.gguf',
    memoryRequirement: 500000000,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String _response = '';
  bool _isLoading = false;
  bool _isModelLoaded = false;

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);

    try {
      // Download model (with progress)
      await for (final progress in RunAnywhere.downloadModel('smollm2-360m-q8_0')) {
        print('Download: ${(progress.percentage * 100).toStringAsFixed(1)}%');
        if (progress.state.isCompleted) break;
      }

      // Load model
      await RunAnywhere.loadModel('smollm2-360m-q8_0');
      setState(() => _isModelLoaded = true);
    } catch (e) {
      setState(() => _response = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateText() async {
    setState(() => _isLoading = true);

    try {
      final result = await RunAnywhere.generate(
        'Explain quantum computing in simple terms',
        options: LLMGenerationOptions(
          maxTokens: 200,
          temperature: 0.7,
        ),
      );

      setState(() => _response = result.text);
      print('Speed: ${result.tokensPerSecond.toStringAsFixed(1)} tok/s');
    } catch (e) {
      setState(() => _response = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('RunAnywhere Demo')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (!_isModelLoaded)
              ElevatedButton(
                onPressed: _isLoading ? null : _loadModel,
                child: Text(_isLoading ? 'Loading...' : 'Download & Load Model'),
              ),
            if (_isModelLoaded)
              ElevatedButton(
                onPressed: _isLoading ? null : _generateText,
                child: Text(_isLoading ? 'Generating...' : 'Generate'),
              ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_response),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
​
Step-by-Step Breakdown

​
1. Initialize the SDK

await RunAnywhere.initialize();
Initialize once at app startup. Development mode requires no API key.
​
2. Register Backend Modules

await LlamaCpp.register();  // For LLM
await Onnx.register();      // For STT/TTS (optional)
Register the backends you need. Each backend is a separate package.
​
3. Register Models

LlamaCpp.addModel(
  id: 'smollm2-360m-q8_0',
  name: 'SmolLM2 360M Q8_0',
  url: 'https://huggingface.co/.../SmolLM2-360M.Q8_0.gguf',
  memoryRequirement: 500000000,
);
Register models with their download URLs. Models are downloaded on-demand.
​
4. Download & Load Models

// Download with progress tracking
await for (final progress in RunAnywhere.downloadModel('smollm2-360m-q8_0')) {
  print('${(progress.percentage * 100).toStringAsFixed(1)}%');
  if (progress.state.isCompleted) break;
}

// Load into memory
await RunAnywhere.loadModel('smollm2-360m-q8_0');
​
5. Generate Text

// Simple chat
final response = await RunAnywhere.chat('Hello!');

// Full generation with metrics
final result = await RunAnywhere.generate(
  'Your prompt here',
  options: LLMGenerationOptions(maxTokens: 200),
);
print('Response: ${result.text}');
print('Speed: ${result.tokensPerSecond} tok/s');
​
Environment Options

Environment	Description	API Key Required
.development	Verbose logging, local-only	No
.staging	Testing with real services	Yes
.production	Minimal logging, telemetry	Yes
// Production initialization
await RunAnywhere.initialize(
  apiKey: 'your-api-key',
  baseURL: 'https://api.runanywhere.ai',
  environment: SDKEnvironment.production,
);
​
Starter Example Repository

For a complete working application with all features demonstrated, clone our starter example:
git clone https://github.com/RunanywhereAI/flutter-starter-example.git
cd flutter-starter-example
flutter pub get
cd ios && pod install && cd ..
flutter run
The Flutter Starter Example includes:
AI Chat with streaming responses
Speech-to-Text transcription
Text-to-Speech synthesis
Voice Assistant pipeline
Model download and management UI







LLM (Language Models)
chat()
Simple one-liner for quick text responses
The simplest way to generate text—returns just the response string.
// One-liner for quick responses
final response = await RunAnywhere.chat('What is the capital of France?');
print(response);  // "The capital of France is Paris."
​
When to Use

Use chat() when you:
Need a quick response without metrics
Don’t need streaming
Want the simplest possible API
​
Requirements

Before calling chat(), ensure:
SDK is initialized: await RunAnywhere.initialize()
Backend is registered: await LlamaCpp.register()
Model is loaded: await RunAnywhere.loadModel('model-id')
​
Example with Error Handling

Future<String> askQuestion(String question) async {
  try {
    if (!RunAnywhere.isModelLoaded) {
      throw SDKError.componentNotReady('No model loaded');
    }
    return await RunAnywhere.chat(question);
  } on SDKError catch (e) {
    return 'Error: ${e.message}';
  }
}





LLM (Language Models)
generate()
Full text generation with performance metrics
Generate text with detailed metrics including latency, token count, and generation speed.
final result = await RunAnywhere.generate(
  'Explain quantum computing in simple terms',
  options: LLMGenerationOptions(
    maxTokens: 200,
    temperature: 0.7,
  ),
);

print('Response: ${result.text}');
print('Tokens: ${result.tokensUsed}');
print('Speed: ${result.tokensPerSecond.toStringAsFixed(1)} tok/s');
print('Latency: ${result.latencyMs.toStringAsFixed(0)}ms');
​
LLMGenerationOptions

Parameter	Type	Default	Description
maxTokens	int	100	Maximum tokens to generate
temperature	double	0.8	Randomness (0.0–2.0)
topP	double	1.0	Nucleus sampling parameter
stopSequences	List<String>	[]	Stop generation at these
systemPrompt	String?	null	System prompt for context
const options = LLMGenerationOptions(
  maxTokens: 256,
  temperature: 0.7,
  topP: 0.95,
  stopSequences: ['END', '###'],
  systemPrompt: 'You are a helpful coding assistant.',
);
​
LLMGenerationResult

Property	Type	Description
text	String	Generated text
thinkingContent	String?	Thinking content (if supported)
inputTokens	int	Number of input tokens
tokensUsed	int	Number of output tokens
modelUsed	String	Model ID used
latencyMs	double	Total latency in milliseconds
tokensPerSecond	double	Generation speed
timeToFirstTokenMs	double?	Time to first token
​
Thinking Models

Some models support “thinking” tokens for chain-of-thought reasoning:
LlamaCpp.addModel(
  id: 'qwen-cot',
  name: 'Qwen CoT',
  url: '...',
  supportsThinking: true,  // Enable thinking token parsing
);

final result = await RunAnywhere.generate('Solve: 2x + 5 = 15');

if (result.thinkingContent != null) {
  print('Reasoning: ${result.thinkingContent}');
}
print('Answer: ${result.text}');





LLM (Language Models)
generateStream()
Stream tokens as they are generated for responsive UX
Stream tokens in real-time for a responsive user experience. Ideal for chat interfaces where users expect to see text appear progressively.
final streamResult = await RunAnywhere.generateStream(
  'Tell me a story about a robot',
  options: LLMGenerationOptions(maxTokens: 500),
);

// Display tokens as they arrive
await for (final token in streamResult.stream) {
  stdout.write(token);  // Real-time output
  // Or update UI: setState(() => _response += token);
}

// Get final metrics after streaming completes
final metrics = await streamResult.result;
print('\n\nGenerated ${metrics.tokensUsed} tokens');
print('Speed: ${metrics.tokensPerSecond.toStringAsFixed(1)} tok/s');
​
LLMStreamingResult

Property	Type	Description
stream	Stream<String>	Stream of tokens
result	Future<LLMGenerationResult>	Final result with metrics
cancel	void Function()	Cancel generation
​
Flutter Widget Example

class StreamingChatWidget extends StatefulWidget {
  @override
  _StreamingChatWidgetState createState() => _StreamingChatWidgetState();
}

class _StreamingChatWidgetState extends State<StreamingChatWidget> {
  String _response = '';
  bool _isStreaming = false;
  LLMStreamingResult? _currentStream;

  Future<void> _startStreaming(String prompt) async {
    setState(() {
      _response = '';
      _isStreaming = true;
    });

    try {
      _currentStream = await RunAnywhere.generateStream(
        prompt,
        options: LLMGenerationOptions(maxTokens: 300),
      );

      await for (final token in _currentStream!.stream) {
        setState(() => _response += token);
      }

      final metrics = await _currentStream!.result;
      print('Generated at ${metrics.tokensPerSecond.toStringAsFixed(1)} tok/s');
    } finally {
      setState(() => _isStreaming = false);
    }
  }

  void _cancelStreaming() {
    _currentStream?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Text(_response),
          ),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: _isStreaming ? null : () => _startStreaming('Tell me a joke'),
              child: Text('Generate'),
            ),
            if (_isStreaming)
              TextButton(
                onPressed: _cancelStreaming,
                child: Text('Cancel'),
              ),
          ],
        ),
      ],
    );
  }
}
​
Cancellation

Cancel ongoing generation at any time:
final streamResult = await RunAnywhere.generateStream('Long story...');

// Start a timer to cancel after 5 seconds
Future.delayed(Duration(seconds: 5), () {
  streamResult.cancel();
  print('Generation cancelled');
});

// Or cancel via the static method
await RunAnywhere.cancelGeneration();
​
Best Practices

Use streaming for chat interfaces — Users perceive the app as more responsive when they see tokens appear progressively, even if total generation time is the same.
Update UI incrementally — Append tokens to your state as they arrive
Show a cancel button — Let users stop long generations
Handle cancellation gracefully — The stream will complete when cancelled
Get final metrics — Always await result for accurate performance data





LLM (Language Models)
System Prompts
Configure model behavior with system prompts
System prompts set the context and behavior for your AI model. Use them to create specialized assistants, enforce response formats, or constrain the model’s persona.
​
Basic Usage

final result = await RunAnywhere.generate(
  'Write a function to sort an array',
  options: LLMGenerationOptions(
    maxTokens: 300,
    systemPrompt: 'You are a helpful coding assistant. Write clean, well-commented code.',
  ),
);
​
Common Patterns

​
Coding Assistant

const codingPrompt = '''
You are an expert programmer. Follow these rules:
- Write clean, readable code with comments
- Use best practices and design patterns
- Explain your approach briefly before the code
- Handle edge cases
''';

final result = await RunAnywhere.generate(
  'Implement a binary search in Dart',
  options: LLMGenerationOptions(
    systemPrompt: codingPrompt,
    maxTokens: 400,
  ),
);
​
Customer Support Bot

const supportPrompt = '''
You are a friendly customer support agent for TechCorp.
- Be helpful and empathetic
- Keep responses concise (2-3 sentences)
- If you don't know something, say so
- Never make up information about products
''';
​
JSON Output

const jsonPrompt = '''
You are a data extraction assistant.
Always respond with valid JSON only, no additional text.
Extract the requested information into the specified format.
''';

final result = await RunAnywhere.generate(
  'Extract: "John Smith, 25 years old, engineer at Google"',
  options: LLMGenerationOptions(
    systemPrompt: jsonPrompt,
    maxTokens: 100,
    temperature: 0.1,  // Lower temperature for consistent format
  ),
);

// Parse the JSON response
final data = jsonDecode(result.text);
​
Character/Persona

const personaPrompt = '''
You are Captain Nova, a space explorer from the year 3000.
- Speak with enthusiasm about space and technology
- Reference your adventures across the galaxy
- Use occasional space-themed expressions
- Stay in character at all times
''';
​
Tips for Effective System Prompts

Be Specific
Use Examples
Set Boundaries
Keep It Concise
​
Reusable Prompt Class

Create a helper class for managing prompts:
class SystemPrompts {
  static const String coding = '''
You are an expert programmer. Write clean, well-documented code.
''';

  static const String creative = '''
You are a creative writing assistant. Be imaginative and engaging.
''';

  static String forDomain(String domain) => '''
You are an expert in $domain. Provide accurate, helpful information.
''';
}

// Usage
final result = await RunAnywhere.generate(
  prompt,
  options: LLMGenerationOptions(
    systemPrompt: SystemPrompts.coding,
  ),
);






STT (Speech-to-Text)
transcribe()
Convert audio to text with Whisper models
Transcribe audio data to text using on-device Whisper models via ONNX Runtime.
​
Basic Usage

// Load STT model first
await RunAnywhere.loadSTTModel('sherpa-onnx-whisper-tiny.en');

// Transcribe audio data (PCM16 at 16kHz mono)
final text = await RunAnywhere.transcribe(audioBytes);
print('Transcription: $text');
​
With Detailed Result

Get confidence scores and metadata with transcribeWithResult():
final result = await RunAnywhere.transcribeWithResult(audioBytes);

print('Text: ${result.text}');
print('Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
print('Duration: ${result.durationMs}ms');
if (result.language != null) {
  print('Language: ${result.language}');
}
​
STTResult

Property	Type	Description
text	String	Transcribed text
confidence	double	Confidence score (0.0 to 1.0)
durationMs	int	Audio duration in milliseconds
language	String?	Detected language code
​
Setup

​
1. Register ONNX Backend

import 'package:runanywhere_onnx/runanywhere_onnx.dart';

await Onnx.register();
​
2. Add STT Model

Onnx.addModel(
  id: 'sherpa-onnx-whisper-tiny.en',
  name: 'Whisper Tiny English',
  url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/sherpa-onnx-whisper-tiny.en.tar.gz',
  modality: ModelCategory.speechRecognition,
);
​
3. Download & Load

// Download
await for (final progress in RunAnywhere.downloadModel('sherpa-onnx-whisper-tiny.en')) {
  print('${(progress.percentage * 100).toStringAsFixed(1)}%');
  if (progress.state.isCompleted) break;
}

// Load
await RunAnywhere.loadSTTModel('sherpa-onnx-whisper-tiny.en');
​
Audio Format Requirements

Audio must be in the correct format for accurate transcription.
Property	Required Value
Format	PCM (raw audio)
Sample Rate	16,000 Hz (16kHz)
Channels	1 (mono)
Bit Depth	16-bit
​
Recording Audio

Use a package like record to capture audio:
import 'package:record/record.dart';

final recorder = AudioRecorder();

// Start recording with correct format
await recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
  ),
  path: tempFilePath,
);

// Stop and get audio
await recorder.stop();
final audioBytes = await File(tempFilePath).readAsBytes();

// Transcribe
final text = await RunAnywhere.transcribe(audioBytes);
​
Available Models

Model ID	Size	Languages	Speed
sherpa-onnx-whisper-tiny.en	~75MB	English	Fast
sherpa-onnx-whisper-base.en	~150MB	English	Medium
sherpa-onnx-whisper-small.en	~250MB	English	Slower
sherpa-onnx-whisper-tiny	~75MB	Multilingual	Fast
​
Complete Example

class TranscriptionDemo extends StatefulWidget {
  @override
  _TranscriptionDemoState createState() => _TranscriptionDemoState();
}

class _TranscriptionDemoState extends State<TranscriptionDemo> {
  final _recorder = AudioRecorder();
  String _transcription = '';
  bool _isRecording = false;
  bool _isTranscribing = false;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop and transcribe
      final path = await _recorder.stop();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _isTranscribing = true;
        });

        final audioBytes = await File(path).readAsBytes();
        final text = await RunAnywhere.transcribe(audioBytes);

        setState(() {
          _transcription = text;
          _isTranscribing = false;
        });
      }
    } else {
      // Start recording
      if (await _recorder.hasPermission()) {
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

        setState(() => _isRecording = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_transcription),
        ElevatedButton(
          onPressed: _isTranscribing ? null : _toggleRecording,
          child: Text(_isRecording ? 'Stop' : 'Record'),
        ),
        if (_isTranscribing) CircularProgressIndicator(),
      ],
    );
  }
}








STT (Speech-to-Text)
Streaming STT
Real-time speech transcription as you speak
Stream audio for real-time transcription as the user speaks. Ideal for voice assistants and live captioning.
​
Overview

Streaming STT processes audio in chunks, providing partial transcriptions that update as more audio arrives. This creates a responsive experience where users see their words appear in real-time.
​
Basic Usage

// Ensure STT model is loaded
await RunAnywhere.loadSTTModel('sherpa-onnx-whisper-tiny.en');

// Stream transcription results from audio chunks
await for (final result in RunAnywhere.transcribeStream(audioStream)) {
  print('Partial: ${result.text}');  // result.isFinal is true on last segment
}
​
With Voice Session

The easiest way to use streaming STT is through the Voice Agent, which handles VAD and audio capture automatically:
final session = await RunAnywhere.startVoiceSession();

session.events.listen((event) {
  if (event is VoiceSessionTranscribed) {
    print('Transcription: ${event.text}');
  }
});
See Voice Agent for the complete voice pipeline.
​
Real-Time Transcription Widget

class LiveTranscriptionWidget extends StatefulWidget {
  @override
  _LiveTranscriptionWidgetState createState() => _LiveTranscriptionWidgetState();
}

class _LiveTranscriptionWidgetState extends State<LiveTranscriptionWidget> {
  final _recorder = AudioRecorder();
  String _partialText = '';
  String _finalText = '';
  bool _isListening = false;
  StreamSubscription? _audioSubscription;

  Future<void> _startListening() async {
    if (!await _recorder.hasPermission()) return;

    setState(() {
      _isListening = true;
      _partialText = '';
    });

    // Start recording with streaming
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    // Process audio chunks
    _audioSubscription = stream.listen((chunk) async {
      // This would use your streaming transcription implementation
      // The exact API depends on how you've set up streaming
    });
  }

  Future<void> _stopListening() async {
    await _audioSubscription?.cancel();
    await _recorder.stop();

    setState(() {
      _isListening = false;
      _finalText = _partialText;
      _partialText = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show partial transcription with typing indicator
        Container(
          padding: EdgeInsets.all(16),
          child: Text(
            _isListening ? '$_partialText|' : _finalText,
            style: TextStyle(
              fontSize: 18,
              color: _isListening ? Colors.grey : Colors.black,
            ),
          ),
        ),

        // Recording button
        IconButton(
          icon: Icon(_isListening ? Icons.stop : Icons.mic),
          iconSize: 48,
          color: _isListening ? Colors.red : Colors.blue,
          onPressed: _isListening ? _stopListening : _startListening,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}







STT (Speech-to-Text)
STT Options
Configure speech-to-text behavior
Configure STT behavior for different use cases and languages.
​
Model Selection

Choose the right model based on your needs:
Model	Size	Languages	Quality	Speed	Use Case
whisper-tiny.en	~75MB	English	Good	Fastest	Quick commands
whisper-base.en	~150MB	English	Better	Fast	General use
whisper-small.en	~250MB	English	Best	Medium	Accuracy-critical
whisper-tiny	~75MB	Multi	Good	Fast	Multilingual apps
​
Register Multiple Models

// English-optimized for primary use
Onnx.addModel(
  id: 'whisper-tiny-en',
  name: 'Whisper Tiny English',
  url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/sherpa-onnx-whisper-tiny.en.tar.gz',
  modality: ModelCategory.speechRecognition,
);

// Multilingual for international users
Onnx.addModel(
  id: 'whisper-tiny-multi',
  name: 'Whisper Tiny Multilingual',
  url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/sherpa-onnx-whisper-tiny.tar.gz',
  modality: ModelCategory.speechRecognition,
);
​
Switch Models at Runtime

// Load English model by default
await RunAnywhere.loadSTTModel('whisper-tiny-en');

// Switch to multilingual when needed
Future<void> switchToMultilingual() async {
  await RunAnywhere.unloadSTTModel();
  await RunAnywhere.loadSTTModel('whisper-tiny-multi');
}
​
Memory Management

Unload STT model when not needed to free memory:
// Check if loaded
if (RunAnywhere.isSTTModelLoaded) {
  print('Current STT model: ${RunAnywhere.currentSTTModelId}');
}

// Unload to free memory
await RunAnywhere.unloadSTTModel();
​
Audio Preprocessing Tips

Sample Rate Conversion
Noise Reduction
Audio Format
​
Error Handling

try {
  final text = await RunAnywhere.transcribe(audioBytes);
  print('Transcribed: $text');
} on SDKError catch (e) {
  switch (e.type) {
    case SDKErrorType.sttNotAvailable:
      print('STT not available. Load an STT model first.');
      break;
    case SDKErrorType.componentNotReady:
      print('STT model not loaded.');
      break;
    default:
      print('STT error: ${e.message}');
  }
}
​
Best Practices

Start with the smallest model that meets your accuracy needs. You can always upgrade later if needed.
Preload during idle time — Download and load STT model before user needs it
Use English-specific models — They’re smaller and more accurate for English
Handle empty audio — Check audio length before transcribing
Provide feedback — Show transcription progress to users










TTS (Text-to-Speech)
synthesize()
Convert text to speech with neural voices
Synthesize natural-sounding speech from text using on-device Piper TTS models.
​
Basic Usage

// Load a TTS voice
await RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');

// Synthesize speech
final result = await RunAnywhere.synthesize(
  'Hello! Welcome to RunAnywhere.',
  rate: 1.0,
  pitch: 1.0,
);

// result.samples contains PCM Float32 audio
// result.sampleRate is typically 22050 Hz
print('Duration: ${result.durationSeconds}s');
​
TTSResult

Property	Type	Description
samples	Float32List	Audio samples (PCM float)
sampleRate	int	Sample rate in Hz (typically 22050)
durationMs	int	Duration in milliseconds
durationSeconds	double	Duration in seconds
numSamples	int	Number of audio samples
​
Parameters

Parameter	Type	Default	Description
rate	double	1.0	Speech rate (0.5 to 2.0)
pitch	double	1.0	Voice pitch (0.5 to 2.0)
volume	double	1.0	Volume (0.0 to 1.0)
// Slower, lower pitch for emphasis
final result = await RunAnywhere.synthesize(
  'Important announcement!',
  rate: 0.8,
  pitch: 0.9,
  volume: 1.0,
);
​
Setup

​
1. Register ONNX Backend

import 'package:runanywhere_onnx/runanywhere_onnx.dart';

await Onnx.register();
​
2. Add TTS Voice

Onnx.addModel(
  id: 'vits-piper-en_US-lessac-medium',
  name: 'Piper US English (Lessac)',
  url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/vits-piper-en_US-lessac-medium.tar.gz',
  modality: ModelCategory.speechSynthesis,
);
​
3. Download & Load

// Download
await for (final progress in RunAnywhere.downloadModel('vits-piper-en_US-lessac-medium')) {
  print('${(progress.percentage * 100).toStringAsFixed(1)}%');
  if (progress.state.isCompleted) break;
}

// Load
await RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');
​
Playing Audio

Use a package like audioplayers to play the synthesized audio:
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

Future<void> speakText(String text) async {
  final result = await RunAnywhere.synthesize(text);

  // Convert Float32 samples to bytes for playback
  final bytes = _convertToBytes(result.samples, result.sampleRate);

  // Play using audioplayers
  await player.play(BytesSource(bytes));
}

Uint8List _convertToBytes(Float32List samples, int sampleRate) {
  // Convert Float32 PCM to Int16 PCM
  final int16Samples = Int16List(samples.length);
  for (var i = 0; i < samples.length; i++) {
    int16Samples[i] = (samples[i] * 32767).clamp(-32768, 32767).toInt();
  }

  // Build WAV file: 44-byte header + PCM data
  final dataSize = int16Samples.length * 2;
  final header = ByteData(44);
  // RIFF header
  header.setUint32(0, 0x52494646, Endian.big);   // "RIFF"
  header.setUint32(4, 36 + dataSize, Endian.little);
  header.setUint32(8, 0x57415645, Endian.big);   // "WAVE"
  // fmt chunk
  header.setUint32(12, 0x666d7420, Endian.big);  // "fmt "
  header.setUint32(16, 16, Endian.little);        // chunk size
  header.setUint16(20, 1, Endian.little);         // PCM format
  header.setUint16(22, 1, Endian.little);         // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little);         // block align
  header.setUint16(34, 16, Endian.little);        // bits per sample
  // data chunk
  header.setUint32(36, 0x64617461, Endian.big);  // "data"
  header.setUint32(40, dataSize, Endian.little);

  final wavBytes = Uint8List(44 + dataSize);
  wavBytes.setAll(0, header.buffer.asUint8List());
  wavBytes.setAll(44, int16Samples.buffer.asUint8List());
  return wavBytes;
}
​
Complete Example

class TextToSpeechDemo extends StatefulWidget {
  @override
  _TextToSpeechDemoState createState() => _TextToSpeechDemoState();
}

class _TextToSpeechDemoState extends State<TextToSpeechDemo> {
  final _controller = TextEditingController();
  final _player = AudioPlayer();
  bool _isSpeaking = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }

  Future<void> _initTTS() async {
    // Download if needed
    final models = await RunAnywhere.availableModels();
    final ttsModel = models.firstWhere(
      (m) => m.id == 'vits-piper-en_US-lessac-medium',
    );

    if (!ttsModel.isDownloaded) {
      await for (final p in RunAnywhere.downloadModel(ttsModel.id)) {
        if (p.state.isCompleted) break;
      }
    }

    // Load voice
    await RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');
    setState(() => _isLoaded = true);
  }

  Future<void> _speak() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isSpeaking = true);

    try {
      final result = await RunAnywhere.synthesize(_controller.text);
      // Play audio (implementation depends on your audio setup)
      await _playAudio(result);
    } finally {
      setState(() => _isSpeaking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: 'Enter text to speak...',
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isLoaded && !_isSpeaking ? _speak : null,
          icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
          label: Text(_isSpeaking ? 'Speaking...' : 'Speak'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }
}









TTS (Text-to-Speech)
Streaming TTS
Stream audio for lower perceived latency
Stream TTS audio as it’s generated for faster time-to-first-audio, especially with longer text.
​
Overview

Streaming TTS starts playing audio before the entire synthesis is complete. This is particularly useful for:
Long text passages
Voice assistants responding in real-time
Reducing perceived latency
​
Basic Concept

// The Voice Agent pipeline handles streaming TTS automatically
final session = await RunAnywhere.startVoiceSession(
  config: VoiceSessionConfig(
    autoPlayTTS: true,  // Automatically plays synthesized audio
  ),
);

session.events.listen((event) {
  if (event is VoiceSessionSpeaking) {
    print('Playing audio response...');
  }
});
​
Chunked Synthesis

For manual control, synthesize text in chunks:
Future<void> speakInChunks(String longText) async {
  // Split into sentences
  final sentences = longText.split(RegExp(r'(?<=[.!?])\s+'));

  for (final sentence in sentences) {
    final result = await RunAnywhere.synthesize(sentence);
    await playAudio(result);
  }
}
​
With Voice Agent Pipeline

The Voice Agent provides the best streaming TTS experience:
// Initialize all components
await RunAnywhere.loadSTTModel('sherpa-onnx-whisper-tiny.en');
await RunAnywhere.loadModel('smollm2-360m-q8_0');
await RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');

// Start session with auto-play
final session = await RunAnywhere.startVoiceSession(
  config: VoiceSessionConfig(
    autoPlayTTS: true,
    continuousMode: true,
  ),
);

// The pipeline automatically:
// 1. Detects speech (VAD)
// 2. Transcribes audio (STT)
// 3. Generates response (LLM)
// 4. Synthesizes and plays audio (TTS)
session.events.listen((event) {
  switch (event) {
    case VoiceSessionTranscribed(:final text):
      print('User: $text');
    case VoiceSessionResponded(:final text):
      print('AI: $text');
    case VoiceSessionSpeaking():
      print('Playing response...');
    case VoiceSessionTurnCompleted():
      print('Ready for next turn');
    default:
      break;
  }
});


Latency Optimization Tips

Preload Voice Model
Load the TTS voice during app startup or idle time, not when the user first needs it.
// In app initialization
await RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');
Use Faster Voices
Smaller voice models synthesize faster. Choose based on your quality/speed tradeoff.
Sentence-Level Streaming
For very long responses, synthesize and play sentence by sentence rather than waiting for the complete response.
Buffer Management
Start playback as soon as you have enough audio buffered (typically 100-200ms).
​










TTS (Text-to-Speech)
Voices
Browse and select TTS voices
RunAnywhere supports neural TTS voices via Piper and system voice fallback via flutter_tts.
​
Piper Neural Voices

High-quality neural voices that run entirely on-device.
​
English (US)

Voice ID	Name	Gender	Style	Size
vits-piper-en_US-lessac-medium	Lessac	Male	Neutral	~50MB
vits-piper-en_US-amy-medium	Amy	Female	Neutral	~50MB
vits-piper-en_US-ryan-medium	Ryan	Male	Conversational	~50MB
vits-piper-en_US-kathleen-low	Kathleen	Female	Soft	~20MB
​
English (UK)

Voice ID	Name	Gender	Style	Size
vits-piper-en_GB-alan-medium	Alan	Male	British	~50MB
vits-piper-en_GB-alba-medium	Alba	Female	Scottish	~50MB
​
Other Languages

Voice ID	Language	Gender	Size
vits-piper-de_DE-thorsten-medium	German	Male	~50MB
vits-piper-fr_FR-upmc-medium	French	Male	~50MB
vits-piper-es_ES-sharvard-medium	Spanish	Male	~50MB
vits-piper-it_IT-riccardo-x_low	Italian	Male	~20MB
vits-piper-zh_CN-huayan-medium	Chinese	Female	~50MB
​
Registering Voices

// US English - Lessac (recommended default)
Onnx.addModel(
  id: 'vits-piper-en_US-lessac-medium',
  name: 'Piper US English (Lessac)',
  url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/vits-piper-en_US-lessac-medium.tar.gz',
  modality: ModelCategory.speechSynthesis,
);

// US English - Amy (female)
Onnx.addModel(
  id: 'vits-piper-en_US-amy-medium',
  name: 'Piper US English (Amy)',
  url: 'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/vits-piper-en_US-amy-medium.tar.gz',
  modality: ModelCategory.speechSynthesis,
);
​
Switching Voices

// Load default voice
await RunAnywhere.loadTTSVoice('vits-piper-en_US-lessac-medium');

// Switch to different voice
Future<void> switchVoice(String voiceId) async {
  await RunAnywhere.unloadTTSVoice();
  await RunAnywhere.loadTTSVoice(voiceId);
}
​
Voice Selection UI

class VoiceSelectorWidget extends StatefulWidget {
  @override
  _VoiceSelectorWidgetState createState() => _VoiceSelectorWidgetState();
}

class _VoiceSelectorWidgetState extends State<VoiceSelectorWidget> {
  final voices = [
    {'id': 'vits-piper-en_US-lessac-medium', 'name': 'Lessac (Male)'},
    {'id': 'vits-piper-en_US-amy-medium', 'name': 'Amy (Female)'},
    {'id': 'vits-piper-en_US-ryan-medium', 'name': 'Ryan (Male)'},
  ];

  String? _selectedVoice;
  bool _isLoading = false;

  Future<void> _selectVoice(String voiceId) async {
    setState(() => _isLoading = true);

    try {
      // Download if needed
      await for (final p in RunAnywhere.downloadModel(voiceId)) {
        if (p.state.isCompleted) break;
      }

      // Load voice
      await RunAnywhere.loadTTSVoice(voiceId);
      setState(() => _selectedVoice = voiceId);

      // Preview voice
      await _previewVoice();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _previewVoice() async {
    final result = await RunAnywhere.synthesize(
      'Hello, this is a preview of my voice.',
    );
    // Play audio...
    void _ = result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Voice', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        IgnorePointer(
          ignoring: _isLoading,
          child: RadioGroup<String>(
            groupValue: _selectedVoice,
            onChanged: (id) {
              if (id != null) _selectVoice(id);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: voices
                  .map((voice) => RadioListTile<String>(
                        value: voice['id']!,
                        title: Text(voice['name']!),
                      ))
                  .toList(),
            ),
          ),
        ),
        if (_isLoading) LinearProgressIndicator(),
      ],
    );
  }
}
​
System Voice Fallback

The SDK can fall back to system TTS voices via flutter_tts when neural voices aren’t available:
// System TTS is automatically available
// Use it for simple cases or as fallback
import 'package:flutter_tts/flutter_tts.dart';

final flutterTts = FlutterTts();

// List available system voices
final voices = await flutterTts.getVoices;

// Speak with system voice
await flutterTts.speak('Hello world');
​
Choosing Between Neural and System Voices

Feature	Piper (Neural)	System TTS
Quality	High	Varies
Latency	~100-500ms	~50ms
Size	20-50MB per voice	0 (built-in)
Offline	Yes	Yes
Customization	Limited	More options
Recommendation: Use Piper neural voices for the best quality. Fall back to system TTS for quick responses or when storage is limited.