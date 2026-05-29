class ApiConstants {
  ApiConstants._();

  static const baseUrl = String.fromEnvironment(
    'HEART_SYNC_API_BASE_URL',
    // Mặc định kết nối tới Server Node.js (cổng 5291) kết nối MongoDB thật của bạn.
    // Nếu muốn chuyển lại dữ liệu giả lập (Mock), bạn hãy đổi thành 'mock://heartsync'
    defaultValue: 'http://127.0.0.1:5291',
  );

  static bool get useMockApi => baseUrl.startsWith('mock://');
}
