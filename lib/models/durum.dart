// lib/models/durum.dart

enum Durum { uygun, eksik, fazla }



extension DurumX on Durum {
  String get label => switch (this) {
    Durum.uygun => 'Uygun',
    Durum.eksik => 'Eksik',
    Durum.fazla => 'Fazla',
  };


}
