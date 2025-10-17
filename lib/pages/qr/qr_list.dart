// lib/pages/qr_list_page.dart
import 'package:agys_depo_yonetim/models/qr_models.dart';
import 'package:agys_depo_yonetim/services/qr_service.dart';
import 'package:flutter/material.dart';
import 'qr_view_page.dart';

class QrListPage extends StatefulWidget {
  const QrListPage({super.key});

  @override
  State<QrListPage> createState() => _QrListPageState();
}

class _QrListPageState extends State<QrListPage> {
  final QrService _service = QrService(useMock: false);
  late Future<List<QrInfo>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bağlanan QR’lar')),
      body: FutureBuilder<List<QrInfo>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Kayıt yok. Bir QR bağlayın.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final info = items[i];
              final total = info.items.fold<double>(
                0.0,
                (s, e) => s + e.miktar,
              );
              return ListTile(
                title: Text(info.code),
                subtitle: Text('${info.items.length} satır • Toplam: $total'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => QrViewPage(
                            code: info.code,
                            info: info,
                            role: QrRole.viewer,
                          ),
                    ),
                  );
                  if (!mounted) return;
                  setState(() => _future = _service.listAll()); // refresh
                },
              );
            },
          );
        },
      ),
    );
  }
}
