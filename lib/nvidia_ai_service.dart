import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'girl-profile.dart';
import 'web_proxy_service.dart';

class NvidiaAIService {
  static const _apiKey =
      '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'; // TODO: secure in production

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

    // We'll use the direct API URL for both platforms
    // The CORS handling will be done in the request logic below
    final baseUrl = 'https://integrate.api.nvidia.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
      'Accept': 'application/json',
    };

    final body = jsonEncode({
      'model': 'meta/llama-4-scout-17b-16e-instruct',
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': 120,
      'temperature': 1.0,
      'top_p': 1.0,
      'stream': false,
    });

    try {
      http.Response response;

      if (kIsWeb) {
        // For web, use WebProxyService which handles CORS issues
        try {
          print('Using WebProxyService for web request...');
          response = await WebProxyService.proxyRequest(
            url: baseUrl,
            method: 'POST',
            headers: headers,
            body: body,
          );
        } catch (e) {
          print('WebProxyService failed: $e');

          // Fallback to simulated response for web
          print('Falling back to simulated response for web');

          // Create a simulated flirty message based on the profile
          final interests =
              profile.interests.isNotEmpty
                  ? profile.interests[0]
                  : "interesting things";
          String simulatedResponse;

          if (tone == 'funny') {
            simulatedResponse = """
"Hey ${profile.name}, if ${interests} were a crime, you'd be serving a life sentence for being too awesome 😄"
"Just saw something about ${interests} and thought of you. Coincidence? I think the universe is playing matchmaker 😏"
"${profile.name}, your passion for ${interests} is almost as attractive as your smile. Almost. 😉"
            """;
          } else if (tone == 'romantic') {
            simulatedResponse = """
"${profile.name}, thinking about your love for ${interests} makes me wonder what other passions we might share together ❤️"
"The way your eyes light up when you talk about ${interests}... it's the kind of magic I could get lost in forever"
"If I could give you anything in the world, it would be the chance to show you how special you are, ${profile.name} 💫"
            """;
          } else {
            simulatedResponse = """
"Hey ${profile.name}, your interest in ${interests} caught my attention, but your smile is what kept it"
"${profile.name}, let's talk about ${interests} over coffee sometime. I promise to be at least half as interesting as you are"
"Just wanted to say that your passion for ${interests} is really cool. It's refreshing to meet someone with genuine interests"
            """;
          }

          // Create a mock response that mimics the NVIDIA API response format
          final mockResponseBody = jsonEncode({
            'choices': [
              {
                'message': {'content': simulatedResponse},
              },
            ],
          });

          response = http.Response(mockResponseBody, 200);
          return simulatedResponse.trim();
        }
      } else {
        // For mobile, make the request directly
        response = await http.post(
          Uri.parse(baseUrl),
          headers: headers,
          body: body,
        );
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          return jsonResponse['choices'][0]['message']['content'].trim();
        }
        return "Could not extract message from AI response.";
      } else {
        throw Exception(
          'AI request failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('Error during API request: $e');
      throw Exception('Failed to connect to NVIDIA API: $e');
    }
  }
}
