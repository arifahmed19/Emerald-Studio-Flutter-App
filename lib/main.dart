import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'providers/passport_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // REPLACE with your Project URL and Anon Key from Supabase Dashboard
  await Supabase.initialize(
    url: 'https://dvxncyptzoeblzengbfk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR2eG5jeXB0em9lYmx6ZW5nYmZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4OTg3NTAsImV4cCI6MjA5MDQ3NDc1MH0.4bk9ofpvZH8vfLsgk9pnBh3v87LXHM5sw6JU_SdiUC4',
  );

  final prefs = await SharedPreferences.getInstance();
  final hasSeenIntro = prefs.getBool('hasSeenIntro') ?? false;
  
  // Mobile check
  bool isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool showIntro = isMobile && !hasSeenIntro;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PassportProvider()),
      ],
      child: EmeraldStudioApp(showIntro: showIntro),
    ),
  );
}

class EmeraldStudioApp extends StatelessWidget {
  final bool showIntro;
  const EmeraldStudioApp({super.key, required this.showIntro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emerald Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (showIntro) return const IntroScreen();
          return auth.isAuthenticated ? const HomeScreen() : const AuthScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/editor': (context) => const EditorScreen(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
