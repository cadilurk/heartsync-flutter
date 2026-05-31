class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'HEART_SYNC_API_BASE_URL',
    defaultValue: 'http://10.0.1.174:5291',
  );

  static bool get useMockApi => baseUrl.startsWith('mock://');
}
