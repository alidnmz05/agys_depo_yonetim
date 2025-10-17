// lib/pages/qr_bind_page.dart
import 'package:agys_depo_yonetim/models/qr_models.dart';
import 'package:agys_depo_yonetim/services/qr_service.dart';
import 'package:flutter/material.dart';

class QrBindPage extends StatefulWidget {
  final String code;
  final QrService service;
  const QrBindPage({super.key, required this.code, required this.service});

  @override
  State<QrBindPage> createState() => _QrBindPageState();
}

class _QrBindPageState extends State<QrBindPage> {
  
  BeyannameLite? _selectedB;
  KalemLite? _selectedK;
  final TextEditingController _bQuery = TextEditingController();
  final TextEditingController _kQuery = TextEditingController();
  final TextEditingController _miktar = TextEditingController();
  final TextEditingController _aciklama = TextEditingController();
  final List<QrBindItem> _items = [];
  bool _busy = false;

  double get _total => _items.fold(0.0, (s, e) => s + e.miktar);

  Future<void> _searchBeyanname() async {
    final q = _bQuery.text.trim();
    if (q.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Beyanname no girin')));
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await widget.service.searchBeyanname(q);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loading

      if (res.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sonuç bulunamadı')));
        return;
      }

      // Öneri chipsleri kaldırıldı. Sadece listeden seçim.
      final sel = await showModalBottomSheet<BeyannameLite>(
        context: context,
        isScrollControlled: true,
        builder:
            (_) => _ResultSheet<BeyannameLite>(
              title: 'Beyanname Seç',
              items: res,
              itemBuilder:
                  (b) => '${b.no}${b.firma != null ? " • ${b.firma}" : ""}',
            ),
      );
      if (sel != null) setState(() => _selectedB = sel);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Arama sırasında hata')));
    }
  }

  Future<void> _searchKalem() async {
    final b = _selectedB;
    if (b == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Önce beyanname seçin')));
      return;
    }
    final q = _kQuery.text.trim();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await widget.service.searchKalem(b.id, q);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (res.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kalem bulunamadı')));
        return;
      }
      final sel = await showModalBottomSheet<KalemLite>(
        context: context,
        isScrollControlled: true,
        builder:
            (_) => _ResultSheet<KalemLite>(
              title: 'Kalem Seç',
              items: res,
              itemBuilder: (k) => k.ad,
            ),
      );
      if (sel != null) setState(() => _selectedK = sel);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Arama sırasında hata')));
    }
  }

  Future<void> _addItem() async {
    final b = _selectedB;
    if (b == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Beyanname seçin')));
      return;
    }
    final miktar = double.tryParse(_miktar.text.replaceAll(',', '.'));
    if (miktar == null || miktar <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli miktar girin')));
      return;
    }
    setState(() {
      _items.add(
        QrBindItem(
          beyannameId: b.id,
          kalemId: _selectedK?.id,
          miktar: miktar,
          aciklama: _aciklama.text.isEmpty ? null : _aciklama.text,
        ),
      );
      _miktar.clear();
      _aciklama.clear();
      _selectedK = null;
      _kQuery.clear();
    });
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('En az bir satır ekleyin')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.bind(widget.code, _items);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Bağla')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kod: ${widget.code}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bQuery,
                    decoration: const InputDecoration(
                      labelText: 'Beyanname no',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchBeyanname(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _searchBeyanname,
                  icon: const Icon(Icons.search),
                  label: const Text('Ara'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Seçilen beyanname',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedB != null
                          ? '${_selectedB!.no}${_selectedB!.firma != null ? " • ${_selectedB!.firma}" : ""}'
                          : '—',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kQuery,
                    decoration: const InputDecoration(
                      labelText: 'Kalem ara (opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchKalem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _searchKalem, child: const Text('Ara')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _miktar,
                    decoration: const InputDecoration(
                      labelText: 'Miktar',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _aciklama,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (opsiyonel)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addItem, child: const Text('Ekle')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final it = _items[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        'B:${it.beyannameId}  K:${it.kalemId ?? "-"}',
                      ),
                      subtitle: it.aciklama != null ? Text(it.aciklama!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${it.miktar}'),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _items.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Toplam: $_total',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: const Icon(Icons.link),
                  label:
                      _busy
                          ? const Text('Gönderiliyor...')
                          : const Text('Bağla'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemBuilder;
  const _ResultSheet({
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    return ListTile(
                      title: Text(itemBuilder(it)),
                      onTap: () => Navigator.of(context).pop<T>(it),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
