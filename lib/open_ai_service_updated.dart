import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import 'girl-profile.dart';
import 'nvidia_ai_service.dart';
import 'shared_preference.dart';
import 'history_model.dart';

class OpenAIService {
  final NvidiaAIService _nvidiaAI = NvidiaAIService();
  final SharedPrefs _sharedPrefs = SharedPrefs();

  Future<String> generateFlirtyMessage(
      GirlProfile profile,
      String tone, {
        String context = '',
      }) async {
    // Check for internet connectivity
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      // Try NVIDIA AI if we have internet connection
      try {
        final aiMsg = await _nvidiaAI.generateFlirtyMessage(
          profile: profile,
          tone: tone,
          context: context,
        );
        // If we got a valid response, return it
        if (aiMsg.isNotEmpty) {
          await _saveMessageHistory(profile, aiMsg);
          return aiMsg;
        }
      } catch (e) {
        // If AI API fails, fall back to simulation
      }
    }

    // Fallback to local simulation if offline or AI service failed
    await Future.delayed(const Duration(seconds: 2));

    final name = profile.name;
    final interest = profile.interests.isNotEmpty ? profile.interests[0] : 'something cool';

    // If context is provided, use it to personalize the message
    if (context.isNotEmpty) {
      switch (tone) {
        case 'funny':
          final msg = "Hey $name, thinking about $context made me realize that your love for $interest is like a perfect punchline - unexpected and makes my day better! 😄";
          await _saveMessageHistory(profile, msg);
          return msg;
        case 'romantic':
          final msg = "Dear $name, remembering $context makes me appreciate how your passion for $interest shines through everything you do. It's the little things about you that make every moment special. ❤️";
          await _saveMessageHistory(profile, msg);
          return msg;
        default:
          final msg = "Hey $name, $context reminded me of you and your love for $interest. Isn't it amazing how the smallest things can create the strongest connections?";
          await _saveMessageHistory(profile, msg);
          return msg;
      }
    } else {
      // Default messages when no context is provided
      switch (tone) {
        case 'funny':
          final msg = "Hey $name, did you know that $interest looks better on you than on Google Maps? 😉";
          await _saveMessageHistory(profile, msg);
          return msg;
        case 'romantic':
          final msg = "$name, you're the kind of $interest enthusiast I'd chase across 10 lifetimes. ❤️";
          await _saveMessageHistory(profile, msg);
          return msg;
        default:
          final msg = "Hey $name, let's pretend we're in a rom-com about $interest. I'll bring the popcorn, you bring your smile.";
          await _saveMessageHistory(profile, msg);
          return msg;
      }
    }
  }

  Future<void> _saveMessageHistory(GirlProfile profile, String message) async {
    final history = MessageHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: profile.id,
      profileName: profile.name,
      message: message,
      timestamp: DateTime.now(),
    );

    await _sharedPrefs.saveProfile('history_${history.id}', history.toJson());
  }
}