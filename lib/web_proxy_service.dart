import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class WebProxyService {
  static Future<http.Response> proxyRequest({
    required String url,
    required String method,
    required Map<String, String> headers,
    String? body,
  }) async {
    // For non-web platforms, just make the request directly
    if (!kIsWeb) {
      final request = http.Request(method, Uri.parse(url));
      request.headers.addAll(headers);
      if (body != null) {
        request.body = body;
      }
      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    } else {
      // For web platforms, try different CORS proxy approaches
      try {
        // First, try direct request (might work if CORS is properly configured)
        try {
          print('Trying direct request with mode=cors...');
          // For web, we need to add mode=cors to the headers
          final modifiedHeaders = Map<String, String>.from(headers);
          modifiedHeaders['mode'] = 'cors';

          final request = http.Request(method, Uri.parse(url));
          request.headers.addAll(modifiedHeaders);
          if (body != null) {
            request.body = body;
          }
          final streamedResponse = await request.send();
          return http.Response.fromStream(streamedResponse);
        } catch (e) {
          print('Direct request failed: $e');
        }

        // Second, try using allorigins.win CORS proxy
        try {
          final proxyUrl =
              'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
          final request = http.Request(method, Uri.parse(proxyUrl));
          request.headers.addAll(headers);
          if (body != null) {
            request.body = body;
          }
          final streamedResponse = await request.send();
          return http.Response.fromStream(streamedResponse);
        } catch (e) {
          print('allorigins.win proxy failed: $e');

          // Try another proxy - corsanywhere
          final proxyUrl = 'https://cors-anywhere.herokuapp.com/$url';
          final request = http.Request(method, Uri.parse(proxyUrl));
          request.headers.addAll(headers);
          if (body != null) {
            request.body = body;
          }
          final streamedResponse = await request.send();
          return http.Response.fromStream(streamedResponse);
        }
      } catch (e) {
        print('CORS proxy failed: $e');

        // Third, try using cors-anywhere CORS proxy
        try {
          final proxyUrl =
              'https://cors-anywhere.herokuapp.com//?${Uri.encodeComponent(url)}';
          final request = http.Request(method, Uri.parse(proxyUrl));
          request.headers.addAll(headers);
          if (body != null) {
            request.body = body;
          }
          final streamedResponse = await request.send();
          return http.Response.fromStream(streamedResponse);
        } catch (e) {
          print('Second CORS proxy failed: $e');

          // Fourth, try using Cloudflare Workers CORS proxy
          try {
            print('Trying Cloudflare Workers CORS proxy...');
            final proxyUrl =
                'https://test.cors.workers.dev/?${Uri.encodeComponent(url)}';

            // Add special header for CORS proxy if needed
            final proxyHeaders = Map<String, String>.from(headers);
            proxyHeaders['x-cors-headers'] = jsonEncode({'cookies': 'x=123'});

            final request = http.Request(method, Uri.parse(proxyUrl));
            request.headers.addAll(proxyHeaders);
            if (body != null) {
              request.body = body;
            }
            final streamedResponse = await request.send();
            return http.Response.fromStream(streamedResponse);
          } catch (e) {
            print('Cloudflare Workers CORS proxy failed: $e');

            // Fifth, try using HTMLDriven CORS proxy
            try {
              print('Trying HTMLDriven CORS proxy...');
              final proxyUrl =
                  'https://cors-proxy.htmldriven.com/?url=${Uri.encodeComponent(url)}';

              final request = http.Request(method, Uri.parse(proxyUrl));
              request.headers.addAll(headers);
              if (body != null) {
                request.body = body;
              }
              final streamedResponse = await request.send();

              // HTMLDriven proxy returns JSON with 'contents' field containing the actual response
              final response = await http.Response.fromStream(streamedResponse);
              if (response.statusCode == 200) {
                try {
                  final jsonResponse = jsonDecode(response.body);
                  if (jsonResponse['contents'] != null) {
                    return http.Response(jsonResponse['contents'], 200);
                  }
                } catch (jsonError) {
                  print('Error parsing HTMLDriven proxy response: $jsonError');
                }
              }
              return response;
            } catch (e) {
              print('HTMLDriven CORS proxy failed: $e');

              // Sixth, try using CORS.sh proxy with API key
              try {
                print('Trying CORS.sh proxy with API key...');
                final proxyUrl = 'https://proxy.cors.sh/$url';

                // Add the required API key header
                final proxyHeaders = Map<String, String>.from(headers);
                proxyHeaders['x-cors-api-key'] =
                    'temp_104ad3eba18791f9033f0e2dbb1e8d1c';

                final request = http.Request(method, Uri.parse(proxyUrl));
                request.headers.addAll(proxyHeaders);
                if (body != null) {
                  request.body = body;
                }
                final streamedResponse = await request.send();
                return http.Response.fromStream(streamedResponse);
              } catch (e) {
                print('CORS.sh proxy failed: $e');
                // Last resort: Try using a jsonp proxy
                try {
                  print('Trying jsonp.afeld.me proxy...');
                  final jsonpUrl =
                      'https://jsonp.afeld.me/?url=${Uri.encodeComponent(url)}';

                  final request = http.Request(method, Uri.parse(jsonpUrl));
                  request.headers.addAll(headers);
                  if (body != null) {
                    request.body = body;
                  }
                  final streamedResponse = await request.send();
                  return http.Response.fromStream(streamedResponse);
                } catch (finalError) {
                  print('All proxies failed. Last error: $finalError');
                  throw Exception(
                    'All CORS proxy methods failed. Last error: $finalError',
                  );
                }
              }
            }
          }
        }
      }
    }
  }
}
