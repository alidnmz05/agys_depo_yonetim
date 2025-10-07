import 'durum.dart';
import 'kayit_detay.dart';
import 'saha_detay.dart';

class BeyannameItem {
  KayitDetay kayit;
  SahaDetay saha;

  BeyannameItem({required this.kayit, required this.saha});

  Durum get durum {
    final adetFark = saha.adet - kayit.adet;
    if (adetFark == 0) return Durum.uygun;
    if (adetFark < 0) return Durum.eksik;
    return Durum.fazla;
  }

  // ← BUNU EKLE
  int get fark => saha.adet - kayit.adet;
}