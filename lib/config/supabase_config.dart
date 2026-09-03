

class SupabaseConfig {
  /// URL de tu proyecto Supabase (ya configurada con tu panel)
  static const String supabaseUrl = 'https://wdebwytdhxlfhmwoydgb.supabase.co';

  /// REEMPLAZA ESTO con tu 'anon' 'public' key (ver pasos en el chat)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndkZWJ3eXRkaHhsZmhtd295ZGdiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE0OTQ1ODAsImV4cCI6MjA4NzA3MDU4MH0.x85SUXeG_2OuV7h5QyPRxJyXjnwtT2Y6ZXv4hTQ2NdY';

  /// Valida si el usuario ya colocó sus credenciales reales
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('TU_PROYECTO') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('TU_SUPABASE_ANON_KEY');
  }
}
