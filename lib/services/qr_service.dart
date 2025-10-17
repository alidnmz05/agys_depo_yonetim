// lib/services/qr_service.dart
import 'dart:async';
import '../models/qr_models.dart';
import '../services/api_service.dart' show ApiService;

typedef _Getter<T> = T? Function();

T? _safe<T>(T? Function() f) {
  try {
    return f();
  } catch (_) {
    return null;
  }
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[\s/.\-_,]'), '');

String _pickFromMap(
  Map<String, dynamic> m,
  List<String> keys, {
  String def = '',
}) {
  for (final k in keys) {
    final v = m[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return def;
}

/// QR servisi: Mevcut yapıyı bozmaz. Mock + API.
class QrService {
  QrService({this.useMock = true});
  final bool useMock;

  static final Map<String, QrInfo> _mem = {};

  Future<QrInfo?> fetchInfo(String code) async {
    if (useMock) {
      if (_mem.containsKey(code)) return _mem[code];
      if (code.toUpperCase().contains('HAVE')) {
        final info = QrInfo(
          code: code,
          items: [
            QrBindItem(beyannameId: 'B-1001', kalemId: 'K-1', miktar: 12),
            QrBindItem(beyannameId: 'B-1001', kalemId: 'K-2', miktar: 5.5),
          ],
        );
        _mem[code] = info;
        return info;
      }
      return null;
    }
    // TODO: gerçek GET /qr/{code}
    return null;
  }

  Future<void> bind(String code, List<QrBindItem> items) async {
    if (useMock) {
      final prev = _safe(() => _mem[code]?.items) ?? const <QrBindItem>[];
      _mem[code] = QrInfo(code: code, items: [...prev, ...items]);
      return;
    }
    // TODO: POST /qr/{code}/bind
  }

  /// Beyanname arama: yalnızca beyanname numarası ile.
  Future<List<BeyannameLite>> searchBeyanname(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 150));
      return List<BeyannameLite>.generate(
        8,
        (i) => BeyannameLite(
          id: 'B-${1000 + i}',
          no: '2025/${(i + 1).toString().padLeft(2, '0')}',
          firma: i.isEven ? 'ACME' : 'Globex',
        ),
      ).where((b) => _norm(b.no).contains(_norm(q))).toList();
    }

    final api = ApiService();
    final list = await api.fetchGirisKalan();

    final nq = _norm(q);
    final out = <BeyannameLite>[];

    for (final dto in list) {
      // 1) Map üzerinden alan seçimi (toJson varsa)
      Map<String, dynamic>? m;
      final any = dto as dynamic;
      m =
          _safe(() => any.toJson() as Map<String, dynamic>?) ??
          (dto is Map<String, dynamic> ? dto as Map<String, dynamic> : null);

      String id = '';
      String no = '';
      String firma = '';

      if (m != null) {
        id = _pickFromMap(m, [
          'id',
          'girisId',
          'beyannameId',
          'declarationId',
        ], def: '');
        no = _pickFromMap(m, [
          'beyannameNo',
          'beyanname_no',
          'belgeNo',
          'declarationNo',
          'declarationNumber',
          'no',
          'numara',
        ], def: '');
        firma = _pickFromMap(m, [
          'firmaAdi',
          'firma',
          'companyName',
          'musteriAdi',
          'cariAdi',
        ], def: '');
      } else {
        // 2) Güvenli property erişimi
        id =
            _safe(() => any.id?.toString()) ??
            _safe(() => any.girisId?.toString()) ??
            _safe(() => any.beyannameId?.toString()) ??
            _safe(() => any.declarationId?.toString()) ??
            '';
        no =
            _safe(() => any.beyannameNo?.toString()) ??
            _safe(() => any.beyanname_no?.toString()) ??
            _safe(() => any.belgeNo?.toString()) ??
            _safe(() => any.declarationNo?.toString()) ??
            _safe(() => any.declarationNumber?.toString()) ??
            _safe(() => any.no?.toString()) ??
            _safe(() => any.numara?.toString()) ??
            '';
        firma =
            _safe(() => any.firmaAdi?.toString()) ??
            _safe(() => any.firma?.toString()) ??
            _safe(() => any.companyName?.toString()) ??
            _safe(() => any.musteriAdi?.toString()) ??
            _safe(() => any.cariAdi?.toString()) ??
            '';
      }

      if (id.isEmpty && no.isEmpty && firma.isEmpty) {
        // Son çare: tüm dto metninde ara
        final s = dto.toString();
        if (_norm(s).contains(nq)) {
          out.add(BeyannameLite(id: 'NA', no: q, firma: null));
        }
        continue;
      }

      final match = _norm(no).contains(nq) || nq.contains(_norm(no));
      if (match) {
        out.add(
          BeyannameLite(
            id: id.isEmpty ? (no.isEmpty ? 'NA' : no) : id,
            no: no.isEmpty ? (id.isEmpty ? 'NA' : id) : no,
            firma: firma.isEmpty ? null : firma,
          ),
        );
      }
    }

    if (out.isEmpty) {
      // İlk 30 kaydı önizleme olarak döndür
      for (final dto in list.take(30)) {
        final any = dto as dynamic;
        Map<String, dynamic>? m =
            _safe(() => any.toJson() as Map<String, dynamic>?) ??
            (dto is Map<String, dynamic> ? dto as Map<String, dynamic> : null);

        String id = '';
        String no = '';
        String firma = '';

        if (m != null) {
          id = _pickFromMap(m, [
            'id',
            'girisId',
            'beyannameId',
            'declarationId',
          ], def: 'NA');
          no = _pickFromMap(m, [
            'beyannameNo',
            'beyanname_no',
            'belgeNo',
            'declarationNo',
            'declarationNumber',
            'no',
            'numara',
          ], def: id);
          firma = _pickFromMap(m, [
            'firmaAdi',
            'firma',
            'companyName',
            'musteriAdi',
            'cariAdi',
          ], def: '');
        } else {
          id =
              _safe(() => any.id?.toString()) ??
              _safe(() => any.girisId?.toString()) ??
              _safe(() => any.beyannameId?.toString()) ??
              _safe(() => any.declarationId?.toString()) ??
              'NA';
          no =
              _safe(() => any.beyannameNo?.toString()) ??
              _safe(() => any.beyanname_no?.toString()) ??
              _safe(() => any.belgeNo?.toString()) ??
              _safe(() => any.declarationNo?.toString()) ??
              _safe(() => any.declarationNumber?.toString()) ??
              _safe(() => any.no?.toString()) ??
              _safe(() => any.numara?.toString()) ??
              id;
          firma =
              _safe(() => any.firmaAdi?.toString()) ??
              _safe(() => any.firma?.toString()) ??
              _safe(() => any.companyName?.toString()) ??
              _safe(() => any.musteriAdi?.toString()) ??
              _safe(() => any.cariAdi?.toString()) ??
              '';
        }

        out.add(
          BeyannameLite(id: id, no: no, firma: firma.isEmpty ? null : firma),
        );
      }
    }

    return out;
  }

  Future<List<KalemLite>> searchKalem(String beyannameId, String query) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final q = query.trim().toLowerCase();
    final base = List<KalemLite>.generate(
      10,
      (i) => KalemLite(id: 'K-$i', ad: 'Kalem $i'),
    );
    if (q.isEmpty) return base;
    return base.where((k) => k.ad.toLowerCase().contains(q)).toList();
  }

  Future<QrRole> resolveRole() async {
    if (useMock) return QrRole.viewer;
    return QrRole.viewer;
  }

  Future<List<QrInfo>> listAll() async {
    final list = _mem.values.toList();
    list.sort((a, b) => a.code.compareTo(b.code));
    return list;
  }
}
