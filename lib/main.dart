import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'chat_service.dart';
import 'theme_provider.dart';
import 'login_screen.dart';
import 'chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final chatService = Provider.of<ChatService>(context);

    return MaterialApp(
      title: 'Chat Memo',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentThemeData,
      home: chatService.isAuthenticated 
          ? const ChatScreen() 
          : const LoginScreen(),
    );
  }
}
