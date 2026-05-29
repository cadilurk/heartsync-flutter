class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'HEART_SYNC_API_BASE_URL',
    defaultValue: 'mock://heartsync',
  );

  static bool get useMockApi => baseUrl.startsWith('mock://');
}
