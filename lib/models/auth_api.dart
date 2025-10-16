// lib/services/auth_api.dart
import 'dart:convert';
import 'package:agys_depo_yonetim/services/settings_controller.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? token;
  final int? kullaniciId;
  final int? rolId;
  final int? firmaId;
  final int? antrepoId;
  final String? antrepoKodu;
  final String? message;

  AuthResult({
    required this.success,
    this.token,
    this.kullaniciId,
    this.rolId,
    this.firmaId,
    this.antrepoId,
    this.antrepoKodu,
    this.message,
  });

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    success: j['success'] == true,
    token: j['token']?.toString(),
    kullaniciId: j['kullanici']?['id'] as int?,
    rolId: j['kullanici']?['rolId'] as int?,
    firmaId: j['kullanici']?['firmaId'] as int?,
    antrepoId: j['kullanici']?['antrepoId'] as int?,
    antrepoKodu: j['kullanici']?['antrepoKodu']?.toString(),
    message: j['message']?.toString(),
  );
}

class AuthApi {
  final SettingsController _sc = SettingsController.instance;

  Future<AuthResult> login({
    required String eposta,
    required String sifre,
    required String antrepoKodu,
  }) async {
    await _sc.init();
    final uri = Uri.parse('${_sc.baseUrl}/api/Auth/login');
    final r = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'eposta': eposta,
        'sifre': sifre,
        'antrepoKodu': antrepoKodu,
      }),
    );

    final data = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode == 200 && data is Map<String, dynamic>) {
      final res = AuthResult.fromJson(data);
      if (res.success && res.token != null) {
        _sc.token = res.token!;
        if (res.antrepoId != null) {
          _sc.antrepoId = res.antrepoId!;
        }
      }
      return res;
    }
    if (data is Map<String, dynamic>) {
      return AuthResult.fromJson(data);
    }
    return AuthResult(success: false, message: 'Login failed ${r.statusCode}');
  }
}
