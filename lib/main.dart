import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'screens/splash_gate_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase si las credenciales fueron provistas
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('✅ Supabase inicializado correctamente.');
    } catch (e) {
      debugPrint('⚠️ Error inicializando Supabase: $e');
    }
  } else {
    debugPrint(
      'ℹ️ Supabase no configurado aún. La app iniciará en Modo Demostración con los 30 PCs del Salón 317.',
    );
  }

  runApp(const Salon317App());
}

class Salon317App extends StatelessWidget {
  const Salon317App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salón 317 - SENA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashGateScreen(),
    );
  }
}
