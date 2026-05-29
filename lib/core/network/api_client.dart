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

  final List<Map<String, dynamic>> _mockMilestones = [
    {
      'id': 'm1',
      'userId': 'user_1',
      'relationshipId': 'rel_user_1_user_2',
      'title': 'First Meeting',
      'date': '2024-01-14',
      'icon': '👋',
      'type': 'memory',
      'isCompleted': false,
      'createdAt': '2026-05-29T00:00:00Z',
      'updatedAt': '2026-05-29T00:00:00Z',
    },
    {
      'id': 'm2',
      'userId': 'user_1',
      'relationshipId': 'rel_user_1_user_2',
      'title': '100 Days Anniversary',
      'date': '2024-04-23',
      'icon': '💯',
      'type': 'memory',
      'isCompleted': false,
      'createdAt': '2026-05-29T00:00:00Z',
      'updatedAt': '2026-05-29T00:00:00Z',
    },
    {
      'id': 'm3',
      'userId': 'user_1',
      'relationshipId': 'rel_user_1_user_2',
      'title': "Valentine's Day 2025",
      'date': '2025-02-14',
      'icon': '💝',
      'type': 'memory',
      'isCompleted': false,
      'createdAt': '2026-05-29T00:00:00Z',
      'updatedAt': '2026-05-29T00:00:00Z',
    },
    {
      'id': 'm4',
      'userId': 'user_1',
      'relationshipId': 'rel_user_1_user_2',
      'title': 'Call partner for 1 hour',
      'date': '2025-06-15',
      'icon': '📞',
      'type': 'challenge',
      'isCompleted': true,
      'createdAt': '2026-05-29T00:00:00Z',
      'updatedAt': '2026-05-29T00:00:00Z',
    },
    {
      'id': 'm5',
      'userId': 'user_1',
      'relationshipId': 'rel_user_1_user_2',
      'title': 'Cook dinner together',
      'date': '2025-06-20',
      'icon': '🍳',
      'type': 'challenge',
      'isCompleted': false,
      'createdAt': '2026-05-29T00:00:00Z',
      'updatedAt': '2026-05-29T00:00:00Z',
    },
  ];

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
    if (method == 'POST' && path == '/account/relationship/shift-date') return _shiftDate(user);
    if (method == 'POST' && path == '/pairing/generate') return _generateCode(user);
    if (method == 'POST' && path == '/pairing/connect') return _connect(user, body ?? {});
    if (method == 'GET' && path == '/pairing/status') return _pairingStatus(user);
    if (method == 'DELETE' && path == '/pairing/disconnect') return _disconnect(user);

    // Milestones routes
    if (method == 'GET' && path == '/milestones') return _getMilestones(user);
    if (method == 'POST' && path == '/milestones') return _createMilestone(user, body ?? {});
    if (method == 'PUT' && path.startsWith('/milestones/')) {
      final id = path.replaceFirst('/milestones/', '');
      return _updateMilestone(user, id, body ?? {});
    }
    if (method == 'DELETE' && path.startsWith('/milestones/')) {
      final id = path.replaceFirst('/milestones/', '');
      return _deleteMilestone(user, id);
    }

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

  Map<String, dynamic> _getMilestones(Map<String, dynamic> user) {
    return _ok(_mockMilestones);
  }

  Map<String, dynamic> _createMilestone(Map<String, dynamic> user, Map<String, dynamic> body) {
    final now = DateTime.now().toUtc().toIso8601String();
    final milestone = {
      'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
      'userId': user['id'],
      'relationshipId': _relationshipsByUserId[user['id']]?['id'],
      'title': body['title']?.toString() ?? '',
      'date': body['date']?.toString() ?? '',
      'icon': body['icon']?.toString() ?? '🎉',
      'type': body['type']?.toString() ?? 'memory',
      'isCompleted': body['isCompleted'] as bool? ?? false,
      'createdAt': now,
      'updatedAt': now,
    };
    _mockMilestones.add(milestone);
    return _ok(milestone);
  }

  Map<String, dynamic> _updateMilestone(Map<String, dynamic> user, String id, Map<String, dynamic> body) {
    final index = _mockMilestones.indexWhere((item) => item['id'] == id);
    if (index == -1) return _error('SERVER_ERROR');
    
    final item = _mockMilestones[index];
    item['title'] = body['title']?.toString() ?? item['title'];
    item['date'] = body['date']?.toString() ?? item['date'];
    item['icon'] = body['icon']?.toString() ?? item['icon'];
    item['type'] = body['type']?.toString() ?? item['type'] ?? 'memory';
    item['isCompleted'] = body['isCompleted'] as bool? ?? item['isCompleted'] ?? false;
    item['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    
    return _ok(item);
  }

  Map<String, dynamic> _deleteMilestone(Map<String, dynamic> user, String id) {
    _mockMilestones.removeWhere((item) => item['id'] == id);
    return _ok(true);
  }

  Map<String, dynamic> _shiftDate(Map<String, dynamic> user) {
    final relationship = _relationshipsByUserId[user['id']];
    final profile = _profilesByUserId[user['id']];
    
    String? currentDateString = relationship != null 
      ? relationship['relationshipStartDate']?.toString()
      : (profile != null ? profile['relationshipStartDate']?.toString() : null);
      
    currentDateString ??= DateTime.now().toUtc().toIso8601String();
    
    final currentDate = DateTime.parse(currentDateString);
    final newDate = currentDate.subtract(const Duration(days: 1));
    final newDateString = newDate.toUtc().toIso8601String();
    
    if (relationship != null) {
      relationship['relationshipStartDate'] = newDateString;
    }
    
    // Always upsert to profile for safety
    if (profile != null) {
      profile['relationshipStartDate'] = newDateString;
    } else {
      _profilesByUserId[user['id']] = {
        'userId': user['id'],
        'displayName': 'Partner',
        'relationshipStartDate': newDateString,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
    }
    
    return _ok({'newStartDate': newDateString});
  }
}
