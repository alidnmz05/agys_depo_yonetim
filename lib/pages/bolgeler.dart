// lib/pages/bolge_page.dart
import 'package:agys_depo_yonetim/services/bolge_services.dart';
import 'package:flutter/material.dart';
import '../services/settings_controller.dart';
import '../models/bolge.dart';

class BolgePage extends StatefulWidget {
  const BolgePage({super.key});
  @override
  State<BolgePage> createState() => _BolgePageState();
}

class _BolgePageState extends State<BolgePage> {
  final api = BolgeApi.instance;
  final sc = SettingsController.instance;
  final _q = TextEditingController();

  int? _currentParentId; // null -> kök (parentId=0)
  List<Bolge> _items = [];
  List<Bolge> _filtered = [];
  bool _loading = true;
  String? _err;
  List<Bolge> _path = [];

  // Çoklu seçim
  bool _selectMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _q.addListener(_apply);
    _init();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await sc.init();
      // Login sonrası bir kez düz listeyi çek
      await api.refreshFlat(antrepoId: sc.antrepoId);
      _reloadLocal();
    } catch (e) {
      _err = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reloadLocal() {
    final parentId = _currentParentId;
    if (parentId == null) {
      _items = api.childrenLocal(null, antrepoId: sc.antrepoId);
      _path = [];
    } else {
      _items = api.childrenLocal(parentId, antrepoId: sc.antrepoId);
      _path = api.pathLocal(parentId);
    }
    _apply();
  }

  void _apply() {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _items);
      return;
    }
    setState(() {
      _filtered = _items.where((e) => e.ad.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _open(Bolge b) async {
    if (_selectMode) {
      _toggleSelected(b.id);
      return;
    }
    _currentParentId = b.id;
    _reloadLocal();
  }

  Future<void> _goUpTo(int? parentId) async {
    _currentParentId = parentId;
    _reloadLocal();
  }

  Future<void> _createNode({required int? parentId}) async {
    final res = await showDialog<_CreateManyParams>(
      context: context,
      builder: (_) => const _CreateManyDialog(),
    );
    if (res == null) return;

    if (res.count <= 1) {
      await api.create(
        antrepoId: sc.antrepoId,
        parentId: parentId,
        kod: res.baseName,
      );
    } else {
      await api.createMany(
        antrepoId: sc.antrepoId,
        parentId: parentId,
        baseName: res.baseName,
        count: res.count,
        start: res.start,
        separator: res.separator,
      );
    }
    _reloadLocal();
  }

  Future<void> _rename(Bolge b) async {
    final ad = await _promptText(
      title: 'Yeniden Adlandır',
      label: 'Yeni ad',
      initial: b.ad,
    );
    if (ad == null || ad.isEmpty || ad == b.ad) return;
    await api.update(b.copyWith(ad: ad));
    _reloadLocal();
  }

  Future<void> _delete(Bolge b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Sil'),
            content: Text('"${b.ad}" silinsin mi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    await api.deleteNode(b.id);
    _reloadLocal();
  }

  // Çoklu silme
  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Seçili ${_selected.length} öğe silinsin mi?'),
            content: const Text('Bu işlem geri alınamaz.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    for (final id in _selected.toList()) {
      await api.deleteNode(id);
    }
    _selected.clear();
    _selectMode = false;
    _reloadLocal();
  }

  void _toggleSelected(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
      if (_selected.isEmpty) _selectMode = false;
    });
  }

  void _enterSelectMode(Bolge b) {
    setState(() {
      _selectMode = true;
      _selected
        ..clear()
        ..add(b.id);
    });
  }

  void _selectAll() {
    setState(() {
      _selectMode = true;
      _selected
        ..clear()
        ..addAll(_filtered.map((e) => e.id));
    });
  }

  void _cancelSelect() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    String? initial,
  }) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: c,
              decoration: InputDecoration(labelText: label),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, c.text.trim()),
                child: const Text('Kaydet'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _selectMode
                ? Text('${_selected.length} seçildi')
                : const Text('Bölge Yönetimi'),
        leading:
            _selectMode
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelSelect,
                )
                : null,
        actions:
            _selectMode
                ? [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    tooltip: 'Tümünü seç',
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Seçilileri sil',
                    onPressed: _deleteSelected,
                  ),
                ]
                : [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      await api.refreshFlat(antrepoId: sc.antrepoId);
                      _reloadLocal();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _createNode(parentId: _currentParentId),
                  ),
                ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _q,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Bölge ara',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) return Center(child: Text('Hata: $_err'));
    return Column(
      children: [
        _BreadcrumbBar(
          path: _path,
          onRoot: () => _goUpTo(null),
          onTap: (idx) => _goUpTo(idx >= 0 ? _path[idx].id : null),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = _filtered[i];
              final selected = _selected.contains(b.id);
              return ListTile(
                onTap: () => _open(b),
                onLongPress: () => _enterSelectMode(b),
                leading:
                    _selectMode
                        ? Checkbox(
                          value: selected,
                          onChanged: (_) => _toggleSelected(b.id),
                        )
                        : null,
                title: Text(b.ad),
                subtitle:
                    b.childCount > 0 ? Text('${b.childCount} alt öğe') : null,
                trailing:
                    _selectMode
                        ? null
                        : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (b.childCount > 0)
                              const Icon(Icons.chevron_right),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                switch (v) {
                                  case 'add':
                                    _createNode(parentId: b.id);
                                    break;
                                  case 'rename':
                                    _rename(b);
                                    break;
                                  case 'delete':
                                    _delete(b);
                                    break;
                                }
                              },
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'add',
                                      child: Text('Alt Bölge Ekle'),
                                    ),
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text('Yeniden Adlandır'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Sil'),
                                    ),
                                  ],
                            ),
                          ],
                        ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BreadcrumbBar extends StatelessWidget {
  final List<Bolge> path;
  final VoidCallback onRoot;
  final void Function(int idx) onTap;

  const _BreadcrumbBar({
    required this.path,
    required this.onRoot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFF7F9FC),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          InkWell(
            onTap: onRoot,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Text('Kök', style: TextStyle(color: Colors.blue)),
            ),
          ),
          for (int i = 0; i < path.length; i++) ...[
            const Text(' / ', style: TextStyle(color: Colors.black54)),
            InkWell(
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  path[i].ad,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---- Çoklu ekleme diyaloğu ----
class _CreateManyParams {
  final String baseName;
  final int count;
  final int start;
  final String separator;
  const _CreateManyParams(
    this.baseName,
    this.count,
    this.start,
    this.separator,
  );
}

class _CreateManyDialog extends StatefulWidget {
  const _CreateManyDialog({super.key});
  @override
  State<_CreateManyDialog> createState() => _CreateManyDialogState();
}

class _CreateManyDialogState extends State<_CreateManyDialog> {
  final _name = TextEditingController(text: 'Raf');
  final _count = TextEditingController(text: '1');
  final _start = TextEditingController(text: '1');
  final _sep = TextEditingController(text: '-');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'İsim (ör. Raf)'),
            autofocus: true,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _count,
                  decoration: const InputDecoration(labelText: 'Adet'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _start,
                  decoration: const InputDecoration(labelText: 'Başlangıç No'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          TextField(
            controller: _sep,
            decoration: const InputDecoration(labelText: 'Ayraç'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Örnek: ${_name.text}-${_start.text} ...',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () {
            final base = _name.text.trim();
            final cnt = int.tryParse(_count.text.trim()) ?? 1;
            final st = int.tryParse(_start.text.trim()) ?? 1;
            final sep = _sep.text.isEmpty ? '-' : _sep.text;
            Navigator.pop(context, _CreateManyParams(base, cnt, st, sep));
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
