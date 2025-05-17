import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefs {
  // Singleton pattern
  static final SharedPrefs _instance = SharedPrefs._internal();

  factory SharedPrefs() => _instance;

  SharedPrefs._internal();

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // Save Girl Profile (as JSON string)
  Future<void> saveProfile(String key, String value) async {
    final prefs = await _prefs;
    print('SharedPrefs: Saving profile with key $key');
    try {
      await prefs.setString(key, value);
      print('SharedPrefs: Profile saved successfully');
    } catch (e) {
      print('SharedPrefs: Error saving profile: $e');
      // If there's an error, try to remove the key first
      await prefs.remove(key);
      // Then try saving again
      await prefs.setString(key, value);
    }
  }

  Future<List<String>> getAllKeys() async {
    final prefs = await _prefs;
    return prefs.getKeys().toList();
  }

  // Load Girl Profile
  Future<String?> loadProfile(String key) async {
    final prefs = await _prefs;
    try {
      final value = prefs.getString(key);
      print('SharedPrefs: Loading profile with key $key: $value');
      return value;
    } catch (e) {
      print('SharedPrefs: Error loading profile with key $key: $e');
      // If there's an error, remove the invalid data
      await prefs.remove(key);
      return null;
    }
  }

  // Clear All Profiles (for debugging)
  Future<void> clearAllProfiles() async {
    final prefs = await _prefs;
    final keys =
        prefs.getKeys().where((key) => key.startsWith('profile_')).toList();
    print('SharedPrefs: Clearing all profiles with keys: $keys');
    for (String key in keys) {
      await prefs.remove(key);
      // Also remove any deletion markers
      await prefs.remove('deleted_$key');
    }
    await prefs.remove('profile_count');
    print('SharedPrefs: All profiles cleared');
  }

  // Delete a profile permanently
  Future<void> deleteProfile(String key) async {
    final prefs = await _prefs;
    print('SharedPrefs: Deleting profile with key $key');

    // Get the profile data before deleting
    String? profileJson = prefs.getString(key);
    if (profileJson != null) {
      try {
        // Parse the profile to get its ID
        Map<String, dynamic> profileData = jsonDecode(profileJson);
        String profileId = profileData['id'];
        print('SharedPrefs: Profile ID to delete: $profileId');

        // Find all keys that might contain this profile
        List<String> allProfileKeys =
            prefs.getKeys().where((k) => k.startsWith('profile_')).toList();

        // Delete all instances of this profile by ID
        for (String profileKey in allProfileKeys) {
          String? json = prefs.getString(profileKey);
          if (json != null) {
            try {
              Map<String, dynamic> data = jsonDecode(json);
              if (data['id'] == profileId) {
                print('SharedPrefs: Removing profile with key: $profileKey');
                await prefs.remove(profileKey);
                await prefs.setBool('deleted_$profileKey', true);
              }
            } catch (e) {
              print('SharedPrefs: Error parsing JSON for key $profileKey: $e');
            }
          }
        }
      } catch (e) {
        print('SharedPrefs: Error processing profile for deletion: $e');
        // If we can't parse the profile, just delete the key directly
        await prefs.remove(key);
        await prefs.setBool('deleted_$key', true);
      }
    } else {
      // If no profile data found, just mark as deleted
      await prefs.remove(key);
      await prefs.setBool('deleted_$key', true);
    }
  }
}
