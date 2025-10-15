// lib/pages/beyanname_liste_page.dart
import 'package:agys_depo_yonetim/pages/qr_kod.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
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
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.listGirisKalanBilgi(); // Ayarlardan okur
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

  Durum _statusOf(GirisKalanBilgiDto d) {
    // Basit kural: kalanBrutKg ≈ 0 → uygun, <0 → fazla, >0 → eksik
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
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.of(
                  context,
                ).pushNamed('/ayarlar').then((_) => _load()),
            tooltip: 'Ayarlar',
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
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {}, // TODO: tarih seçimi
                  child: const Text('Bugün'),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
    if (_visible.isEmpty) {
      return const Center(child: Text('Kayıt bulunamadı'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _tile(_visible[i]),
    );
  }

  Widget _tile(GirisKalanBilgiDto d) {
    final s = _statusOf(d);
    final title = d.beyannameNo ?? '-';
    final dt = d.beyannameTarihi;
    final dateStr =
        dt == null
            ? ''
            : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

    final kayitAdet =
        d.kalanKap != null &&
                d.girenToplamBrutKg != null &&
                d.cikanToplamBrutKg != null
            ? null // adet bilgisi yoksa boş bırak
            : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            // Üst satır
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, color: Colors.black54),
              ],
            ),
            const SizedBox(height: 6),
            // Özet
            Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bullet('Kayıt: ${_fmtKayitKg(d)}'),
                      _bullet('Saha: ${_fmtSahaAdet(d)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: _pillButton(
                    label: 'Kayıt Detayları',
                    selected: true,
                    onTap: () {
                      // TODO: kayıt detay route
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pillButton(
                    label: 'Saha Detayları',
                    selected: false,
                    onTap: () {
                      // TODO: saha detay route
                    },
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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Text('•  ', style: TextStyle(color: Colors.black54)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _fmtKayitKg(GirisKalanBilgiDto d) {
    final kgIn = d.girenToplamBrutKg;
    final kgOut = d.cikanToplamBrutKg;
    final kg = (kgIn != null && kgOut != null) ? (kgIn) : (kgIn ?? kgOut ?? 0);
    return '${_fmtKg.format(kg)} kg';
  }

  String _fmtSahaAdet(GirisKalanBilgiDto d) {
    final adet = d.kalanKap; // eldeki en yakın alan
    return adet == null ? '-' : '$adet adet';
  }
}
