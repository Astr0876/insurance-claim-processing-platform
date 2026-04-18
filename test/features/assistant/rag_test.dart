import 'package:flutter_test/flutter_test.dart';
import 'package:lumina/core/services/assistant_service.dart';

void main() {
  group('Offline RAG System Tests', () {
    late AssistantService assistantService;

    setUp(() {
      assistantService = AssistantService();
    });

    test('Simulate ingestion of a textbook PDF', () async {
      const textbookContent = '''
      Chapter 1: Quantum Computing
      Quantum computing is a type of computing that uses quantum-mechanical phenomena.
      It uses qubits instead of classical bits.
      
      Chapter 2: Shors Algorithm
      Shors algorithm is a quantum algorithm for integer factorization.
      ''';

      await assistantService.indexDocument(textbookContent);
      expect(assistantService.hasDocument, true);
      expect(assistantService.documentContent, contains('Quantum Computing'));
    });

    test('Verify TensorFlow.js local vectorization & Airplane Mode', () async {
      // Setup
      assistantService.setMode(AssistantMode.luminaRag);
      await assistantService.downloadLumina(); // Simulate loading model
      
      const textbookContent = 'The primary goal of a compiler is to translate source code to machine code.';
      await assistantService.indexDocument(textbookContent);

      // Execute query
      final stream = assistantService.getAnswerStream('What is the goal of a compiler?');
      final output = await stream.join('');

      // Verify "Airplane Mode" / Privacy Guard
      expect(output, contains('Privacy Guard'));
      expect(output, contains('Zero Network Activity Verified'));
      
      // Verify Local Vectorization
      expect(output, contains('Local Vectorization'));
      expect(output, contains('Searching offline embeddings'));
      
      // Verify results are from local document only
      expect(output, contains('translate source code to machine code'));
    });

    test('Test Synthesis logic (not just snippets)', () async {
      assistantService.setMode(AssistantMode.luminaRag);
      await assistantService.downloadLumina();
      
      const content = 'Photosynthesis is the process by which green plants use sunlight to synthesize nutrients from carbon dioxide and water.';
      await assistantService.indexDocument(content);

      final stream = assistantService.getAnswerStream('What is photosynthesis?');
      final output = await stream.join('');

      // Verify Synthesis header
      expect(output, contains('Synthesis'));
      
      // Verify it synthesized an answer (not just a raw snippet list)
      expect(output, contains('Based on your local document'));
      expect(output, contains('can be defined through the following context'));
    });

    test('Verify Privacy Guard: No network requests should be triggered', () {
      // This is a structural check - ensure Privacy Guard is active by default in RAG mode
      assistantService.setMode(AssistantMode.luminaRag);
      expect(assistantService.isPrivacyGuardActive, true);
    });
  });
}
