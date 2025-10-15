import '../models/bolge.dart';

class BolgeMockStore {
  // parentId -> list
  final Map<int, List<Bolge>> _byParent = {};
  final Map<int, Bolge> _byId = {};
  int _seq = 1000;

  BolgeMockStore(int antrepoId) {
    // örnek ağaç
    _seed(antrepoId);
  }

  void _seed(int antrepoId) {
    // kök çocukları
    final koridor = _add(parentId: 0, antrepoId: antrepoId, ad: 'Koridor-A');
    final koridor2 = _add(parentId: 0, antrepoId: antrepoId, ad: 'Koridor-B');
    final raf1 = _add(parentId: koridor.id, antrepoId: antrepoId, ad: 'Raf-01');
    _add(parentId: koridor.id, antrepoId: antrepoId, ad: 'Raf-02');
    _add(parentId: koridor2.id, antrepoId: antrepoId, ad: 'Raf-01');
    _add(parentId: raf1.id, antrepoId: antrepoId, ad: 'Göz-01');
    _add(parentId: raf1.id, antrepoId: antrepoId, ad: 'Göz-02');
  }

  Bolge _add({
    required int parentId,
    required int antrepoId,
    required String ad,
    String? kod,
    int? sira,
  }) {
    final id = _seq++;
    final list = _byParent.putIfAbsent(parentId, () => []);
    final node = Bolge(
      id: id,
      antrepoId: antrepoId,
      parentId: parentId == 0 ? null : parentId,
      ad: ad,
      kod: kod,
      sira: sira ?? list.length,
      childCount: 0,
    );
    list.add(node);
    _byId[id] = node;
    // parent’ın childCount’unu güncellemek yerine dinamik hesaplayacağız
    return node;
  }

  List<Bolge> children(int parentId, int antrepoId) {
    final raw = _byParent[parentId] ?? const [];
    return raw
        .where((e) => e.antrepoId == antrepoId)
        .map(
          (e) => e.copyWith(childCount: (_byParent[e.id] ?? const []).length),
        )
        .toList()
      ..sort((a, b) => a.sira.compareTo(b.sira));
  }

  List<Bolge> pathOf(int id) {
    final path = <Bolge>[];
    var cur = _byId[id];
    while (cur != null) {
      path.insert(0, cur);
      final pid = cur.parentId ?? 0;
      cur = pid == 0 ? null : _byId[pid];
    }
    return path;
  }

  List<Bolge> tree(int antrepoId) {
    // düz liste döndür (id,parentId,ad,sira,childCount)
    return _byId.values
        .where((e) => e.antrepoId == antrepoId)
        .map(
          (e) => e.copyWith(childCount: (_byParent[e.id] ?? const []).length),
        )
        .toList();
  }

  Bolge create({
    required int antrepoId,
    required int? parentId,
    required String ad,
    String? kod,
    int? sira,
  }) {
    final pid = parentId ?? 0;
    final node = _add(
      parentId: pid,
      antrepoId: antrepoId,
      ad: ad,
      kod: kod,
      sira: sira,
    );
    return node.copyWith(childCount: (_byParent[node.id] ?? const []).length);
  }

  int bulk({
    required int parentId,
    required String pattern,
    required int count,
    int start = 1,
    int? sira,
  }) {
    int created = 0;
    for (int i = 0; i < count; i++) {
      final n = start + i;
      final name = _subst(pattern, n);
      final parent = parentId == 0 ? null : _byId[parentId];
      _add(
        parentId: parentId,
        antrepoId: parent?.antrepoId ?? 1,
        ad: name,
        sira: sira,
      );
      created++;
    }
    return created;
  }

  void rename(int id, String ad) {
    final n = _byId[id];
    if (n == null) return;
    final updated = n.copyWith(ad: ad);
    _byId[id] = updated;
    final list = _byParent[n.parentId ?? 0];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == id);
    if (idx >= 0) list[idx] = updated;
  }

  void deleteNode(int id) {
    final n = _byId.remove(id);
    if (n == null) return;
    _byParent[n.parentId ?? 0]?.removeWhere((e) => e.id == id);
    // altları da basitçe temizle
    final stack = [id];
    while (stack.isNotEmpty) {
      final pid = stack.removeLast();
      final children = _byParent.remove(pid) ?? const [];
      for (final c in children) {
        _byId.remove(c.id);
        stack.add(c.id);
      }
    }
  }

  String _subst(String pattern, int n) {
    final hasNum =
        RegExp(r'\{0*1\}').hasMatch(pattern) || pattern.contains('{1}');
    final hasAZ = pattern.contains('{A}');
    final hasaz = pattern.contains('{a}');
    String x = pattern;
    if (hasNum) {
      final m = RegExp(r'\{(0*)(1)\}').firstMatch(pattern);
      if (m != null) {
        final pad = m.group(1)!;
        final width = 1 + pad.length;
        final s = n.toString().padLeft(width, '0');
        x = x.replaceFirst(m.group(0)!, s);
      } else {
        x = x.replaceFirst('{1}', n.toString());
      }
    }
    if (hasAZ) {
      final ch = String.fromCharCode('A'.codeUnitAt(0) + (n - 1) % 26);
      x = x.replaceFirst('{A}', ch);
    }
    if (hasaz) {
      final ch = String.fromCharCode('a'.codeUnitAt(0) + (n - 1) % 26);
      x = x.replaceFirst('{a}', ch);
    }
    return x;
  }
}
