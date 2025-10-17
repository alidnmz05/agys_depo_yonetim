// lib/pages/beyanname_liste_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/settings_controller.dart';
import '../models/giris_kalan_bilgi_dto.dart';

enum Durum { hepsi, uygun, eksik, fazla }

class BeyannameListePage extends StatefulWidget {
  const BeyannameListePage({super.key});
  @override
  State<BeyannameListePage> createState() => _BeyannameListePageState();
}

class _BeyannameListePageState extends State<BeyannameListePage> {
  final _api = ApiService();
  final _q = TextEditingController();
  final _fmtKg = NumberFormat('#,##0.##', 'tr_TR');

  bool _loading = true;
  String? _error;
  Durum _filter = Durum.hepsi;
  List<GirisKalanBilgiDto> _all = const [];
  List<GirisKalanBilgiDto> _visible = const [];

  @override
  void initState() {
    super.initState();
    _load();
    _q.addListener(_apply);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureFirstRun());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _ensureFirstRun() async {
    final sc = SettingsController.instance;
    await sc.init();
    await sc.load();
    if (sc.firstRunDone) return;

    bool value = sc.showLocation;
    if (!mounted) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: StatefulBuilder(
            builder:
                (context, setSt) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Konum Gösterimi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Detaylarda cihaz konumunu göstermek ister misiniz?',
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Depodaki yeri göster'),
                      value: value,
                      onChanged: (v) => setSt(() => value = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Vazgeç'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        );
      },
    );

    if (saved == true) await sc.setShowLocation(value);
    await sc.setFirstRunDone();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.listGirisKalanBilgi();
      _all = list;
      _apply();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _apply() {
    final q = _q.text.trim().toLowerCase();
    List<GirisKalanBilgiDto> res = _all;

    if (q.isNotEmpty) {
      res =
          res.where((d) {
            final t1 = (d.beyannameNo ?? '').toLowerCase();
            final t2 = (d.esyaTanimi ?? '').toLowerCase();
            final t3 = (d.aliciFirma ?? '').toLowerCase();
            return t1.contains(q) || t2.contains(q) || t3.contains(q);
          }).toList();
    }

    if (_filter != Durum.hepsi) {
      res = res.where((d) => _statusOf(d) == _filter).toList();
    }

    setState(() => _visible = res);
  }

  void applyQrToForm(String s) {
    setState(() {
      _q.text = s;
    });
    _apply();
  }

  Durum _statusOf(GirisKalanBilgiDto d) {
    final k = d.kalanBrutKg;
    if (k == null) return Durum.uygun;
    if (k.abs() < 1e-6) return Durum.uygun;
    return k > 0 ? Durum.eksik : Durum.fazla;
  }

  Color _statusColor(Durum s, {bool filled = true}) {
    switch (s) {
      case Durum.uygun:
        return filled ? const Color(0xFF2ECC71) : const Color(0x332ECC71);
      case Durum.eksik:
        return filled ? const Color(0xFFF1C40F) : const Color(0x33F1C40F);
      case Durum.fazla:
        return filled ? const Color(0xFFE74C3C) : const Color(0x33E74C3C);
      case Durum.hepsi:
        return Colors.grey;
    }
  }

  String _statusText(Durum s) {
    switch (s) {
      case Durum.uygun:
        return 'Uygun';
      case Durum.eksik:
        return 'Eksik';
      case Durum.fazla:
        return 'Fazla';
      case Durum.hepsi:
        return 'Hepsi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beyanname Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Bölge Yönetimi',
            onPressed: () => Navigator.of(context).pushNamed('/bolge'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              Navigator.of(context).pushNamed('/qr/scan');
            },
            tooltip: 'QR Tara',
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed:
                () => Navigator.pushNamed(context, '/qr/list'), // ← BURAYA
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.of(
                  context,
                ).pushNamed('/ayarlar').then((_) => _load()),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Beyanname, ürün, firma...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<Durum>(
                  tooltip: 'Durum',
                  initialValue: _filter,
                  onSelected: (v) {
                    _filter = v;
                    _apply();
                  },
                  itemBuilder:
                      (_) => [
                        _menuItem(Durum.hepsi, leadingDot: false),
                        _menuItem(Durum.uygun),
                        _menuItem(Durum.eksik),
                        _menuItem(Durum.fazla),
                      ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_statusText(_filter)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  PopupMenuItem<Durum> _menuItem(Durum s, {bool leadingDot = true}) {
    return PopupMenuItem<Durum>(
      value: s,
      child: Row(
        children: [
          if (leadingDot) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _statusColor(s),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(_statusText(s)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Hata: $_error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (_visible.isEmpty) return const Center(child: Text('Kayıt bulunamadı'));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _tile(i, _visible[i]),
    );
  }

  Widget _tile(int i, GirisKalanBilgiDto d) {
    final s = _statusOf(d);
    final title = d.beyannameNo ?? '-';
    final t = d.beyannameTarihi;
    final dateStr =
        t == null
            ? ''
            : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('bx_$i'),
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColor(s),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(dateStr, style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              _statusBadge(s),
            ],
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: _pillButton(
                    label: 'Kayıt Detayları',
                    selected: true,
                    onTap: () => _showKayitDetay(d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pillButton(
                    label: 'Saha Detayları',
                    selected: false,
                    onTap: () => _showSahaDetay(d),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(Durum s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor(s, filled: false),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor(s)),
      ),
      child: Row(
        children: [
          Icon(
            s == Durum.uygun
                ? Icons.check_circle
                : (s == Durum.eksik ? Icons.error : Icons.cancel),
            size: 16,
            color: _statusColor(s),
          ),
          const SizedBox(width: 6),
          Text(
            _statusText(s),
            style: TextStyle(
              color: _statusColor(s),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FE) : const Color(0xFF2F80ED),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF2F80ED) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showKayitDetay(GirisKalanBilgiDto d) {
    final sc = SettingsController.instance;
    final showLoc = sc.showLocation;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String fmtDate(DateTime? t) {
          if (t == null) return '';
          return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
        }

        String? fmtKg(num? v) => v == null ? null : '${_fmtKg.format(v)} kg';
        Widget row(String k, String? v) {
          if (v == null || v.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 160,
                  child: Text(k, style: const TextStyle(color: Colors.black54)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(v)),
              ],
            ),
          );
        }

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kayıt Detayları',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  row('Alıcı Firma', d.aliciFirma),
                  row('Beyanname No', d.beyannameNo),
                  row('Beyanname Tarihi', fmtDate(d.beyannameTarihi)),
                  row('Kalan Kap', d.kalanKap?.toString()),
                  row('Eşya Tanımı', d.esyaTanimi),
                  row('Çıkan Toplam Brüt Kg', fmtKg(d.cikanToplamBrutKg)),
                  row('Giren Toplam Brüt Kg', fmtKg(d.girenToplamBrutKg)),
                  row('Kalan Brüt Kg', fmtKg(d.kalanBrutKg)),

                  if (showLoc) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Depodaki yeri',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Konum açık. İzin verilince koordinatlar burada görüntülenecek.',
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSahaDetay(GirisKalanBilgiDto d) async {
    final sc = SettingsController.instance;
    final showLoc = sc.showLocation;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        Widget row(String k, String? v) {
          if (v == null || v.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(k, style: const TextStyle(color: Colors.black54)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(v)),
              ],
            ),
          );
        }

        String? fmtKg(num? v) => v == null ? null : '${_fmtKg.format(v)} kg';

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Saha Detayları',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  row('Kalan Kap', d.kalanKap?.toString()),
                  row('Kalan Brüt', fmtKg(d.kalanBrutKg)),

                  if (showLoc) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Konum',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Konum açık. İzin verilince koordinatlar burada görüntülenecek.',
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
