// lib/models/bolge.dart
class Bolge {
  final int id;
  final int antrepoId;
  final int? parentId; // ustYerlesimId
  final String ad; // maps to 'kod' from API
  final int sira;
  final String? tip;
  final String? aciklama;
  final bool? aktif;
  final int childCount; // computed client-side from flat cache

  const Bolge({
    required this.id,
    required this.antrepoId,
    required this.parentId,
    required this.ad,
    required this.sira,
    this.tip,
    this.aciklama,
    this.aktif,
    this.childCount = 0,
  });

  Bolge copyWith({
    int? id,
    int? antrepoId,
    int? parentId,
    String? ad,
    int? sira,
    String? tip,
    String? aciklama,
    bool? aktif,
    int? childCount,
  }) => Bolge(
    id: id ?? this.id,
    antrepoId: antrepoId ?? this.antrepoId,
    parentId: parentId ?? this.parentId,
    ad: ad ?? this.ad,
    sira: sira ?? this.sira,
    tip: tip ?? this.tip,
    aciklama: aciklama ?? this.aciklama,
    aktif: aktif ?? this.aktif,
    childCount: childCount ?? this.childCount,
  );

  factory Bolge.fromJson(Map<String, dynamic> j) => Bolge(
    id: j['id'] as int,
    antrepoId: j['antrepoId'] as int,
    parentId: j['ustYerlesimId'] as int?,
    ad: (j['kod'] ?? '').toString(),
    sira: (j['sira'] ?? 0) as int,
    tip: j['tip']?.toString(),
    aciklama: j['aciklama']?.toString(),
    aktif: j['aktif'] is bool ? j['aktif'] as bool : null,
  );

  Map<String, dynamic> toCreateBody() => {
    'ustYerlesimId': parentId,
    'antrepoId': antrepoId,
    'kod': ad,
    'sira': sira,
    'tip': tip,
    'aciklama': aciklama,
    'aktif': aktif ?? true,
  };

  Map<String, dynamic> toUpdateBody() => {
    'id': id,
    'ustYerlesimId': parentId,
    'antrepoId': antrepoId,
    'kod': ad,
    'sira': sira,
    'tip': tip,
    'aciklama': aciklama,
    'aktif': aktif,
  };
}
