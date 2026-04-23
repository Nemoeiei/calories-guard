class AppConstants {
  // อ่านจาก --dart-define=API_BASE_URL=https://... ตอน build
  // Default ชี้ production — dev สามารถ override ได้ด้วย --dart-define
  //
  // ตัวอย่าง release build:
  //   flutter build apk --release \
  //     --dart-define=API_BASE_URL=https://api.caloriesguard.com
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.caloriesguard.com',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zawlghlnzgftlxcoipuf.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inphd2xnaGxuemdmdGx4Y29pcHVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAzNTgxODYsImV4cCI6MjA4NTkzNDE4Nn0.KPu4h9kAUYKINBShNFFas_DEVvOAZvaA78PXffYo6OI',
  );

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Must match the major segment ("YYYY") of backend `API_VERSION`.
  /// Bump this in the same PR that upgrades the client to a breaking
  /// server release. See docs/CHANGELOG_API.md for the contract.
  static const String kExpectedApiVersion = '2026.04';

  /// Hosted legal documents. Overridable at build time so staging can point
  /// at a preview deployment without a client rebuild. Default is the prod
  /// GitHub-Pages URL planned for public launch; during beta the file lives
  /// in the repo at `docs/privacy-policy.md` and `docs/terms-of-service.md`.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://calories-guard.pages.dev/privacy',
  );
  static const String termsOfServiceUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://calories-guard.pages.dev/terms',
  );
}
