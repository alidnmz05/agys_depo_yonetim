import 'package:flutter/material.dart';
import '../services/settings_controller.dart';
import '../services/api_service.dart';

class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});
  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  final sc = SettingsController.instance;
  late final _base = TextEditingController(text: sc.baseUrl);
  late final _key = TextEditingController(text: sc.apiKey);
  late final _id = TextEditingController(text: sc.antrepoId.toString());
  bool _showLoc = false;
  bool _testing = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _showLoc = sc.showLocation;
  }

  @override
  void dispose() {
    _base.dispose();
    _key.dispose();
    _id.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    sc.baseUrl = _base.text.trim();
    sc.apiKey = _key.text.trim();
    sc.antrepoId = int.tryParse(_id.text.trim()) ?? 1;
    await sc.setShowLocation(_showLoc);
    setState(() => _msg = 'Kaydedildi');
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    _msg = null;
    try {
      final list = await ApiService().listGirisKalanBilgi();
      _msg = 'Bağlandı • Kayıt: ${list.length}';
    } catch (e) {
      _msg = 'Hata: $e';
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _base,
            decoration: const InputDecoration(labelText: 'Base URL'),
          ),
          TextField(
            controller: _key,
            decoration: const InputDecoration(labelText: 'API Key'),
          ),
          TextField(
            controller: _id,
            decoration: const InputDecoration(labelText: 'Antrepo ID'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Depodaki yeri göster'),
            value: _showLoc,
            onChanged: (v) {
              setState(() => _showLoc = v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(onPressed: _save, child: const Text('Kaydet')),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _testing ? null : _test,
                child: Text(
                  _testing ? 'Test ediliyor...' : 'Bağlantıyı test et',
                ),
              ),
            ],
          ),
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Text(_msg!, style: const TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
