import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class GradioService {
  final String baseUrl = 'https://kankshi-lockIn.hf.space';

  /// Uploads a file to Gradio and returns the server-side path.
  Future<String?> uploadFile(File file) async {
    try {
      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath(
        'files',
        file.path,
        filename: p.basename(file.path),
      ));

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final List<dynamic> result = jsonDecode(body);
        if (result.isNotEmpty) {
          final first = result[0];
          if (first is String) {
            return first;
          } else if (first is Map && first.containsKey('path')) {
            return first['path'] as String;
          }
        }
      }
    } catch (e) {
      debugPrint('Gradio upload error: $e');
    }
    return null;
  }

  /// Calls a Gradio endpoint using the two-step predict flow.
  Future<dynamic> callEndpoint(String endpoint, List<dynamic> data) async {
    try {
      // Step 1: POST to /call/<endpoint>
      final callUri = Uri.parse('$baseUrl/call/$endpoint');
      final callResponse = await http.post(
        callUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': data}),
      );

      if (callResponse.statusCode != 200) {
        debugPrint('Gradio call error: ${callResponse.statusCode} ${callResponse.body}');
        return null;
      }

      final eventId = jsonDecode(callResponse.body)['event_id'];

      // Step 2: GET from /call/<endpoint>/<event_id>
      // Gradio might take some time, so we might need to poll, but usually for simple calls one GET is enough
      // or it might be a server-sent events stream.
      // Based on user's instruction: "The response body will contain data: [...]"
      
      final resultUri = Uri.parse('$baseUrl/call/$endpoint/$eventId');
      
      // We might need to wait a bit or poll if it returns "pending"
      // For now, let's try a simple GET. 
      // Note: Gradio v6 SSE often uses a stream. If it's a simple GET that returns the final result, this works.
      
      while (true) {
        final resultResponse = await http.get(resultUri);
        if (resultResponse.statusCode != 200) {
          debugPrint('Gradio result error: ${resultResponse.statusCode} ${resultResponse.body}');
          return null;
        }

        final body = resultResponse.body;
        
        // Handle Gradio SSE (Server-Sent Events)
        if (body.contains('event: complete')) {
          final lines = body.split('\n');
          final dataLine = lines.firstWhere((line) => line.startsWith('data: '), orElse: () => '');
          if (dataLine.isNotEmpty) {
            return jsonDecode(dataLine.substring(6));
          }
        } 
        
        // Handle standard JSON if it's not SSE
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map && decoded.containsKey('data')) {
            return decoded['data'];
          } else if (decoded is List) {
            return decoded;
          }
        } catch (_) {
          // Not a simple JSON, might be pending SSE
        }

        if (body.contains('event: error')) {
          debugPrint('Gradio execution error: $body');
          return null;
        }
        
        // If it's still heartbeat or pending, wait and poll
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Gradio service error: $e');
    }
    return null;
  }
}
