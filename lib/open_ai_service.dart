import 'dart:async';

import 'girl-profile.dart';

class OpenAIService {
  Future<String> generateFlirtyMessage(GirlProfile profile, String tone) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final name = profile.name;
    final interest =
        profile.interests.isNotEmpty ? profile.interests[0] : 'something cool';

    switch (tone) {
      case 'funny':
        return "Hey $name, did you know that $interest looks better on you than on Google Maps?";
      case 'romantic':
        return "$name, you're the kind of $interest I’d chase across 10 lifetimes.";
      default:
        return "Hey $name, let’s pretend we’re in a rom-com about $interest.";
    }
  }
}
