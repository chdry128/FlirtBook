import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'girl_profile.dart';
import 'openai_service.dart';

class MessageScreen extends StatefulWidget {
  final GirlProfile profile;

  const MessageScreen({super.key, required this.profile});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  String generatedMessage = '';
  bool isLoading = false;
  String selectedTone = 'casual'; // Default tone
  final TextEditingController _contextController = TextEditingController();

  void selectTone(String tone) {
    setState(() {
      selectedTone = tone;
    });
  }

  void generateMessage() async {
    setState(() => isLoading = true);
    final service = OpenAIService();
    final msg = await service.generateFlirtyMessage(
      widget.profile,
      selectedTone,
      context: _contextController.text.trim(),
    );
    setState(() {
      generatedMessage = msg;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Delay initial message generation to allow context input first
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Message for ${widget.profile.name}"),
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8E1F1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful Profile Card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF85A2), Color(0xFFFF5988)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Decorative elements
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.profile.name
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF5988),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.profile.name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          widget.profile.status,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Interests",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  widget.profile.interests.map((interest) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        interest,
                                        style: const TextStyle(
                                          color: Color(0xFFFF5988),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Context input field
              const Text(
                "Add Context or Situation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5988),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _contextController,
                  decoration: InputDecoration(
                    hintText:
                        "E.g., We met at a coffee shop, She loves hiking...",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 24),

              // Message section title
              const Text(
                "Generated Message",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5988),
                ),
              ),
              const SizedBox(height: 12),

              // Message content
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    isLoading
                        ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFFF5988),
                              ),
                            ),
                          ),
                        )
                        : SelectableText(
                          generatedMessage,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          cursorColor: Color(0xFFFF5988),
                          showCursor: true,
                          contextMenuBuilder: (
                            BuildContext context,
                            EditableTextState editableTextState,
                          ) {
                            return AdaptiveTextSelectionToolbar.editableText(
                              editableTextState: editableTextState,
                            );
                          },
                        ),
              ),

              const SizedBox(height: 24),

              // Tone Selection Buttons
              const Text(
                "Select Tone",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF5988),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => selectTone("funny"),
                    icon: const Icon(Icons.tag_faces, color: Colors.white),
                    label: const Text(
                      "Funny",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedTone == "funny"
                              ? const Color(0xFFFF3366)
                              : Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => selectTone("romantic"),
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text(
                      "Romantic",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedTone == "romantic"
                              ? const Color(0xFFFF3366)
                              : Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => selectTone("casual"),
                    icon: const Icon(Icons.chat_bubble, color: Colors.white),
                    label: const Text(
                      "Casual",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedTone == "casual"
                              ? const Color(0xFFFF3366)
                              : Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),

              // Generate Button
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : generateMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text(
                    "Generate Message",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: OutlinedButton.icon(
                  onPressed:
                      generatedMessage.isEmpty
                          ? null
                          : () => Clipboard.setData(
                            ClipboardData(text: generatedMessage),
                          ),
                  icon: Icon(
                    Icons.copy,
                    color: generatedMessage.isEmpty ? Colors.grey : Colors.pink,
                  ),
                  label: Text(
                    "Copy Message",
                    style: TextStyle(
                      color:
                          generatedMessage.isEmpty ? Colors.grey : Colors.pink,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          generatedMessage.isEmpty ? Colors.grey : Colors.pink,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
