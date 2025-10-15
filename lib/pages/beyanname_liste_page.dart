// lib/pages/beyanname_liste_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/giris_kalan_bilgi_dto.dart';

class BeyannameListePage extends StatefulWidget {
  const BeyannameListePage({super.key});
  @override
  State<BeyannameListePage> createState() => _BeyannameListePageState();
}

class _BeyannameListePageState extends State<BeyannameListePage> {
  final _api = ApiService();
  bool _loading = true;
  String? _error;
  List<GirisKalanBilgiDto> _items = const [];

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
    try {
      final data = await _api.listGirisKalanBilgi(); // Ayarlardan okur
      setState(() {
        _items = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
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
              await Navigator.of(context).pushNamed('/ayarlar');
              if (mounted) _load();
            },
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Hata: $_error',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(onPressed: _load, child: const Text('Tekrar dene')),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/ayarlar'),
                child: const Text('Ayarlar'),
              ),
            ],
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(child: Text('Kayıt bulunamadı')),
        ],
      );
    }
    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final d = _items[i];
        final sub = <String>[
          if ((d.esyaTanimi ?? '').isNotEmpty) d.esyaTanimi!,
          if ((d.aliciFirma ?? '').isNotEmpty) d.aliciFirma!,
          _kalanText(d),
        ].where((e) => e.isNotEmpty).join(' • ');
        return ListTile(
          title: Text(_title(d)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        );
      },
    );
  }

  String _title(GirisKalanBilgiDto d) {
    final no = d.beyannameNo ?? '-';
    final t = d.beyannameTarihi;
    final ds =
        t == null
            ? ''
            : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
    return ds.isEmpty ? no : '$no  •  $ds';
  }

  String _kalanText(GirisKalanBilgiDto d) {
    final parts = <String>[];
    if (d.kalanKap != null) parts.add('Kalan Kap: ${d.kalanKap}');
    if (d.kalanBrutKg != null)
      parts.add('Kalan Brüt: ${d.kalanBrutKg!.toStringAsFixed(2)} kg');
    return parts.join(' | ');
  }
}
