class SahaDetay {
  String bolge;
  String sira;
  String etiket;
  String batch;
  int adet;
  String taban;
  String ustSira;
  int plusMinus;
  String hesap;

  SahaDetay({
    required this.bolge,
    required this.sira,
    required this.etiket,
    required this.batch,
    required this.adet,
    required this.taban,
    required this.ustSira,
    required this.plusMinus,
    required this.hesap,
  });

  SahaDetay copyWith({
    String? bolge,
    String? sira,
    String? etiket,
    String? batch,
    int? adet,
    String? taban,
    String? ustSira,
    int? plusMinus,
    String? hesap,
  }) {
    return SahaDetay(
      bolge: bolge ?? this.bolge,
      sira: sira ?? this.sira,
      etiket: etiket ?? this.etiket,
      batch: batch ?? this.batch,
      adet: adet ?? this.adet,
      taban: taban ?? this.taban,
      ustSira: ustSira ?? this.ustSira,
      plusMinus: plusMinus ?? this.plusMinus,
      hesap: hesap ?? this.hesap,
    );
  }
}
