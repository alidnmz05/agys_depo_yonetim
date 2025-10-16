// lib/pages/qr_bind_page.dart
import 'dart:async';

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
  final TextEditingController _searchB = TextEditingController();
  final TextEditingController _searchK = TextEditingController();
  final TextEditingController _miktar = TextEditingController();
  final TextEditingController _aciklama = TextEditingController();
  final List<QrBindItem> _items = [];
  bool _busy = false;

  double get _total => _items.fold(0.0, (s, e) => s + e.miktar);

  Future<void> _addItem() async {
    final b = _selectedB;
    if (b == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Beyanname seç.')));
      return;
    }
    final miktar = double.tryParse(_miktar.text.replaceAll(',', '.'));
    if (miktar == null || miktar <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli miktar gir.')));
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
    });
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('En az bir satır ekle.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.service.bind(widget.code, _items);
      if (!mounted) return;
      Navigator.of(context).pop(); // geri dön
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _BeyannameSearch(
                    controller: _searchB,
                    hint: 'Beyanname no/firma',
                    onSelected: (b) => setState(() => _selectedB = b),
                    service: widget.service,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedB != null)
              Row(
                children: [
                  Expanded(
                    child: _KalemSearch(
                      controller: _searchK,
                      hint: 'Kalem ara (opsiyonel)',
                      onSelected: (k) => setState(() => _selectedK = k),
                      service: widget.service,
                      beyannameId: _selectedB!.id,
                    ),
                  ),
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

class _BeyannameSearch extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(BeyannameLite) onSelected;
  final QrService service;
  const _BeyannameSearch({
    required this.controller,
    required this.hint,
    required this.onSelected,
    required this.service,
  });

  @override
  State<_BeyannameSearch> createState() => _BeyannameSearchState();
}

class _BeyannameSearchState extends State<_BeyannameSearch> {
  List<BeyannameLite> _results = [];
  bool _loading = false;
  Timer? _deb;

  void _onChanged() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final res = await widget.service.searchBeyanname(widget.controller.text);
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _deb?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.hint,
            border: const OutlineInputBorder(),
            suffixIcon:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final b = _results[i];
              final selected = b.id == (null == null ? null : null);
              return ChoiceChip(
                label: Text('${b.no}${b.firma != null ? " • ${b.firma}" : ""}'),
                selected: selected,
                onSelected: (_) => widget.onSelected(b),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _KalemSearch extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(KalemLite) onSelected;
  final QrService service;
  final String beyannameId;
  const _KalemSearch({
    required this.controller,
    required this.hint,
    required this.onSelected,
    required this.service,
    required this.beyannameId,
  });

  @override
  State<_KalemSearch> createState() => _KalemSearchState();
}

class _KalemSearchState extends State<_KalemSearch> {
  List<KalemLite> _results = [];
  bool _loading = false;
  Timer? _deb;

  void _onChanged() {
    _deb?.cancel();
    _deb = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final res = await widget.service.searchKalem(
        widget.beyannameId,
        widget.controller.text,
      );
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _deb?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.hint,
            border: const OutlineInputBorder(),
            suffixIcon:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _results.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final k = _results[i];
              return ActionChip(
                label: Text(k.ad),
                onPressed: () => widget.onSelected(k),
              );
            },
          ),
        ),
      ],
    );
  }
}
