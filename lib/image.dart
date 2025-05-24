import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
// import 'web_proxy_service.dart'; // Removed as calls go through our server proxy

class ImageAnalyzerScreen extends StatefulWidget {
  const ImageAnalyzerScreen({super.key});

  @override
  State<ImageAnalyzerScreen> createState() => _ImageAnalyzerScreenState();
}

class _ImageAnalyzerScreenState extends State<ImageAnalyzerScreen> {
  String? _apiResponse;
  bool _isLoading = false;
  File? _selectedImageFile; // For mobile platforms
  Uint8List? _selectedImageBytes; // For web platform
  XFile? _pickedFile; // To store the picked file reference
  final TextEditingController _contextController = TextEditingController();

  // Check if an image is selected on either platform
  bool get hasSelectedImage =>
      kIsWeb ? _selectedImageBytes != null : _selectedImageFile != null;

  // Show options to pick image from camera or gallery
  void _showImageSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Color(0xFF330033),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Select Image Source",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildImageSourceOption(
                        icon: Icons.camera_alt,
                        title: "Camera",
                        onTap: () async {
                          Navigator.pop(context);
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                          );
                          if (pickedFile != null) {
                            _pickedFile = pickedFile;
                            if (kIsWeb) {
                              // For web: read as bytes
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _selectedImageBytes = bytes;
                                _selectedImageFile = null;
                                _apiResponse = null; // Clear previous result
                              });
                            } else {
                              // For mobile: use File
                              setState(() {
                                _selectedImageFile = File(pickedFile.path);
                                _selectedImageBytes = null;
                                _apiResponse = null; // Clear previous result
                              });
                            }
                          }
                        },
                      ),
                      _buildImageSourceOption(
                        icon: Icons.photo_library,
                        title: "Gallery",
                        onTap: () async {
                          Navigator.pop(context);
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (pickedFile != null) {
                            _pickedFile = pickedFile;
                            if (kIsWeb) {
                              // For web: read as bytes
                              final bytes = await pickedFile.readAsBytes();
                              setState(() {
                                _selectedImageBytes = bytes;
                                _selectedImageFile = null;
                                _apiResponse = null; // Clear previous result
                              });
                            } else {
                              // For mobile: use File
                              setState(() {
                                _selectedImageFile = File(pickedFile.path);
                                _selectedImageBytes = null;
                                _apiResponse = null; // Clear previous result
                              });
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  // Build image source option button
  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00CCFF), Color(0xFF33FFCC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00CCFF).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Function to encode an image to Base64 (works for both web and mobile)
  Future<String> encodeImageToBase64() async {
    if (kIsWeb) {
      // For web: use the already loaded bytes
      if (_selectedImageBytes != null) {
        return base64Encode(_selectedImageBytes!);
      } else if (_pickedFile != null) {
        // If bytes aren't loaded yet, read them from the picked file
        final bytes = await _pickedFile!.readAsBytes();
        return base64Encode(bytes);
      }
    } else {
      // For mobile: read from file
      if (_selectedImageFile != null) {
        final List<int> imageBytes = await _selectedImageFile!.readAsBytes();
        return base64Encode(imageBytes);
      } else if (_pickedFile != null) {
        // Fallback to reading from XFile if File isn't available
        final bytes = await _pickedFile!.readAsBytes();
        return base64Encode(bytes);
      }
    }
    throw Exception('No image selected');
  }

  // Function to call the NVIDIA API with the Base64-encoded image and context
  Future<String> callNvidiaApi({
    // apiKey parameter removed
    required String imageBase64,
    required String customContext,
    bool stream = false, // Keep stream parameter for potential future use, though proxy might not support it yet
  }) async {
    // All requests now go through our server-side proxy
    final Uri proxyUri;
    if (kIsWeb) {
      proxyUri = Uri.parse('/api/nvidia'); // Relative path for web
    } else {
      // TODO: Replace with configurable production URL
      proxyUri = Uri.parse('http://localhost:3000/api/nvidia'); // For mobile/dev
    }

    // Compose enhanced prompt to instruct AI to analyze the screenshot and generate a flirty message
    String userPrompt =
        "This is a screenshot of an ongoing chat conversation. Analyze the screenshot to understand the dialogue. Based on this, generate a suitable flirty message as a response that I can send next."
        "${customContext.isNotEmpty ? '\n\nAdditional context about the conversation: $customContext' : ''}"
        '\n\n<img src="data:image/png;base64,$imageBase64" />';

    // Headers for the proxy request - Authorization is handled by the server
    final headers = {
      'Content-Type': 'application/json',
      'Accept': stream ? 'text/event-stream' : 'application/json',
    };

    // Prepare the request body for the NVIDIA API (to be sent TO the proxy)
    final nvidiaApiPayload = {
      'model': 'meta/llama-4-scout-17b-16e-instruct', // Example model, can be configured
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': 512,
      'temperature': 1.0,
      'top_p': 1.0,
      'stream': stream,
    };

    print('Sending request to proxy server: $proxyUri');

    try {
      final response = await http.post(
        proxyUri,
        headers: headers,
        body: jsonEncode(nvidiaApiPayload), // This body is sent to your proxy
      );

      if (response.statusCode == 200) {
        print('API request successful');

        if (stream) {
          // Handle streaming response
          return _processStreamResponse(response.body);
        } else {
          // Handle regular JSON response
          final jsonResponse = jsonDecode(response.body);
          if (jsonResponse.containsKey('choices') &&
              jsonResponse['choices'].isNotEmpty &&
              jsonResponse['choices'][0].containsKey('message') &&
              jsonResponse['choices'][0]['message'].containsKey('content')) {
            return jsonResponse['choices'][0]['message']['content'];
          } else {
            return 'Received response but could not extract content: ${response.body}';
          }
        }
      } else {
        print('API request failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
          'API request failed with status code: ${response.statusCode}, message: ${response.body}',
        );
      }
    } catch (e) {
      print('Error during API request: $e');
      throw Exception('Failed to connect to NVIDIA API: $e');
    }
  }

  // Process streaming response from the API
  String _processStreamResponse(String responseBody) {
    print('Processing streaming response...');

    try {
      // Split the response by data: prefix (SSE format)
      final events =
          responseBody
              .split('\n\n')
              .where((e) => e.startsWith('data: '))
              .toList();

      print('Found ${events.length} events in the response');

      // Extract and combine content from all events
      String combinedContent = '';

      for (var event in events) {
        try {
          // Remove 'data: ' prefix and parse JSON
          final jsonStr = event.substring(6);
          if (jsonStr.trim() == '[DONE]') continue;

          final jsonData = jsonDecode(jsonStr);
          if (jsonData.containsKey('choices') &&
              jsonData['choices'].isNotEmpty &&
              jsonData['choices'][0].containsKey('delta') &&
              jsonData['choices'][0]['delta'].containsKey('content')) {
            combinedContent += jsonData['choices'][0]['delta']['content'];
          }
        } catch (e) {
          print('Error processing event: $e');
          print('Event data: $event');
        }
      }

      if (combinedContent.isNotEmpty) {
        return combinedContent;
      } else {
        // If we couldn't extract content from streaming format, try parsing as a regular response
        try {
          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse.containsKey('choices') &&
              jsonResponse['choices'].isNotEmpty &&
              jsonResponse['choices'][0].containsKey('message') &&
              jsonResponse['choices'][0]['message'].containsKey('content')) {
            return jsonResponse['choices'][0]['message']['content'];
          }
        } catch (e) {
          print('Error parsing as regular response: $e');
        }
        return 'No content extracted from response';
      }
    } catch (e) {
      print('Error in stream processing: $e');
      return 'Error processing response: $e';
    }
  }

  // Only called when user taps "Generate"
  Future<void> analyzeImageWithContext() async {
    if (!hasSelectedImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first!')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _apiResponse =
          "Analyzing conversation and generating a flirty response...";
    });

    try {
      // Step 1: Encode image to Base64 (works for both web and mobile)
      final imageBase64 = await encodeImageToBase64();
      print('Image encoded to Base64');

      // Step 2: Call the API (apiKey is no longer passed from client)

      // For web, we'll use non-streaming mode as it's more reliable with CORS proxies
      // The proxy server will decide if it can handle streaming to NVIDIA if stream=true is passed.
      // For now, let's assume the proxy handles non-streaming responses primarily for this refactor.
      final useStreaming = !kIsWeb; // This can be simplified or made configurable via proxy if needed

      print('Calling proxy for NVIDIA API with streaming mode: $useStreaming');
      final response = await callNvidiaApi(
        // apiKey parameter removed
        imageBase64: imageBase64,
        customContext: _contextController.text,
        stream: useStreaming, // Proxy will receive this; its handling of it is server-side logic
      );
      print('Received response from API');

      setState(() {
        _apiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error analyzing image: $e');
      setState(() {
        _apiResponse = 'Error analyzing image: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Ensures the UI adapts when keyboard appears
      backgroundColor: Color(0xFF1A0033),
      appBar: AppBar(
        title: Text(
          "Image Analyzer",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A0033), // Deep purple
              Color(0xFF330033), // Dark purple
              Color(0xFF4D0033), // Purple-red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header section
                        const Text(
                          "Flirty Reply Generator",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Upload a chat screenshot & get the best flirty message.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Add context text field
                        TextField(
                          controller: _contextController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: "Add context (optional)",
                            labelStyle: const TextStyle(
                              color: Color(0xFF00CCFF),
                            ),
                            hintText:
                                "e.g. I want to keep things playful but sincere",
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF00CCFF),
                              ),
                            ),
                          ),
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                        ),

                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    () => _showImageSourceOptions(context),
                                icon: const Icon(
                                  Icons.upload,
                                  color: Color(0xFF330033),
                                ),
                                label: const Text("Upload Screenshot"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: const Color(0xFF330033),
                                  backgroundColor: const Color(0xFF00CCFF),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Smaller image preview - works for both web and mobile
                        if (hasSelectedImage)
                          Center(
                            child: Container(
                              width: 140,
                              height: 140,
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    kIsWeb
                                        ? _selectedImageBytes != null
                                            ? Image.memory(
                                              _selectedImageBytes!,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              color: Colors.grey.shade800,
                                            )
                                        : _selectedImageFile != null
                                        ? Image.file(
                                          _selectedImageFile!,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          color: Colors.grey.shade800,
                                        ),
                              ),
                            ),
                          ),

                        // Loading indicator
                        if (_isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF00CCFF),
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    "Analyzing and generating...",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Generated response (flirty message) section
                        if (_apiResponse != null && !_isLoading)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: SelectableText(
                                    _apiResponse ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      height: 1.55,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                // Copy button
                                if (_apiResponse != null &&
                                    _apiResponse!.length > 10)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.copy,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: _apiResponse ?? '',
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Message copied to clipboard',
                                              ),
                                              backgroundColor: const Color(
                                                0xFF00CCFF,
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        },
                                        tooltip: 'Copy to clipboard',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Generate button at the bottom, always visible, adapt to keyboard
                Padding(
                  padding: EdgeInsets.only(
                    top: 8.0,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).viewInsets.bottom
                            : 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isLoading || !hasSelectedImage
                                  ? null
                                  : () => analyzeImageWithContext(),
                          icon: const Icon(
                            Icons.rocket_launch,
                            color: Color(0xFF330033),
                          ),
                          label: const Text("Generate Flirty Message"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: const Color(0xFF330033),
                            backgroundColor: const Color(0xFF33FFCC),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
