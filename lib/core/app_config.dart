import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  // This is Supabase's client-safe publishable key. Database access remains
  // protected by the Row Level Security policies in `supabase/migrations`.
  static const _defaultSupabaseUrl = 'https://phaocokndkzkdtshztfb.supabase.co';
  static const _defaultSupabasePublishableKey =
      'sb_publishable_leodvvpkMogxzg59bO7foQ_9gu2WIiC';

  // Build-time values can still point a development build to another project.
  static const _definedSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedSupabaseKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get supabaseUrl => _definedSupabaseUrl.isNotEmpty
      ? _definedSupabaseUrl
      : _defaultSupabaseUrl;
  static String get supabasePublishableKey => _definedSupabaseKey.isNotEmpty
      ? _definedSupabaseKey
      : _defaultSupabasePublishableKey;

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;

  static String? get authRedirectUrl {
    if (kIsWeb) return '${Uri.base.origin}/';
    return 'io.supabase.flutter://login-callback/';
  }
}
