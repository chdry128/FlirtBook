import 'package:flutter/material.dart';
import 'shared_preference.dart';
//import 'message_history.dart';
//import 'history_screen.dart';
import 'history_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<MessageHistory> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final sharedPrefs = SharedPrefs();
    final keys = await sharedPrefs.getAllKeys();
    final historyKeys = keys.where((key) => key.startsWith('history_')).toList();

    List<MessageHistory> loadedHistory = [];
    for (String key in historyKeys) {
      final json = await sharedPrefs.loadProfile(key);
      if (json != null) {
        loadedHistory.add(MessageHistory.fromJson(json));
      }
    }

    setState(() {
      history = loadedHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Message History"),
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8E1F1),
      body: history.isEmpty
          ? const Center(
        child: Text(
          "No history yet. Generate some messages!",
          style: TextStyle(fontSize: 18, color: Colors.pink),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (_, i) {
          final h = history[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profile: ${h.profileName}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Message: ${h.message}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Generated on: ${h.timestamp}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}