import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'config/supabase_config.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/incident_provider.dart';
import 'providers/notification_provider.dart';
import 'services/auth_service.dart';
import 'services/incident_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_image_storage.dart';
import 'screens/auth_wrapper.dart';
import 'utils/constants.dart';
import 'widgets/responsive_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(
          // To use Firebase Storage instead, replace SupabaseImageStorage()
          // with FirebaseImageStorage() (and import firebase_image_storage.dart)
          create: (_) => IncidentProvider(IncidentService(SupabaseImageStorage())),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider(NotificationService())),
      ],
      child: const CampusIncidentApp(),
    ),
  );
}

class CampusIncidentApp extends StatelessWidget {
  const CampusIncidentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      builder: (context, child) => ResponsiveFrame(child: child!),
    );
  }
}