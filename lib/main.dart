import 'package:flutter/material.dart';
import 'home_screen.dart';
//import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  //await MobileAds.instance.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlirtBook',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4081), // Vibrant pink
          brightness: Brightness.light,
          primary: const Color(0xFFFF4081),
          secondary: const Color(0xFFF06292),
          tertiary: const Color(0xFFAD1457),
          surface: const Color(0xFFFCE4EC),
          background: const Color(0xFFFCE4EC), // Added background color
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto', // Consider if Roboto is consistently used/imported
          ),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 16),
          labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Added for buttons
        ),
        scaffoldBackgroundColor: const Color(0xFFFCE4EC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF4081),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
