// lib/models/auth_api.dart  (revizyon: OpenAPI uyumlu)
import 'package:dio/dio.dart';
import 'package:agys_depo_yonetim/services/settings_controller.dart';
import 'package:flutter/foundation.dart';

class AuthResult {
  final bool success;
  final String? token;
  final String? message;
  final int? antrepoId;

  const AuthResult({
    required this.success,
    this.token,
    this.message,
    this.antrepoId,
  });

  static AuthResult fromResponse(Response res) {
    String? token;
    int? antrepoId;
    String? msg;

    // 1) Header'da Authorization/Bearer olabilir
    final authH = res.headers['authorization'] ?? res.headers['Authorization'];
    if (authH != null && authH.isNotEmpty) {
      final h = authH.first;
      token = h.startsWith('Bearer ') ? h.substring(7) : h;
    }

    // 2) Body map ise tipik alan isimlerini deneriz
    if (res.data is Map) {
      final m = res.data as Map;
      token =
          (m['token'] ?? m['access_token'] ?? m['jwt'] ?? token)?.toString();
      msg = (m['message'] ?? m['Message'])?.toString();
      final aid = m['antrepoId'] ?? m['AntrepoId'];
      if (aid != null) {
        try {
          antrepoId = int.parse(aid.toString());
        } catch (_) {}
      }
    } else if (res.data is String && (token ?? '').isEmpty) {
      // Body string ise token direkt dönebilir
      final s = (res.data as String).trim();
      if (s.length > 20) token = s;
    }

    return AuthResult(
      success:
          (res.statusCode ?? 0) >= 200 &&
          (res.statusCode ?? 0) < 300 &&
          token != null &&
          token.isNotEmpty,
      token: token,
      message: msg,
      antrepoId: antrepoId,
    );
  }
}

class AuthApi {
  AuthApi._();
  static final instance = AuthApi._();
  final _sc = SettingsController.instance;

  Dio _dio() => Dio(
    BaseOptions(
      baseUrl: _sc.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// POST /api/Auth/login
  /// Body: { eposta, sifre, antrepoKodu }
  Future<AuthResult> login({
    required String eposta,
    required String sifre,
    required String antrepoKodu,
    CancelToken? cancelToken,
  }) async {
    final dio = _dio();
    final paths = [
      '/api/Auth/Login',
      '/api/Auth/login',
      '/Auth/Login',
      '/Auth/login',
    ];

    for (final p in paths) {
      try {
        if (kDebugMode) {
          // isteğin nereye gittiğini görmek için
          // ignore: avoid_print
          print('[AUTH] POST ${_sc.baseUrl}$p');
        }
        final res = await dio.post<Map<String, dynamic>>(
          p,
          data: {
            'eposta': eposta.trim(),
            'sifre': sifre,
            'antrepoKodu': antrepoKodu.trim(),
          },
          cancelToken: cancelToken,
        );

        final ar = AuthResult.fromResponse(res);
        if (ar.success && (ar.token ?? '').isNotEmpty) {
          _sc.token = ar.token!;
          if (ar.antrepoId != null) _sc.antrepoId = ar.antrepoId!;
        }
        return ar;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 404) continue; // diğer path'i dene
        final msg =
            e.response?.data is Map
                ? ((e.response?.data as Map)['message']?.toString() ?? '')
                : e.message;
        return AuthResult(
          success: false,
          message:
              msg?.isNotEmpty == true ? msg : 'Login failed (${code ?? 0})',
        );
      }
    }

    return const AuthResult(
      success: false,
      message: 'Login endpoint not found (404)',
    );
  }
}
