// lib/services/qr_service.dart
import 'dart:async';
import '../models/qr_models.dart';

/// QrService gerçek API hazır olana kadar mock destekli çalışır.
class QrService {
  QrService({this.useMock = true});
  final bool useMock;
  static final Map<String, QrInfo> _mem = {};

  /// QR hakkında mevcut kayıt var mı?
  Future<QrInfo?> fetchInfo(String code) async {
    if (useMock) {
      if (_mem.containsKey(code)) return _mem[code]; // EKLE
      if (code.contains('HAVE')) {
        return QrInfo(
          code: code,
          items: [
            QrBindItem(beyannameId: 'B-1001', kalemId: 'K-1', miktar: 12),
            QrBindItem(beyannameId: 'B-1001', kalemId: 'K-2', miktar: 5.5),
          ],
        );
      }
      return null;
    }
    // TODO: gerçek GET
    return null;
  }

  /// QR'ı beyanname/kalemlerle ilişkilendir.
  Future<void> bind(String code, List<QrBindItem> items) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      _mem[code] = QrInfo(code: code, items: List.of(items));
      return;
    }
    // TODO: POST /qr/{code}/bind
  }

  /// Beyanname arama
  Future<List<BeyannameLite>> searchBeyanname(String query) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      return List.generate(6, (i) {
            return BeyannameLite(
              id: 'B-${1000 + i}',
              no: '2025/0${i + 1}',
              firma: i % 2 == 0 ? 'ACME' : 'Globex',
            );
          })
          .where((b) => b.no.contains(query) || (b.firma ?? '').contains(query))
          .toList();
    }
    // TODO: GET /beyanname?search=...
    return [];
  }

  /// Kalem arama (beyannameye bağlı)
  Future<List<KalemLite>> searchKalem(String beyannameId, String query) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return List.generate(
        8,
        (i) => KalemLite(id: 'K-$i', ad: 'Kalem $i'),
      ).where((k) => k.ad.toLowerCase().contains(query.toLowerCase())).toList();
    }
    // TODO: GET /beyanname/{id}/kalem?search=...
    return [];
  }

  /// Rol belirleme. Gerçek senaryoda JWT claim veya kullanıcı ayarı.
  Future<QrRole> resolveRole() async {
    if (useMock) return QrRole.viewer;
    // TODO: gerçek rol çözümlemesi
    return QrRole.viewer;
  }
}
