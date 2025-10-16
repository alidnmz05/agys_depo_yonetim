// lib/pages/qr_view_page.dart
import 'package:agys_depo_yonetim/models/qr_models.dart';
import 'package:flutter/material.dart';

class QrViewPage extends StatelessWidget {
  final String code;
  final QrInfo info;
  final QrRole role;
  const QrViewPage({
    super.key,
    required this.code,
    required this.info,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final total = info.items.fold<double>(0.0, (s, e) => s + e.miktar);
    return Scaffold(
      appBar: AppBar(title: const Text('QR Kayıtları')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kod: $code',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: info.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final it = info.items[i];
                    return ListTile(
                      dense: true,
                      title: Text(
                        'B:${it.beyannameId}  K:${it.kalemId ?? "-"}',
                      ),
                      subtitle: it.aciklama != null ? Text(it.aciklama!) : null,
                      trailing: Text('${it.miktar}'),
                    );
                  },
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Toplam: $total',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (role == QrRole.counter)
                  FilledButton.icon(
                    onPressed: () {
                      // İlerde sayım modu
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sayım modu yakında.')),
                      );
                    },
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Sayım Modu'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
