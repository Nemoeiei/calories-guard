class AppConstants {
  // อ่านจาก --dart-define=API_BASE_URL=https://... ตอน build
  // Default เป็น Android emulator loopback สำหรับ dev
  //
  // ตัวอย่าง release build:
  //   flutter build apk --release \
  //     --dart-define=API_BASE_URL=https://api.calories-guard.example
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.caloriesguard.com',
  );
}
