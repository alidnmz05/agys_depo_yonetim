// lib/services/api_service.dart
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'settings_controller.dart';
import '../models/giris_kalan_bilgi_dto.dart';

class ApiService {
  factory ApiService() => instance;
  ApiService._internal()
    : _dio = Dio(
        BaseOptions(
          baseUrl:
              'http://213.159.6.209:65062', // başlangıç; runtime'da ayardan set edilir
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
          validateStatus: (c) => c != null && c >= 200 && c < 600,
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          responseBody: false,
          error: true,
          requestHeader: false,
          responseHeader: false,
          requestBody: false,
        ),
      );
    }
  }

  static final ApiService instance = ApiService._internal();
  final Dio _dio;
  static const String _path = '/GirisIslemleri/GirisKalanBilgiGetirPublic';

  Future<List<GirisKalanBilgiDto>> listGirisKalanBilgi({
    int? antrepoId,
    String? apiKey,
    CancelToken? cancelToken,
  }) async {
    final sc = SettingsController.instance;

    // Base URL'yi çalışma zamanında uygula
    final cfgBase = sc.baseUrl.trim();
    if (cfgBase.isNotEmpty && _dio.options.baseUrl != cfgBase) {
      _dio.options.baseUrl = cfgBase;
    }

    final id = antrepoId ?? sc.antrepoId;
    final key = (apiKey ?? sc.apiKey).trim();

    // Anahtar yoksa mock
    if (key.isEmpty) return _mock();

    // Yanlış giriş koruması
    if (key.startsWith('http')) {
      throw ApiException(message: 'apiKey hatalı: URL verilmiş', code: -2);
    }

    try {
      final res = await _dio.get<Map<String, dynamic>>(
        _path,
        queryParameters: {'antrepoId': id, 'apiKey': key},
        cancelToken: cancelToken,
      );

      final status = res.statusCode ?? 0;
      final data = res.data ?? const <String, dynamic>{};
      final code = data['Code'] as int? ?? status;
      final message = data['Message'] as String? ?? '';

      final result = data['Result'] as Map<String, dynamic>?;
      if (result == null) {
        throw ApiException(
          message: 'Geçersiz yanıt: Result yok',
          code: code,
          serverMessage: message,
        );
      }

      final success = result['Success'] as bool? ?? false;
      final value = result['Value'];

      if (!success && code == 200) return const <GirisKalanBilgiDto>[];
      if (!success) {
        throw ApiException(
          message: message.isEmpty ? 'İşlem başarısız' : message,
          code: code,
          serverMessage: message,
        );
      }
      if (value is! List) {
        throw ApiException(
          message: 'Geçersiz yanıt: Value liste değil',
          code: code,
          serverMessage: message,
        );
      }

      return value
          .where((e) => e != null)
          .map(
            (e) => GirisKalanBilgiDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw ApiException(message: 'İstek iptal edildi', code: -499);
      }
      final status = e.response?.statusCode ?? 0;
      final serverMsg = _msg(e.response?.data);
      throw ApiException(
        message: serverMsg ?? (e.message ?? 'Ağ hatası'),
        code: status,
        serverMessage: serverMsg,
      );
    } catch (e) {
      throw ApiException(message: e.toString(), code: -1);
    }
  }

  // Eski ad
  Future<List<GirisKalanBilgiDto>> fetchGirisKalan({
    int? antrepoId,
    String? apiKey,
    CancelToken? cancelToken,
  }) => listGirisKalanBilgi(
    antrepoId: antrepoId,
    apiKey: apiKey,
    cancelToken: cancelToken,
  );

  List<GirisKalanBilgiDto> _mock() => <GirisKalanBilgiDto>[
    GirisKalanBilgiDto(
      defterSiraNo: 101,
      girisBaslikId: 5001,
      beyannameNo: '2025/0001',
      beyannameTarihi: DateTime.now().subtract(const Duration(days: 2)),
      esyaTanimi: 'Örnek Malzeme A',
      aliciFirma: 'Demir Lojistik A.Ş.',
      kalanKap: 12,
      kalanBrutKg: 240.0,
      ozetBeyanNo: 'OB-12345',
      girenToplamBrutKg: 500.0,
      cikanToplamBrutKg: 260.0,
    ),
    GirisKalanBilgiDto(
      defterSiraNo: 102,
      girisBaslikId: 5002,
      beyannameNo: '2025/0002',
      beyannameTarihi: DateTime.now().subtract(const Duration(days: 1)),
      esyaTanimi: 'Örnek Malzeme B',
      aliciFirma: 'Yıldız Dış Ticaret',
      kalanKap: 5,
      kalanBrutKg: 75.5,
    ),
  ];

  static String? _msg(dynamic data) {
    try {
      if (data is Map && data['Message'] is String)
        return data['Message'] as String;
      if (data is Map && data['error'] is String)
        return data['error'] as String;
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int code;
  final String? serverMessage;
  ApiException({required this.message, required this.code, this.serverMessage});
  @override
  String toString() {
    final sm =
        (serverMessage == null || serverMessage!.isEmpty)
            ? ''
            : ' ($serverMessage)';
    return 'ApiException[$code]: $message$sm';
  }
}
