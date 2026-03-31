import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'providers/passport_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/auth_screen.dart';
// import 'firebase_options.dart'; // Uncomment after running 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: You must run 'flutterfire configure' to generate firebase_options.dart
  // Then uncomment the following block:
  /*
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  */

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PassportProvider()),
      ],
      child: const PassportPhotoStudioApp(),
    ),
  );
}

class PassportPhotoStudioApp extends StatelessWidget {
  const PassportPhotoStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passport Photo Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
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
