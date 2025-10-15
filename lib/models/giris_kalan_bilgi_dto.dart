// lib/models/giris_kalan_bilgi_dto.dart
class GirisKalanBilgiDto {
  final int? defterSiraNo;
  final int? girisBaslikId;
  final String? beyannameNo;
  final DateTime? beyannameTarihi;
  final String? ozetBeyanNo;
  final String? esyaTanimi;
  final String? aliciFirma;
  final int? kalanKap;
  final double? kalanBrutKg;
  final double? girenToplamBrutKg;
  final double? cikanToplamBrutKg;

  GirisKalanBilgiDto({
    this.defterSiraNo,
    this.girisBaslikId,
    this.beyannameNo,
    this.beyannameTarihi,
    this.ozetBeyanNo,
    this.esyaTanimi,
    this.aliciFirma,
    this.kalanKap,
    this.kalanBrutKg,
    this.girenToplamBrutKg,
    this.cikanToplamBrutKg,
  });

  // Çoklu ad desteği: PascalCase / camelCase / snake_case
  factory GirisKalanBilgiDto.fromJson(Map<String, dynamic> j) {
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) {
          final v = j[k];
          if (T == int) return _toInt(v) as T?;
          if (T == double) return _toDouble(v) as T?;
          if (T == DateTime) return _toDate(v) as T?;
          return v as T?;
        }
      }
      return null;
    }

    return GirisKalanBilgiDto(
      defterSiraNo: pick<int>([
        'DefterSiraNo',
        'defterSiraNo',
        'defter_sira_no',
      ]),
      girisBaslikId: pick<int>([
        'GirisBaslikId',
        'girisBaslikId',
        'giris_baslik_id',
      ]),
      beyannameNo: pick<String>(['BeyannameNo', 'beyannameNo', 'beyanname_no']),
      beyannameTarihi: pick<DateTime>([
        'BeyannameTarihi',
        'beyannameTarihi',
        'beyanname_tarihi',
      ]),
      ozetBeyanNo: pick<String>([
        'OzetBeyanNo',
        'ozetBeyanNo',
        'ozet_beyan_no',
      ]),
      esyaTanimi: pick<String>(['EsyaTanimi', 'esyaTanimi', 'esya_tanimi']),
      aliciFirma: pick<String>(['AliciFirma', 'aliciFirma', 'alici_firma']),
      kalanKap: pick<int>(['KalanKap', 'kalanKap', 'kalan_kap']),
      kalanBrutKg: pick<double>([
        'KalanBrutKg',
        'kalanBrutKg',
        'kalan_brut_kg',
      ]),
      girenToplamBrutKg: pick<double>([
        'GirenToplamBrutKg',
        'girenToplamBrutKg',
        'giren_toplam_brut_kg',
      ]),
      cikanToplamBrutKg: pick<double>([
        'CikanToplamBrutKg',
        'cikanToplamBrutKg',
        'cikan_toplam_brut_kg',
      ]),
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    return null;
  }
}
