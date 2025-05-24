import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'girl_profile.dart';
import 'message_screen.dart';
import 'add_profile_screen.dart';
import 'shared_preference.dart';

class ProfilesListScreen extends StatefulWidget {
  const ProfilesListScreen({super.key});

  @override
  State<ProfilesListScreen> createState() => _ProfilesListScreenState();
}

class _ProfilesListScreenState extends State<ProfilesListScreen> {
  List<GirlProfile> profiles = [];

  @override
  void initState() {
    super.initState();
    _initializeProfiles();
  }

  Future<void> _initializeProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInitialized = prefs.getBool('has_initialized') ?? false;

    if (!hasInitialized) {
      // Only clear profiles on first app launch
      final hasLaunched = prefs.getBool('has_launched') ?? false;
      if (!hasLaunched) {
        await clearOldProfiles();
        await prefs.setBool('has_launched', true);
      }
      await prefs.setBool('has_initialized', true);
    }

    await loadProfiles();
  }

  Future<void> clearOldProfiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((key) => key.startsWith('profile_')).toList();
    print('Clearing old profiles with keys: $keys');
    for (String key in keys) {
      await prefs.remove(key);
    }
    await prefs.remove('profile_count');
    print('Old profiles cleared');
  }

  Future<void> loadProfiles() async {
    final sharedPrefs = SharedPrefs();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get all keys that start with 'profile_'
    List<String> profileKeys =
        prefs.getKeys().where((key) => key.startsWith('profile_')).toList();
    print('Found profile keys: $profileKeys');

    // Get all deletion markers
    List<String> deletionMarkers =
        prefs
            .getKeys()
            .where((key) => key.startsWith('deleted_profile_'))
            .toList();
    print('Found deletion markers: $deletionMarkers');

    // Create a set of profile keys that should be skipped
    Set<String> keysToSkip = {};

    // Process deletion markers
    for (String marker in deletionMarkers) {
      if (prefs.getBool(marker) == true) {
        // Extract the profile key from the deletion marker
        String profileKey = marker.substring('deleted_'.length);
        keysToSkip.add(profileKey);

        // Clean up the deletion marker and profile data
        print('Removing deleted profile: $profileKey');
        await prefs.remove(marker);
        await prefs.remove(profileKey);
      }
    }

    List<GirlProfile> loadedProfiles = [];
    for (String key in profileKeys) {
      // Skip this profile if it's marked for deletion
      if (keysToSkip.contains(key)) {
        print('Skipping deleted profile: $key');
        continue;
      }

      try {
        final json = await sharedPrefs.loadProfile(key);
        print('Loading profile with key $key: $json');
        if (json != null) {
          loadedProfiles.add(GirlProfile.fromJson(json));
        }
      } catch (e) {
        print('Error loading profile with key $key: $e');
        // If there's an error loading a profile, remove it
        await prefs.remove(key);
      }
    }

    if (mounted) {
      setState(() {
        profiles = loadedProfiles;
      });
    }

    print('Loaded ${profiles.length} profiles');

    print('Loaded ${profiles.length} profiles');
  }

  Future<void> deleteProfile(GirlProfile profile) async {
    // Show confirmation dialog
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete ${profile.name}?'),
                content: Text(
                  'Are you sure you want to delete this profile? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text(
                      'DELETE',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirm) return;

    // Get SharedPreferences instance
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Find the actual profile key in SharedPreferences
    List<String> allKeys =
        prefs.getKeys().where((key) => key.startsWith('profile_')).toList();
    String? profileKey;

    // Find the key that contains this profile's ID
    for (String key in allKeys) {
      String? jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          Map<String, dynamic> data = jsonDecode(jsonStr);
          if (data['id'] == profile.id) {
            profileKey = key;
            break;
          }
        } catch (e) {
          print('Error parsing JSON for key $key: $e');
        }
      }
    }

    if (profileKey == null) {
      print('Could not find profile key for ID: ${profile.id}');
      profileKey = 'profile_${profile.id}'; // Fallback
    }

    print('Deleting profile with key: $profileKey');

    // Get SharedPrefs instance
    final sharedPrefs = SharedPrefs();

    // Remove the profile from the list
    setState(() {
      profiles.removeWhere((p) => p.id == profile.id);
    });

    // Delete the profile using SharedPrefs (which handles marking as deleted)
    await sharedPrefs.deleteProfile(profileKey);

    // Show a snackbar to confirm deletion
    if (!mounted) return; // Check if the widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${profile.name} has been deleted'),
        backgroundColor: Colors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profiles"),
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8E1F1),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProfileScreen()),
          );
          if (result == true) {
            loadProfiles(); // Refresh the list when a new profile is added
          }
        },
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add),
      ),
      body:
          profiles.isEmpty
              ? const Center(
                child: Text(
                  "No profiles yet. Add some girls!",
                  style: TextStyle(fontSize: 18, color: Colors.pink),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: profiles.length,
                itemBuilder: (_, i) {
                  final p = profiles[i];
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
                    child: Row(
                      children: [
                        // Main content with InkWell for navigation
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MessageScreen(profile: p),
                                    ),
                                  ).then((_) {
                                    // Check if this profile still exists before reloading
                                    loadProfiles();
                                  }), // Refresh list when returning from message screen
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // Profile initial circle
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFF85A2),
                                            Color(0xFFFF5988),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          p.name.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Profile details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8E1F1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              p.status,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFFFF5988),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Interests
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children:
                                                p.interests.take(3).map((
                                                  interest,
                                                ) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      interest,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Arrow icon
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Color(0xFFFF5988),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Delete button (separate from InkWell)
                        Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 22,
                              ),
                              onPressed: () => deleteProfile(p),
                              splashRadius: 24,
                              tooltip: 'Delete profile',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
