// lib/services/bolge_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'settings_controller.dart';
import '../models/bolge.dart';
import 'bolge_mock.dart';

/// Mock açık: API kapalıyken yerel bellekten çalışır.
const bool _useMock = true;

class BolgeApi {
  BolgeApi._();
  static final instance = BolgeApi._();

  final SettingsController _sc = SettingsController.instance;

  // Mock store ve düz cache
  BolgeMockStore? _mock;
  List<Bolge> _flat = const [];

  Map<String, String> _authHeaders() => {
    'Authorization': 'Bearer ${_sc.token}',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<void> refreshFlat({int? antrepoId}) async {
    await _sc.init();
    final id = antrepoId ?? _sc.antrepoId;
    if (_useMock) {
      _mock ??= BolgeMockStore(id);
      _flat = _mock!.flat;
      return;
    }
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri/antrepo/$id');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final list =
          (data['data'] as List).map((e) => Bolge.fromJson(e)).toList();
      _flat = list;
      return;
    }
    throw Exception('antrepo list failed ${r.statusCode}: ${r.body}');
  }

  List<Bolge> childrenLocal(int? parentId, {int? antrepoId}) {
    if (_useMock) {
      _mock ??= BolgeMockStore(antrepoId ?? _sc.antrepoId);
      return _mock!.childrenLocal(parentId);
    }
    final pid = parentId ?? 0;
    final aId = antrepoId ?? _sc.antrepoId;
    final byParent =
        _flat
            .where((e) => (e.parentId ?? 0) == pid && e.antrepoId == aId)
            .toList()
          ..sort((a, b) => a.sira.compareTo(b.sira));
    return byParent.map((e) {
      final cc = _flat.where((x) => (x.parentId ?? 0) == e.id).length;
      return e.copyWith(childCount: cc);
    }).toList();
  }

  List<Bolge> pathLocal(int id) {
    if (_useMock) {
      _mock ??= BolgeMockStore(_sc.antrepoId);
      return _mock!.pathLocal(id);
    }
    final out = <Bolge>[];
    final byId = {for (final e in _flat) e.id: e};
    var cur = byId[id];
    while (cur != null) {
      out.insert(0, cur);
      final pid = cur.parentId ?? 0;
      cur = pid == 0 ? null : byId[pid];
    }
    return out;
  }

  Future<Bolge> create({
    required int antrepoId,
    required int? parentId,
    required String kod,
    int? sira,
    String? tip,
    String? aciklama,
    bool aktif = true,
  }) async {
    await _sc.init();
    if (_useMock) {
      _mock ??= BolgeMockStore(antrepoId);
      final b = _mock!.create(
        parentId: parentId,
        kod: kod,
        sira: sira,
        tip: tip,
        aciklama: aciklama,
        aktif: aktif,
      );
      _flat = _mock!.flat;
      return b;
    }
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri');
    final body = {
      'ustYerlesimId': parentId,
      'antrepoId': antrepoId,
      'kod': kod,
      'sira': sira ?? 0,
      'tip': tip,
      'aciklama': aciklama,
      'aktif': aktif,
    };
    final r = await http.post(
      uri,
      headers: _authHeaders(),
      body: jsonEncode(body),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final b = Bolge.fromJson(data['data']);
      _flat = [..._flat, b];
      return b;
    }
    throw Exception('create failed ${r.statusCode}: ${r.body}');
  }

  Future<List<Bolge>> createMany({
    required int antrepoId,
    required int? parentId,
    required String baseName,
    required int count,
    int start = 1,
    String separator = '-',
    int? siraStart,
    int siraStep = 10,
  }) async {
    if (_useMock) {
      _mock ??= BolgeMockStore(antrepoId);
      final list = _mock!.createMany(
        parentId: parentId,
        baseName: baseName,
        count: count,
        start: start,
        separator: separator,
      );
      _flat = _mock!.flat;
      return list;
    }
    final out = <Bolge>[];
    for (var i = 0; i < count; i++) {
      final kod = '$baseName$separator${start + i}';
      final sira = siraStart == null ? null : siraStart + i * siraStep;
      out.add(
        await create(
          antrepoId: antrepoId,
          parentId: parentId,
          kod: kod,
          sira: sira,
        ),
      );
    }
    return out;
  }

  Future<Bolge> update(Bolge b) async {
    await _sc.init();
    if (_useMock) {
      _mock ??= BolgeMockStore(_sc.antrepoId);
      final nb = _mock!.update(b);
      _flat = _mock!.flat;
      return nb;
    }
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri');
    final r = await http.put(
      uri,
      headers: _authHeaders(),
      body: jsonEncode({
        'id': b.id,
        'ustYerlesimId': b.parentId,
        'antrepoId': b.antrepoId,
        'kod': b.ad,
        'sira': b.sira,
        'tip': b.tip,
        'aciklama': b.aciklama,
        'aktif': b.aktif,
      }),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final nb = Bolge.fromJson(data['data']);
      _flat = _flat.map((x) => x.id == nb.id ? nb : x).toList();
      return nb;
    }
    throw Exception('update failed ${r.statusCode}: ${r.body}');
  }

  Future<void> deleteNode(int id) async {
    await _sc.init();
    if (_useMock) {
      _mock ??= BolgeMockStore(_sc.antrepoId);
      _mock!.deleteNode(id);
      _flat = _mock!.flat;
      return;
    }
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri/$id');
    final r = await http.delete(uri, headers: _authHeaders());
    if (r.statusCode >= 200 && r.statusCode < 300) {
      _flat = _flat.where((e) => e.id != id).toList();
      return;
    }
    throw Exception('delete failed ${r.statusCode}: ${r.body}');
  }
}
