import 'api_exception.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiException? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) parseData,
  ) {
    final success = json['success'] == true;
    if (success) {
      return ApiResponse<T>(
        success: true,
        data: parseData(json['data']),
      );
    }

    final error = json['error'] as Map<String, dynamic>?;
    return ApiResponse<T>(
      success: false,
      error: ApiException(
        code: error?['code']?.toString() ?? 'SERVER_ERROR',
        message: error?['message']?.toString() ?? 'Đã có lỗi xảy ra.',
      ),
    );
  }
}
