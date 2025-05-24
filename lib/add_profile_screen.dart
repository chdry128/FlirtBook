import 'package:flutter/material.dart';
import 'girl_profile.dart';
import 'shared_preference.dart';
import 'custom_button.dart';
//import 'package:google_mobile_ads/google_mobile_ads.dart';

class AddProfileScreen extends StatefulWidget {
  const AddProfileScreen({super.key});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String status;
  final List<String> interests = [];
  final TextEditingController interestController = TextEditingController();

  @override
  void initState() {
    status = 'Stranger';
    super.initState();
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    final sharedPrefs = SharedPrefs();
    final profile = GirlProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      status: status,
      interests: interests,
    );

    print('Saving profile: ${profile.toJson()}');
    await sharedPrefs.saveProfile('profile_${profile.id}', profile.toJson());
    print('Profile saved with key: profile_${profile.id}');

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Girl"),
        // backgroundColor: Colors.pink, // Removed to use AppBarTheme
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary), // Use theme color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), // Use theme color
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter name';
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: status,
                items:
                    ['Stranger', 'Friend', 'Ex', 'Crush']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() => status = val!),
                decoration: InputDecoration(
                  labelText: 'Relationship Status',
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary), // Use theme color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), // Use theme color
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: interestController,
                      decoration: InputDecoration(
                        labelText: 'Interest',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary), // Use theme color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary), // Use theme color
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary), // Use theme color
                    onPressed: () {
                      if (interestController.text.isNotEmpty) {
                        setState(() {
                          interests.add(interestController.text);
                          interestController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: interests.map((i) => Chip(label: Text(i))).toList(),
              ),
              const SizedBox(height: 20),
              CustomButton(text: "Save Profile", onPressed: saveProfile),
            ],
          ),
        ),
      ),
    );
  }
}
