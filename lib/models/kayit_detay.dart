class KayitDetay {
  String beyannameNo;
  String urunKodu;
  String lokasyon;
  DateTime tarih;
  String batch;
  int adet;
  double kg;

  KayitDetay({
    required this.beyannameNo,
    required this.urunKodu,
    required this.lokasyon,
    required this.tarih,
    required this.batch,
    required this.adet,
    required this.kg,
  });

  KayitDetay copyWith({
    String? beyannameNo,
    String? urunKodu,
    String? lokasyon,
    DateTime? tarih,
    String? batch,
    int? adet,
    double? kg,
  }) {
    return KayitDetay(
      beyannameNo: beyannameNo ?? this.beyannameNo,
      urunKodu: urunKodu ?? this.urunKodu,
      lokasyon: lokasyon ?? this.lokasyon,
      tarih: tarih ?? this.tarih,
      batch: batch ?? this.batch,
      adet: adet ?? this.adet,
      kg: kg ?? this.kg,
    );
  }
}
