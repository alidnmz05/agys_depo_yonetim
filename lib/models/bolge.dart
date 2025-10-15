// lib/models/bolge.dart
class Bolge {
  final int id;
  final int antrepoId;
  final int? parentId;
  final String ad;
  final String? kod;
  final int sira;
  final int childCount;

  const Bolge({
    required this.id,
    required this.antrepoId,
    required this.parentId,
    required this.ad,
    required this.kod,
    required this.sira,
    required this.childCount,
  });

  Bolge copyWith({
    int? id,
    int? antrepoId,
    int? parentId,
    String? ad,
    String? kod,
    int? sira,
    int? childCount,
  }) => Bolge(
    id: id ?? this.id,
    antrepoId: antrepoId ?? this.antrepoId,
    parentId: parentId ?? this.parentId,
    ad: ad ?? this.ad,
    kod: kod ?? this.kod,
    sira: sira ?? this.sira,
    childCount: childCount ?? this.childCount,
  );

  factory Bolge.fromJson(Map<String, dynamic> j) => Bolge(
    id: j['id'] as int,
    antrepoId: j['antrepoId'] as int,
    parentId: j['parentId'] as int?,
    ad: (j['ad'] ?? j['name'] ?? '').toString(),
    kod: j['kod']?.toString(),
    sira: (j['sira'] ?? j['order'] ?? 0) as int,
    childCount: (j['childCount'] ?? j['children'] ?? 0) as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'antrepoId': antrepoId,
    'parentId': parentId,
    'ad': ad,
    'kod': kod,
    'sira': sira,
    'childCount': childCount,
  };
}
