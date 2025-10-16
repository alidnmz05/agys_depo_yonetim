// lib/services/bolge_mock.dart
import '../models/bolge.dart';

class BolgeMockStore {
  final int antrepoId;
  int _seq = 1000;
  final Map<int, Bolge> _byId = {};
  final Map<int, List<int>> _children = {}; // parentId -> child ids
  List<Bolge> get flat => _byId.values.toList();

  BolgeMockStore(this.antrepoId) {
    seed();
  }

  void seed() {
    _byId.clear();
    _children.clear();
    _seq = 1000;

    // Kök (parentId=0 kabul ediyoruz)
    // İlk seviye
    final korA = _add(parentId: 0, kod: 'Koridor-A', sira: 10);
    final korB = _add(parentId: 0, kod: 'Koridor-B', sira: 20);

    // İkinci seviye
    final rafA1 = _add(parentId: korA.id, kod: 'Raf-1', sira: 10);
    _add(parentId: korA.id, kod: 'Raf-2', sira: 20);
    _add(parentId: korB.id, kod: 'Raf-1', sira: 10);

    // Üçüncü seviye
    _add(parentId: rafA1.id, kod: 'Goz-1', sira: 10);
    _add(parentId: rafA1.id, kod: 'Goz-2', sira: 20);
  }

  Bolge _add({required int parentId, required String kod, int? sira}) {
    final id = _seq++;
    final b = Bolge(
      id: id,
      antrepoId: antrepoId,
      parentId: parentId == 0 ? null : parentId,
      ad: kod,
      sira: sira ?? (_children[parentId]?.length ?? 0) * 10,
      tip: null,
      aciklama: null,
      aktif: true,
      childCount: 0,
    );
    _byId[id] = b;
    final list = _children.putIfAbsent(parentId, () => []);
    list.add(id);
    return b;
  }

  List<Bolge> childrenLocal(int? parentId) {
    final pid = parentId ?? 0;
    final ids = _children[pid] ?? const [];
    final items =
        ids.map((id) => _byId[id]!).toList()
          ..sort((a, b) => a.sira.compareTo(b.sira));
    return items
        .map(
          (e) => e.copyWith(childCount: (_children[e.id] ?? const []).length),
        )
        .toList();
  }

  List<Bolge> pathLocal(int id) {
    final out = <Bolge>[];
    Bolge? cur = _byId[id];
    while (cur != null) {
      out.insert(0, cur);
      final pid = cur.parentId ?? 0;
      cur = pid == 0 ? null : _byId[pid];
    }
    return out;
  }

  Bolge create({
    required int? parentId,
    required String kod,
    int? sira,
    String? tip,
    String? aciklama,
    bool aktif = true,
  }) {
    final pid = parentId ?? 0;
    final node = _add(parentId: pid, kod: kod, sira: sira);
    return node.copyWith(childCount: (_children[node.id] ?? const []).length);
  }

  List<Bolge> createMany({
    required int? parentId,
    required String baseName,
    required int count,
    int start = 1,
    String separator = '-',
  }) {
    final out = <Bolge>[];
    for (var i = 0; i < count; i++) {
      final name = '$baseName$separator${start + i}';
      out.add(create(parentId: parentId, kod: name));
    }
    return out;
  }

  Bolge update(Bolge b) {
    final cur = _byId[b.id];
    if (cur == null) return b;
    final nb = cur.copyWith(
      ad: b.ad,
      sira: b.sira,
      tip: b.tip,
      aciklama: b.aciklama,
      // aktif: b.aktif,
    );
    _byId[b.id] = nb;
    return nb;
  }

  void deleteNode(int id) {
    final cur = _byId.remove(id);
    if (cur == null) return;
    final pid = cur.parentId ?? 0;
    _children[pid]?.remove(id);
    // recursive
    final stack = <int>[id];
    while (stack.isNotEmpty) {
      final x = stack.removeLast();
      final kids = _children.remove(x) ?? const [];
      for (final cid in kids) {
        _byId.remove(cid);
        stack.add(cid);
      }
    }
  }
}
