class AppConstants {
  // อ่านจาก --dart-define=API_BASE_URL=https://... ตอน build
  // Default เป็น Android emulator loopback สำหรับ dev
  //
  // ตัวอย่าง release build:
  //   flutter build apk --release \
  //     --dart-define=API_BASE_URL=https://api.calories-guard.example
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Must match the major segment ("YYYY") of backend `API_VERSION`.
  /// Bump this in the same PR that upgrades the client to a breaking
  /// server release. See docs/CHANGELOG_API.md for the contract.
  static const String kExpectedApiVersion = '2026.04';
}
