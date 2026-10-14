/// Supabase project configuration.
/// Only the PUBLIC (publishable/anon) key belongs in the app.
/// Never put the service_role / secret key in client code.
class SupabaseConfig {
  static const url = 'https://cdrixqouzicncmggbusk.supabase.co';
  static const publishableKey =
      'sb_publishable_xGaG4uxEsvqePT2hKSN5Sw_xLx-0ggQ';

  /// Deep link used by Android to return to the app after Google login
  /// and email confirmation. Must be added in Supabase:
  /// Authentication → URL Configuration → Redirect URLs.
  static const mobileRedirect = 'com.company.servisku://login-callback';

  /// Google OAuth **Web** client ID — the same one set in
  /// Supabase → Authentication → Providers → Google.
  /// Native Android sign-in requests an ID token for this audience.
  static const googleWebClientId =
      '992375719488-hajafl518e83vkham5lcr3619cfufhd2.apps.googleusercontent.com';
}
