// lib/services/bolge_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'settings_controller.dart';
import '../models/bolge.dart';
import 'bolge_mock.dart';

/// API hazır olana kadar mock veriyi kullanın. Hazır olduğunda false yapın.
const bool _useMock = true;

class BolgeApi {
  BolgeApi._();
  static final instance = BolgeApi._();

  // ---- HTTP endpoint yollarınızı backend'e göre uyarlayın ----
  static const String _childrenPath = '/Bolge/Children';
  static const String _pathPath = '/Bolge/Path';
  static const String _treePath = '/Bolge/Tree';
  static const String _createPath = '/Bolge';
  static String _updatePath(int id) => '/Bolge/$id';
  static String _deletePath(int id) => '/Bolge/$id';

  // ---- MOCK STORE ----
  final BolgeMockStore _mock = BolgeMockStore(
    SettingsController.instance.antrepoId,
  );

  // ---- HTTP yardımcıları ----
  Future<http.Response> _get(String path, Map<String, String> qp) async {
    final s = SettingsController.instance;
    await s.init();
    final uri = Uri.parse(
      s.baseUrl + path,
    ).replace(queryParameters: {...qp, 'apiKey': s.apiKey});
    return http.get(uri);
  }

  Future<http.Response> _post(String path, Map body) async {
    final s = SettingsController.instance;
    await s.init();
    final uri = Uri.parse(
      s.baseUrl + path,
    ).replace(queryParameters: {'apiKey': s.apiKey});
    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _patch(String path, Map body) async {
    final s = SettingsController.instance;
    await s.init();
    final uri = Uri.parse(
      s.baseUrl + path,
    ).replace(queryParameters: {'apiKey': s.apiKey});
    return http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<http.Response> _delete(String path) async {
    final s = SettingsController.instance;
    await s.init();
    final uri = Uri.parse(
      s.baseUrl + path,
    ).replace(queryParameters: {'apiKey': s.apiKey});
    return http.delete(uri);
  }

  // ---- İŞLEVLER ----

  Future<List<Bolge>> children({
    required int parentId,
    required int antrepoId,
  }) async {
    if (_useMock) {
      return _mock.children(parentId, antrepoId);
    }
    final r = await _get(_childrenPath, {
      'parentId': '$parentId',
      'antrepoId': '$antrepoId',
    });
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      return data.map((e) => Bolge.fromJson(e)).toList();
    }
    throw Exception('children ${r.statusCode}: ${r.body}');
  }

  Future<List<Bolge>> pathOf({required int id}) async {
    if (_useMock) {
      return _mock.pathOf(id);
    }
    final r = await _get(_pathPath, {'id': '$id'});
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      return data.map((e) => Bolge.fromJson(e)).toList();
    }
    throw Exception('path ${r.statusCode}: ${r.body}');
  }

  Future<List<Bolge>> tree({required int antrepoId}) async {
    if (_useMock) {
      return _mock.tree(antrepoId);
    }
    final r = await _get(_treePath, {'antrepoId': '$antrepoId'});
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes)) as List;
      return data.map((e) => Bolge.fromJson(e)).toList();
    }
    throw Exception('tree ${r.statusCode}: ${r.body}');
  }

  Future<Bolge> create({
    required int antrepoId,
    required int? parentId,
    required String ad,
    String? kod,
    int? sira,
  }) async {
    if (_useMock) {
      return _mock.create(
        antrepoId: antrepoId,
        parentId: parentId,
        ad: ad,
        kod: kod,
        sira: sira,
      );
    }
    final r = await _post(_createPath, {
      'antrepoId': antrepoId,
      'parentId': parentId,
      'ad': ad,
      'kod': kod,
      'sira': sira,
    });
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      return Bolge.fromJson(data);
    }
    throw Exception('create ${r.statusCode}: ${r.body}');
  }

  /// Bir isme göre çoklu ekleme. Backend'de toplu uç yoksa tek tek create çağrılır.
  Future<List<Bolge>> createMany({
    required int antrepoId,
    required int? parentId,
    required String baseName,
    required int count,
    int start = 1,
    String separator = '-',
  }) async {
    if (count <= 0) return const [];
    final out = <Bolge>[];
    for (var i = 0; i < count; i++) {
      final name = '$baseName$separator${start + i}';
      out.add(await create(antrepoId: antrepoId, parentId: parentId, ad: name));
    }
    return out;
  }

  Future<void> rename({required int id, required String ad}) async {
    if (_useMock) {
      _mock.rename(id, ad);
      return;
    }
    final r = await _patch(_updatePath(id), {'ad': ad});
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw Exception('rename ${r.statusCode}: ${r.body}');
  }

  Future<void> deleteNode({required int id}) async {
    if (_useMock) {
      _mock.deleteNode(id);
      return;
    }
    final r = await _delete(_deletePath(id));
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw Exception('delete ${r.statusCode}: ${r.body}');
  }
}
