// lib/models/qr_models.dart
enum QrRole { viewer, counter }

class QrInfo {
  final String code;
  final List<QrBindItem> items;
  QrInfo({required this.code, required this.items});
}

class QrBindItem {
  final String beyannameId;
  final String? kalemId;
  final double miktar;
  final String? aciklama;
  QrBindItem({
    required this.beyannameId,
    this.kalemId,
    required this.miktar,
    this.aciklama,
  });
}

class BeyannameLite {
  final String id;
  final String no;
  final String? firma;
  BeyannameLite({required this.id, required this.no, this.firma});
}

class KalemLite {
  final String id;
  final String ad;
  KalemLite({required this.id, required this.ad});
}
