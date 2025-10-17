// lib/services/bolge_services.dart  (named param adapter fix)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings_controller.dart';
import '../models/bolge.dart';

class BolgeApi {
  BolgeApi._();
  static final instance = BolgeApi._();
  final SettingsController _sc = SettingsController.instance;

  List<Bolge> _flat = [];
  List<Bolge> get flat => List.unmodifiable(_flat);

  Map<String, String> _authHeaders() => {
    'Content-Type': 'application/json',
    if (_sc.token.isNotEmpty) 'Authorization': 'Bearer ${_sc.token}',
  };

  // ---------- Core calls ----------

  Future<void> fetchAll() async {
    final uri = Uri.parse(
      '${_sc.baseUrl}/api/YerlesimYeri/antrepo/${_sc.antrepoId}',
    );
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final body = json.decode(r.body) as List;
      _flat =
          body.map((e) => Bolge.fromJson(e as Map<String, dynamic>)).toList();
      _recomputeChildCounts();
      return;
    }
    throw Exception('fetchAll failed ${r.statusCode}: ${r.body}');
  }

  Future<Bolge> getById(int id) async {
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri/$id');
    final r = await http.get(uri, headers: _authHeaders());
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final j = json.decode(r.body) as Map<String, dynamic>;
      return Bolge.fromJson(j);
    }
    throw Exception('getById failed ${r.statusCode}: ${r.body}');
  }

  Future<Bolge> _addNode(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri');
    final r = await http.post(
      uri,
      headers: _authHeaders(),
      body: json.encode(payload),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final j = json.decode(r.body) as Map<String, dynamic>;
      final n = Bolge.fromJson(j);
      _flat.add(n);
      _recomputeChildCounts();
      return n;
    }
    throw Exception('addNode failed ${r.statusCode}: ${r.body}');
  }

  Future<Bolge> _updateNode(Map<String, dynamic> payload) async {
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri');
    final r = await http.put(
      uri,
      headers: _authHeaders(),
      body: json.encode(payload),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final j = json.decode(r.body) as Map<String, dynamic>;
      final n = Bolge.fromJson(j);
      final idx = _flat.indexWhere((e) => e.id == n.id);
      if (idx >= 0) _flat[idx] = n;
      _recomputeChildCounts();
      return n;
    }
    throw Exception('updateNode failed ${r.statusCode}: ${r.body}');
  }

  Future<void> deleteNode(int id) async {
    final uri = Uri.parse('${_sc.baseUrl}/api/YerlesimYeri/$id');
    final r = await http.delete(uri, headers: _authHeaders());
    if (r.statusCode >= 200 && r.statusCode < 300) {
      _flat = _flat.where((e) => e.id != id).toList();
      _recomputeChildCounts();
      return;
    }
    throw Exception('deleteNode failed ${r.statusCode}: ${r.body}');
  }

  // ---------- Adapters expected by bolgeler.dart ----------

  Future<void> refreshFlat({required int antrepoId}) async {
    _sc.antrepoId = antrepoId;
    await fetchAll();
  }

  List<Bolge> childrenLocal({int? parentId}) {
    return _flat.where((e) => e.parentId == parentId).toList()
      ..sort((a, b) => a.sira.compareTo(b.sira));
  }

  List<Bolge> pathLocal({required int id}) {
    final map = {for (final b in _flat) b.id: b};
    final path = <Bolge>[];
    Bolge? cur = map[id];
    while (cur != null) {
      path.insert(0, cur);
      cur = cur.parentId == null ? null : map[cur.parentId!];
    }
    return path;
  }

  /// create({antrepoId, parentId, kod, sira=0, tip, aciklama, aktif=true})
  Future<Bolge> create({
    required int antrepoId,
    int? parentId,
    required String kod,
    int sira = 0,
    String? tip,
    String? aciklama,
    bool? aktif,
  }) async {
    final payload = {
      'antrepoId': antrepoId,
      'ustYerlesimId': parentId,
      'kod': kod,
      'sira': sira,
      'tip': tip,
      'aciklama': aciklama,
      'aktif': aktif ?? true,
    };
    return _addNode(payload);
  }

  /// createMany({baseName, count, start=1, separator='-', parentId, antrepoId})
  Future<List<Bolge>> createMany({
    required String baseName,
    required int count,
    int start = 1,
    String separator = '-',
    int? parentId,
    required int antrepoId,
  }) async {
    final out = <Bolge>[];
    for (int i = 0; i < count; i++) {
      final name = '$baseName$separator${start + i}';
      out.add(
        await create(
          antrepoId: antrepoId,
          parentId: parentId,
          kod: name,
          sira: start + i,
        ),
      );
    }
    return out;
  }

  /// update({id, kod, parentId, sira, tip, aciklama, aktif, antrepoId})
  Future<Bolge> update({
    required int id,
    String? kod,
    int? parentId,
    int? sira,
    String? tip,
    String? aciklama,
    bool? aktif,
    int? antrepoId,
  }) async {
    final current = _flat.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('id not found'),
    );
    final body = {
      'id': id,
      'antrepoId': antrepoId ?? current.antrepoId,
      'ustYerlesimId': parentId ?? current.parentId,
      'kod': kod ?? current.ad,
      'sira': sira ?? current.sira,
      'tip': tip ?? current.tip,
      'aciklama': aciklama ?? current.aciklama,
      'aktif': aktif ?? (current.aktif ?? true),
    };
    return _updateNode(body);
  }

  // ---------- Helpers ----------
  void _recomputeChildCounts() {
    final count = <int, int>{};
    for (final b in _flat) {
      final pid = b.parentId;
      if (pid != null) {
        count[pid] = (count[pid] ?? 0) + 1;
      }
    }
    _flat = _flat.map((b) => b.copyWith(childCount: count[b.id] ?? 0)).toList();
  }
}
