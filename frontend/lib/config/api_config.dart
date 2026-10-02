class ApiConfig {
  ApiConfig._();

  // Android Emulator: http://10.0.2.2:5000
  // iOS Simulator/Web: http://localhost:5000
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
}
