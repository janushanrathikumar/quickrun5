import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // REQUIRED for system locales
import 'package:provider/provider.dart'; // REQUIRED for state management
import 'package:quickrun5/firebase_options.dart';
import 'package:quickrun5/view/admin/adminhome_screen.dart';

import 'package:quickrun5/view/login/welcome_view.dart';
import 'package:quickrun5/view/on_boarding/startup_view.dart';
import 'package:quickrun5/view/user/home_screen.dart';
import 'package:quickrun5/services/location_background_service.dart';
import 'package:quickrun5/translation.dart'; // Import your custom localization logic

void main() async {
  // Ensure all asynchronous operations are safe before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Your existing Firebase and Background Service initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeService();

  runApp(
    // 1. Wrap the entire application with ChangeNotifierProvider for LocaleNotifier
    ChangeNotifierProvider(
      create: (context) => LocaleNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Consume the LocaleNotifier to dynamically change the app's locale
    final localeNotifier = context.watch<LocaleNotifier>();

    return MaterialApp(
      title: 'QuickRun Delivery App', // Updated title for clarity
      debugShowCheckedModeBanner: false,

      // --- LOCALIZATION CONFIGURATION START ---

      // 3. SET THE DYNAMIC LOCALE from the notifier
      locale: localeNotifier.locale,

      // 4. ADD LOCALIZATION DELEGATES
      localizationsDelegates: const [
        // Your custom delegate for the translation file
        AppLocalizations.delegate,
        // Standard Flutter delegates for basic materials/widgets
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 5. LIST SUPPORTED LOCALES
      supportedLocales: AppLocalizations.supportedLocales,

      // --- LOCALIZATION CONFIGURATION END ---
      theme: ThemeData(
        fontFamily: "Metropolis",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const StartupView(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const WelcomeView(),
        '/adminhome': (context) => const AdminhomeomeScreen(),
        // Define other routes here
      },
    );
  }
}
