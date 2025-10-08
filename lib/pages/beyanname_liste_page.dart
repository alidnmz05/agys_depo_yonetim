import 'package:agys_depo_yonetim/pages/ilk_acilis_konum.dart';
import 'package:agys_depo_yonetim/pages/qr_kod.dart';
import 'package:flutter/material.dart';
import '../models/durum.dart';
import '../models/beyanname_item.dart';
import '../widgets/legend.dart';
import '../widgets/beyanname_tile.dart';
import '../services/api_service.dart';

class BeyannameListePage extends StatefulWidget {
  const BeyannameListePage({super.key});
  @override
  State<BeyannameListePage> createState() => _BeyannameListePageState();
}

class _BeyannameListePageState extends State<BeyannameListePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _api = ApiService();

  List<BeyannameItem> _items = [];
  bool _loading = true;
  String? _error;
  Durum? _filter; // null -> hepsi
  bool _showOnlyToday = false;

  // ← YENİ: yüzde ilerleme (0..1) ya da null (belirsiz)
  final ValueNotifier<double?> _progress = ValueNotifier<double?>(null);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _progress.value = null; // başta belirsiz
    try {
      final dto = await _api.fetchGirisKalan(
        onProgress: (received, total) {
          if (total > 0) {
            _progress.value = (received / total).clamp(0, 1);
          } else {
            _progress.value = null; // Content-Length yoksa belirsiz
          }
        },
      );
      final mapped = _api.mapToItems(dto);
      setState(() {
        _items = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    } finally {
      // küçük bir gecikmeyle çubuğu gizlemek daha şık olabilir:
      Future.delayed(
        const Duration(milliseconds: 200),
        () => _progress.value = null,
      );
    }
  }

  List<BeyannameItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _items.where((e) {
      final matchesQuery =
          q.isEmpty ||
          e.kayit.beyannameNo.toLowerCase().contains(q) ||
          e.kayit.urunKodu.toLowerCase().contains(q) ||
          e.kayit.lokasyon.toLowerCase().contains(q) ||
          e.kayit.batch.toLowerCase().contains(q);
      final matchesFilter = _filter == null ? true : e.durum == _filter;
      final matchesToday =
          !_showOnlyToday ? true : _sameDate(e.kayit.tarih, DateTime.now());
      return matchesQuery && matchesFilter && matchesToday;
    }).toList();
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _statusColor(Durum d) {
    switch (d) {
      case Durum.uygun:
        return Colors.green;
      case Durum.eksik:
        return Colors.amber;
      case Durum.fazla:
        return Colors.red;
    }
  }

  String _durumText(Durum d) {
    switch (d) {
      case Durum.uygun:
        return 'Uygun';
      case Durum.eksik:
        return 'Eksik';
      case Durum.fazla:
        return 'Fazla';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beyanname Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FirstRunSettingsPage()),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const ScannerPage()),
              );
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Bulunan kod: $result')));
              }
            },
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                onRefresh: _load,
                child: Column(
                  children: [
                    // Arama & filtre
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Beyanname, ürün kodu, lokasyon...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<Durum?>(
                            tooltip: 'Duruma göre filtrele',
                            icon: const Icon(Icons.filter_alt_outlined),
                            onSelected: (v) => setState(() => _filter = v),
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: null,
                                    child: Text('Hepsi'),
                                  ),
                                  PopupMenuItem(
                                    value: Durum.uygun,
                                    child: Row(
                                      children: [
                                        Legend(
                                          color: _statusColor(Durum.uygun),
                                          text: 'Uygun',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: Durum.eksik,
                                    child: Row(
                                      children: [
                                        Legend(
                                          color: _statusColor(Durum.eksik),
                                          text: 'Eksik',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: Durum.fazla,
                                    child: Row(
                                      children: [
                                        Legend(
                                          color: _statusColor(Durum.fazla),
                                          text: 'Fazla',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Sadece bugün',
                            child: FilterChip(
                              label: const Text('Bugün'),
                              selected: _showOnlyToday,
                              onSelected:
                                  (v) => setState(() => _showOnlyToday = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Liste
                    Expanded(
                      child:
                          _filtered.isEmpty
                              ? const Center(child: Text('Kayıt bulunamadı'))
                              : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  12,
                                  16,
                                ),
                                itemCount: _filtered.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = _filtered[index];
                                  // YENİ:
                                  return BeyannameTile(
                                    item: item,
                                    onEdited: () => setState(() {}),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
