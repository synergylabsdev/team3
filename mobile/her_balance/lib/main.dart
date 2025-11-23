import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'core/theme/app_theme.dart';
import 'core/database/supabase_client.dart';
import 'presentation/main_navigation_page.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseClient.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Her Balance',
      theme: AppTheme.theme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    SupabaseClient.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == supabase.AuthChangeEvent.signedIn || 
          event == supabase.AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseClient.auth.currentUser;
    
    if (user != null) {
      return MainNavigationPage(key: MainNavigationPage.navigatorKey);
    } else {
      return const LoginPage();
    }
  }
}
