/// Supabase configuration
/// 
/// Bu dosyada Supabase URL ve anon key tanımlanır.
/// Production'da bu değerler environment variables veya secure storage'dan okunmalıdır.
class SupabaseConfig {
  // TODO: Kendi Supabase projenizin URL ve anon key'ini buraya ekleyin
  // Supabase Dashboard > Settings > API > Project URL ve anon public key
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
  
  // Örnek:
  // static const String supabaseUrl = 'https://xxxxx.supabase.co';
  // static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
}

