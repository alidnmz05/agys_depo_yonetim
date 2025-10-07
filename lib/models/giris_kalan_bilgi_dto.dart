class GirisKalanBilgiDto {
  final String? defterSiraNo;
  final int? girisBaslikId;
  final String? beyannameNo;
  final DateTime? beyannameTarihi;
  final String? ozetBeyanNo;
  final String? esyaTanimi;
  final String? aliciFirma;

  final num? girenToplamBrutKg;
  final num? cikanToplamBrutKg;
  final int? girenKap;
  final int? cikanKap;

  final int? kalanKap;
  final num? kalanBrutKg;

  GirisKalanBilgiDto({
    this.defterSiraNo,
    this.girisBaslikId,
    this.beyannameNo,
    this.beyannameTarihi,
    this.ozetBeyanNo,
    this.esyaTanimi,
    this.aliciFirma,
    this.girenToplamBrutKg,
    this.cikanToplamBrutKg,
    this.girenKap,
    this.cikanKap,
    this.kalanKap,
    this.kalanBrutKg,
  });

  factory GirisKalanBilgiDto.fromJson(Map<String, dynamic> j) {
    DateTime? parseDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    num? toNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }
    int? toInt(dynamic v) => toNum(v)?.toInt();

    return GirisKalanBilgiDto(
      defterSiraNo: j['defterSiraNo'],
      girisBaslikId: toInt(j['girisBaslikId']),
      beyannameNo: j['beyannameNo'],
      beyannameTarihi: parseDate(j['beyannameTarihi']),
      ozetBeyanNo: j['ozetBeyanNo'],
      esyaTanimi: j['esyaTanimi'],
      aliciFirma: j['aliciFirma'],
      girenToplamBrutKg: toNum(j['girenToplamBrutKg']),
      cikanToplamBrutKg: toNum(j['cikanToplamBrutKg']),
      girenKap: toInt(j['girenKap']),
      cikanKap: toInt(j['cikanKap']),
      kalanKap: toInt(j['kalanKap']),
      kalanBrutKg: toNum(j['kalanBrutKg']),
    );
  }
}
