import 'package:agys_depo_yonetim/services/settings_controller.dart';
import 'package:flutter/material.dart';

class FirstRunSettingsPage extends StatefulWidget {
  const FirstRunSettingsPage({super.key});
  @override
  State<FirstRunSettingsPage> createState() => _S();
}

class _S extends State<FirstRunSettingsPage> {
  bool _showLocation = SettingsController.instance.showLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İlk Kurulum')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('“Depodaki yeri” bilgisini göster'),
            subtitle: const Text('Saha Detay ve Kayıt Detay’da görünür.'),
            value: _showLocation,
            onChanged: (v) => setState(() => _showLocation = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await SettingsController.instance.setShowLocation(_showLocation);
              await SettingsController.instance.setFirstRunDone();
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Kaydet ve devam'),
          ),
        ],
      ),
    );
  }
}
