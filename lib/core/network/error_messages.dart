class ErrorMessages {
  ErrorMessages._();

  static const _messages = {
    'INVALID_INPUT': 'Thông tin nhập chưa hợp lệ.',
    'EMAIL_ALREADY_EXISTS': 'Email này đã được đăng ký.',
    'INVALID_EMAIL_OR_PASSWORD': 'Email hoặc mật khẩu không đúng.',
    'UNAUTHENTICATED': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'ACCOUNT_DISABLED': 'Tài khoản đã bị vô hiệu hóa.',
    'PROFILE_INCOMPLETE': 'Vui lòng hoàn thiện hồ sơ cá nhân.',
    'PAIRING_CODE_INVALID': 'Mã ghép đôi không đúng.',
    'PAIRING_CODE_EXPIRED': 'Mã ghép đôi đã hết hạn. Vui lòng tạo mã mới.',
    'PAIRING_CODE_USED': 'Mã này đã được sử dụng.',
    'PAIRING_SELF_NOT_ALLOWED': 'Bạn không thể tự ghép đôi với chính mình.',
    'USER_ALREADY_PAIRED': 'Tài khoản của bạn đã được ghép đôi.',
    'PARTNER_ALREADY_PAIRED': 'Người dùng này đã được ghép đôi.',
    'RELATIONSHIP_NOT_FOUND': 'Không tìm thấy kết nối partner.',
    'SERVER_ERROR': 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
  };

  static String friendly(String code, [String? fallback]) {
    return _messages[code] ?? fallback ?? _messages['SERVER_ERROR']!;
  }
}
