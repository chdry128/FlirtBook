import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'girl_profile.dart';
// import 'web_proxy_service.dart'; // Removed unused import

class NvidiaAIService {
  // API Key is now handled by the server-side proxy
  late final http.Client _httpClient;

  NvidiaAIService({http.Client? client}) : _httpClient = client ?? http.Client();

  Future<String> generateFlirtyMessage({
    required GirlProfile profile,
    required String tone,
    String context = '',
  }) async {
    final interests =
        profile.interests.isNotEmpty
            ? profile.interests.join(", ")
            : "interesting things";
    final name = profile.name;

    String userPrompt = """
You are a flirt expert helping a guy craft **multiple short, flirty, and romantic messages** that look like they came straight from a blue chat bubble (like WhatsApp or iMessage).

Here’s what you know:
- Name: $name
- Her interests: $interests
- Tone requested: $tone
${context.isNotEmpty ? '- Current situation/context: $context' : ''}

Your task:
Generate **3–5 different flirty messages**, each:
- Under 2 lines
- Romantic and smooth
- Written like a real guy texting casually
- Incorporating her interests or the context
- With optional emojis (not overused)
- NO explanations or formatting — just the messages, one per line

Example output:
"Hey Em, saw a dog wearing a tiny backpack and thought of you 😂"
"If we went hiking tomorrow, would you carry me… or leave me for a bear?"

    

""";

    // The client now calls our proxy server, which handles the API key and CORS.
    // Ensure your Flutter app can reach this proxy endpoint.
    // If running locally: 'http://localhost:3000/api/nvidia'
    // If deployed, use the appropriate deployed proxy URL.
    // For simplicity, using a relative path assuming the Flutter web build is served by the same server
    // or the mobile app is configured to hit the correct backend.
    // final proxyUrl = kIsWeb ? '/api/nvidia' : 'http://your-backend-server-address/api/nvidia'; // This variable is no longer needed with the simplified logic below

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Authorization header is removed, server will add it.
    };

    final bodyPayload = {
      // This is the body that will be sent to NVIDIA by the proxy
      'model': 'meta/llama-4-scout-17b-16e-instruct',
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': 120,
      'temperature': 1.0,
      'top_p': 1.0,
      'stream': false,
    };

    try {
      http.Response response;
      Uri parsedUri;

      // Determine the correct URI based on the platform
      if (kIsWeb) {
        // For web, if served from the same domain as the proxy, a relative path should work.
        // Otherwise, a full URL (e.g., from environment config) would be needed.
        // The server.js proxy already handles CORS.
        parsedUri = Uri.parse('/api/nvidia');
      } else {
        // For mobile, always use the full URL to your proxy server.
        // This needs to be configurable for production.
        // TODO: Replace 'http://localhost:3000' with your actual deployed server address or use an environment variable.
        parsedUri = Uri.parse('http://localhost:3000/api/nvidia');
      }

      print('Sending request to proxy: $parsedUri');

      response = await _httpClient.post( // Use injected client
        parsedUri,
        headers: headers,
        body: jsonEncode(bodyPayload), // This is the body sent to your proxy
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // Assuming the proxy forwards NVIDIA's response structure directly
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          return jsonResponse['choices'][0]['message']['content'].trim();
        }
        print("Could not extract message from AI response: ${response.body}");
        return "Could not extract message from AI response.";
      } else {
        // Error message from the proxy server
        print('Error from proxy: ${response.statusCode} ${response.body}');
        throw Exception(
          'Proxy request failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error during API request to proxy: $e');
      // Consider more specific error handling or re-throwing a custom exception
      throw Exception('Failed to connect to the proxy server: $e');
    }
  }
}
