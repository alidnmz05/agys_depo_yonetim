import 'package:dio/dio.dart';
import '../models/giris_kalan_bilgi_dto.dart';
import '../models/beyanname_item.dart';
import '../models/kayit_detay.dart';
import '../models/saha_detay.dart';

const _baseUrl = 'https://d0444dc904fc.ngrok-free.app';
const bool _useMockData = true; // ← SUNUM İÇİN true YAP, gerçek API için false

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ));
  }

  Future<List<GirisKalanBilgiDto>> fetchGirisKalan({
    void Function(int received, int total)? onProgress,
  }) async {
    // MOCK DATA - Sunum için
    if (_useMockData) {
      // Yükleniyor efekti için küçük gecikme
      await Future.delayed(const Duration(milliseconds: 800));

      // Progress simülasyonu
      if (onProgress != null) {
        for (int i = 0; i <= 100; i += 20) {
          await Future.delayed(const Duration(milliseconds: 50));
          onProgress(i, 100);
        }
      }

      return _getMockData();
    }

    // GERÇEK API ÇAĞRISI
    final res = await _dio.get(
      '/api/giris/kalan-bilgi',
      onReceiveProgress: onProgress,
    );
    final data = (res.data as List).cast<Map<String, dynamic>>();
    return data.map(GirisKalanBilgiDto.fromJson).toList();
  }

  // MOCK VERİ KAYNAĞI
  List<GirisKalanBilgiDto> _getMockData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      GirisKalanBilgiDto(
        beyannameNo: 'TR2025001234',
        beyannameTarihi: today,
        esyaTanimi: 'Pamuklu Kumaş',
        defterSiraNo: 'A-01-001',
        ozetBeyanNo: 'BATCH-2025-001',
        kalanKap: 100,
        girenKap: 100,
        kalanBrutKg: 2500.0,
        girenToplamBrutKg: 2500.0,
        aliciFirma: 'ABC Tekstil A.Ş.',
      ),
      GirisKalanBilgiDto(
        beyannameNo: 'TR2025001235',
        beyannameTarihi: today,
        esyaTanimi: 'Polyester İplik',
        defterSiraNo: 'B-02-015',
        ozetBeyanNo: 'BATCH-2025-002',
        kalanKap: 85,
        girenKap: 100,
        kalanBrutKg: 1800.5,
        girenToplamBrutKg: 2000.0,
        aliciFirma: 'XYZ Tekstil Ltd.',
      ),
      GirisKalanBilgiDto(
        beyannameNo: 'TR2025001236',
        beyannameTarihi: today.subtract(const Duration(days: 1)),
        esyaTanimi: 'Sentetik Kumaş',
        defterSiraNo: 'A-01-025',
        ozetBeyanNo: 'BATCH-2025-003',
        kalanKap: 120,
        girenKap: 100,
        kalanBrutKg: 3200.0,
        girenToplamBrutKg: 2800.0,
        aliciFirma: 'Mega Tekstil A.Ş.',
      ),
      GirisKalanBilgiDto(
        beyannameNo: 'TR2025001237',
        beyannameTarihi: today,
        esyaTanimi: 'Pamuk İplik',
        defterSiraNo: 'C-03-008',
        ozetBeyanNo: 'BATCH-2025-004',
        kalanKap: 50,
        girenKap: 50,
        kalanBrutKg: 1250.0,
        girenToplamBrutKg: 1250.0,
        aliciFirma: 'Elit Tekstil San.',
      ),
      GirisKalanBilgiDto(
        beyannameNo: 'TR2025001238',
        beyannameTarihi: today.subtract(const Duration(days: 2)),
        esyaTanimi: 'Viskon Kumaş',
        defterSiraNo: 'B-02-032',
        ozetBeyanNo: 'BATCH-2025-005',
        kalanKap: 75,
        girenKap: 80,
        kalanBrutKg: 1900.0,
        girenToplamBrutKg: 2100.0,
        aliciFirma: 'Prestij Tekstil Ltd.',
      ),
      GirisKalanBilgiDto(
        beyannameNo: 'TR2025001239',
        beyannameTarihi: today,
        esyaTanimi: 'Elastan İplik',
        defterSiraNo: 'A-01-042',
        ozetBeyanNo: 'BATCH-2025-006',
        kalanKap: 200,
        girenKap: 150,
        kalanBrutKg: 4500.0,
        girenToplamBrutKg: 3500.0,
        aliciFirma: 'Delta Tekstil A.Ş.',
      ),
    ];
  }

  List<BeyannameItem> mapToItems(List<GirisKalanBilgiDto> list) {
    return list.map((d) {
      final adet = d.kalanKap ?? d.girenKap ?? 0;
      final kg = (d.kalanBrutKg ?? d.girenToplamBrutKg ?? 0).toDouble();

      final kayit = KayitDetay(
        beyannameNo: d.beyannameNo ?? '',
        urunKodu: d.esyaTanimi ?? '',
        lokasyon: d.defterSiraNo ?? '',
        tarih: d.beyannameTarihi ?? DateTime.now(),
        batch: d.ozetBeyanNo ?? '',
        adet: adet,
        kg: kg,
      );

      final saha = SahaDetay(
        bolge: d.aliciFirma ?? '',
        sira: '',
        etiket: '',
        batch: d.ozetBeyanNo ?? '',
        adet: adet,
        taban: '',
        ustSira: '',
        plusMinus: 0,
        hesap: '',
      );

      return BeyannameItem(kayit: kayit, saha: saha);
    }).toList();
  }
}