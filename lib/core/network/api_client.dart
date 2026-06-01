import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'error_messages.dart';

class ApiClient {
  final TokenStorage tokenStorage;
  final String baseUrl;
  final http.Client _httpClient;
  final MockApiBackend _mockBackend;

  ApiClient({
    required this.tokenStorage,
    this.baseUrl = ApiConstants.baseUrl,
    http.Client? httpClient,
    MockApiBackend? mockBackend,
  })  : _httpClient = httpClient ?? http.Client(),
        _mockBackend = mockBackend ?? MockApiBackend();

  Future<T> get<T>(
    String path,
    T Function(Object? json) parseData,
  ) {
    return _send<T>('GET', path, null, parseData);
  }

  Future<T> post<T>(
    String path,
    Map<String, dynamic>? body,
    T Function(Object? json) parseData,
  ) {
    return _send<T>('POST', path, body, parseData);
  }

  Future<T> put<T>(
    String path,
    Map<String, dynamic>? body,
    T Function(Object? json) parseData,
  ) {
    return _send<T>('PUT', path, body, parseData);
  }

  Future<T> patch<T>(
    String path,
    Map<String, dynamic>? body,
    T Function(Object? json) parseData,
  ) {
    return _send<T>('PATCH', path, body, parseData);
  }

  Future<T> delete<T>(
    String path,
    Map<String, dynamic>? body,
    T Function(Object? json) parseData,
  ) {
    return _send<T>('DELETE', path, body, parseData);
  }

  Future<T> _send<T>(
    String method,
    String path,
    Map<String, dynamic>? body,
    T Function(Object? json) parseData,
  ) async {
    final token = await tokenStorage.readAccessToken();
    final json = baseUrl.startsWith('mock://')
        ? await _mockBackend.handle(method, path, body, token)
        : await _sendHttp(method, path, body, token);

    final response = ApiResponse<T>.fromJson(json, parseData);
    if (response.success) return response.data as T;

    final error = response.error ??
        const ApiException(code: 'SERVER_ERROR', message: 'Server error');
    throw ApiException(
      code: error.code,
      message: ErrorMessages.friendly(error.code, error.message),
      statusCode: error.statusCode,
    );
  }

  Future<Map<String, dynamic>> _sendHttp(
    String method,
    String path,
    Map<String, dynamic>? body,
    String? token,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    switch (method) {
      case 'GET':
        response = await _httpClient.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _httpClient.post(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'PUT':
        response = await _httpClient.put(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'PATCH':
        response = await _httpClient.patch(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'DELETE':
        response = await _httpClient.delete(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      default:
        throw const ApiException(code: 'SERVER_ERROR', message: 'Unsupported method');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 401 && decoded['success'] != true) {
      throw ApiException(
        code: 'UNAUTHENTICATED',
        message: ErrorMessages.friendly('UNAUTHENTICATED'),
        statusCode: response.statusCode,
      );
    }
    return decoded;
  }
}

class MockApiBackend {
  final Map<String, Map<String, dynamic>> _usersByEmail = {};
  final Map<String, Map<String, dynamic>> _profilesByUserId = {};
  final Map<String, Map<String, dynamic>> _relationshipsByUserId = {};
  final Map<String, Map<String, dynamic>> _pairingCodes = {};

  Future<Map<String, dynamic>> handle(
    String method,
    String path,
    Map<String, dynamic>? body,
    String? token,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (method == 'POST' && path == '/auth/register') return _register(body ?? {});
    if (method == 'POST' && path == '/auth/login') return _login(body ?? {});
    if (method == 'POST' && path == '/auth/logout') return _ok(true);

    final user = _userFromToken(token);
    if (user == null) return _error('UNAUTHENTICATED');

    if (method == 'GET' && path == '/account/me') return _me(user);
    if (method == 'PUT' && path == '/account/profile') return _updateProfile(user, body ?? {});
    if (method == 'POST' && path == '/pairing/generate') return _generateCode(user);
    if (method == 'POST' && path == '/pairing/connect') return _connect(user, body ?? {});
    if (method == 'GET' && path == '/pairing/status') return _pairingStatus(user);
    if (method == 'DELETE' && path == '/pairing/disconnect') return _disconnect(user);

    return _error('SERVER_ERROR');
  }

  Map<String, dynamic> _register(Map<String, dynamic> body) {
    final email = body['email']?.toString().trim().toLowerCase() ?? '';
    final password = body['password']?.toString() ?? '';
    if (!email.contains('@') || password.length < 6) return _error('INVALID_INPUT');
    if (_usersByEmail.containsKey(email)) return _error('EMAIL_ALREADY_EXISTS');

    final now = DateTime.now().toUtc();
    final user = {
      'id': 'user_${_usersByEmail.length + 1}',
      'email': email,
      'phone': null,
      'authProvider': 'email',
      'status': 'active',
      'password': password,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    _usersByEmail[email] = user;

    return _ok({
      'accessToken': 'mock_access_${user['id']}',
      'refreshToken': 'mock_refresh_${user['id']}',
      'user': _publicUser(user),
    });
  }

  Map<String, dynamic> _login(Map<String, dynamic> body) {
    final email = body['email']?.toString().trim().toLowerCase() ?? '';
    final password = body['password']?.toString() ?? '';
    final user = _usersByEmail[email];
    if (user == null || user['password'] != password) {
      return _error('INVALID_EMAIL_OR_PASSWORD');
    }
    return _ok({
      'accessToken': 'mock_access_${user['id']}',
      'refreshToken': 'mock_refresh_${user['id']}',
      'user': _publicUser(user),
    });
  }

  Map<String, dynamic> _me(Map<String, dynamic> user) {
    final relationship = _relationshipsByUserId[user['id']];
    final partnerId = relationship == null
        ? null
        : relationship['userAId'] == user['id']
            ? relationship['userBId']
            : relationship['userAId'];
    final partner = partnerId == null ? null : _findUserById(partnerId);
    return _ok({
      'user': _publicUser(user),
      'profile': _profilesByUserId[user['id']],
      'relationship': relationship,
      'partner': partner == null ? null : _publicUser(partner),
    });
  }

  Map<String, dynamic> _updateProfile(Map<String, dynamic> user, Map<String, dynamic> body) {
    final displayName = body['displayName']?.toString().trim() ?? '';
    if (displayName.isEmpty) return _error('INVALID_INPUT');

    final profile = _profileJson(
      user['id'] as String,
      displayName,
      avatarUrl: body['avatarUrl']?.toString(),
      dateOfBirth: body['dateOfBirth']?.toString(),
      relationshipStartDate: body['relationshipStartDate']?.toString(),
      gender: body['gender']?.toString(),
      bio: body['bio']?.toString(),
    );
    _profilesByUserId[user['id'] as String] = profile;
    return _ok(profile);
  }

  Map<String, dynamic> _generateCode(Map<String, dynamic> user) {
    if (_relationshipsByUserId.containsKey(user['id'])) return _error('USER_ALREADY_PAIRED');

    final code = _randomCode();
    final now = DateTime.now().toUtc();
    final pairing = {
      'id': 'pairing_$code',
      'code': code,
      'createdByUserId': user['id'],
      'status': 'active',
      'expiredAt': now.add(const Duration(minutes: 15)).toIso8601String(),
      'usedByUserId': null,
      'usedAt': null,
      'createdAt': now.toIso8601String(),
    };
    _pairingCodes[code] = pairing;
    return _ok(pairing);
  }

  Map<String, dynamic> _connect(Map<String, dynamic> user, Map<String, dynamic> body) {
    if (_relationshipsByUserId.containsKey(user['id'])) return _error('USER_ALREADY_PAIRED');

    final code = body['code']?.toString().trim().toUpperCase() ?? '';
    final pairing = _pairingCodes[code];
    if (pairing == null) return _error('PAIRING_CODE_INVALID');
    if (pairing['status'] == 'used') return _error('PAIRING_CODE_USED');
    if (DateTime.parse(pairing['expiredAt'] as String).isBefore(DateTime.now().toUtc())) {
      return _error('PAIRING_CODE_EXPIRED');
    }
    if (pairing['createdByUserId'] == user['id']) return _error('PAIRING_SELF_NOT_ALLOWED');
    if (_relationshipsByUserId.containsKey(pairing['createdByUserId'])) {
      return _error('PARTNER_ALREADY_PAIRED');
    }

    final creator = _findUserById(pairing['createdByUserId'] as String);
    if (creator == null) return _error('PAIRING_CODE_INVALID');

    final now = DateTime.now().toUtc();
    final relationship = {
      'id': 'rel_${creator['id']}_${user['id']}',
      'userAId': creator['id'],
      'userBId': user['id'],
      'relationshipStartDate':
          _profilesByUserId[creator['id']]?['relationshipStartDate'] ?? now.toIso8601String(),
      'status': 'active',
      'disconnectedAt': null,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    _relationshipsByUserId[creator['id'] as String] = relationship;
    _relationshipsByUserId[user['id'] as String] = relationship;
    pairing['status'] = 'used';
    pairing['usedByUserId'] = user['id'];
    pairing['usedAt'] = now.toIso8601String();

    return _ok({
      'relationship': relationship,
      'partner': _publicUser(creator),
    });
  }

  Map<String, dynamic> _pairingStatus(Map<String, dynamic> user) {
    final relationship = _relationshipsByUserId[user['id']];
    if (relationship == null) {
      return _ok({'status': 'unpaired', 'relationshipId': null, 'partner': null});
    }
    final partnerId = relationship['userAId'] == user['id']
        ? relationship['userBId']
        : relationship['userAId'];
    final partner = _findUserById(partnerId as String);
    return _ok({
      'status': 'paired',
      'relationshipId': relationship['id'],
      'partner': partner == null ? null : _publicUser(partner),
    });
  }

  Map<String, dynamic> _disconnect(Map<String, dynamic> user) {
    final relationship = _relationshipsByUserId[user['id']];
    if (relationship == null) return _error('RELATIONSHIP_NOT_FOUND');
    final now = DateTime.now().toUtc().toIso8601String();
    relationship['status'] = 'disconnected';
    relationship['disconnectedAt'] = now;
    relationship['updatedAt'] = now;
    _relationshipsByUserId.remove(relationship['userAId']);
    _relationshipsByUserId.remove(relationship['userBId']);
    return _ok(true);
  }

  Map<String, dynamic>? _userFromToken(String? token) {
    if (token == null || !token.startsWith('mock_access_')) return null;
    final userId = token.replaceFirst('mock_access_', '');
    return _findUserById(userId);
  }

  Map<String, dynamic>? _findUserById(String id) {
    for (final user in _usersByEmail.values) {
      if (user['id'] == id) return user;
    }
    return null;
  }

  Map<String, dynamic> _profileJson(
    String userId,
    String displayName, {
    String? avatarUrl,
    String? dateOfBirth,
    String? relationshipStartDate,
    String? gender,
    String? bio,
  }) {
    final now = DateTime.now().toUtc();
    return {
      'id': 'profile_$userId',
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'bio': bio,
      'relationshipStartDate': relationshipStartDate,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
  }

  Map<String, dynamic> _publicUser(Map<String, dynamic> user) {
    final copy = Map<String, dynamic>.from(user);
    copy.remove('password');
    return copy;
  }

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Map<String, dynamic> _ok(Object? data) => {
        'success': true,
        'data': data,
        'error': null,
      };

  Map<String, dynamic> _error(String code) => {
        'success': false,
        'data': null,
        'error': {
          'code': code,
          'message': ErrorMessages.friendly(code),
        },
      };

  
}
