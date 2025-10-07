import 'package:flutter/material.dart';
import '../models/beyanname_item.dart';
import '../models/saha_detay.dart';
import '../models/durum.dart';
import 'dot.dart';
import 'sheet_header.dart';
import 'readonly_row.dart';
import 'edit_row.dart';

class BeyannameTile extends StatefulWidget {
  final BeyannameItem item;
  final VoidCallback onEdited;

  const BeyannameTile({
    super.key,
    required this.item,
    required this.onEdited,
  });

  @override
  State<BeyannameTile> createState() => _BeyannameTileState();
}

class _BeyannameTileState extends State<BeyannameTile> {
  bool _expanded = false;

  Color _statusColor(Durum d) {
    switch (d) {
      case Durum.uygun:
        return Colors.green;
      case Durum.eksik:
        return Colors.amber;
      case Durum.fazla:
        return Colors.red;
    }
  }

  Widget _durumWidget(Durum d, int fark) {
    switch (d) {
      case Durum.uygun:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 4),
            Text('Uygun',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        );
      case Durum.eksik:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.remove_circle, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text('Eksik ($fark)',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),
          ],
        );
      case Durum.fazla:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle, color: Colors.red, size: 20),
            const SizedBox(width: 4),
            Text('Fazla (+$fark)',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kayit = widget.item.kayit;
    final saha = widget.item.saha;
    final durum = widget.item.durum;
    final color = _statusColor(durum);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Dot(color: color),
            title: Text(kayit.beyannameNo,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Kayıt: ${kayit.adet} adet / ${kayit.kg.toStringAsFixed(1)} kg   •   Saha: ${saha.adet} adet'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _durumWidget(durum, widget.item.fark),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (_expanded) const Divider(height: 1),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _showKayitDetay(context),
                      child: const Text('Kayıt Detayları'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _showSahaDetay(context, widget.onEdited),
                      child: const Text('Saha Detayları'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showKayitDetay(BuildContext context) {
    final k = widget.item.kayit;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHeader(
                title: 'Kayıt Detayları',
                subtitle: 'Sistem kayıtları (teorik stok)',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 8),
              ReadonlyRow(label: 'Beyanname No', value: k.beyannameNo),
              ReadonlyRow(label: 'Ürün Kodu', value: k.urunKodu),
              ReadonlyRow(label: 'Lokasyon', value: k.lokasyon),
              ReadonlyRow(
                  label: 'Tarih',
                  value: '${k.tarih.day}.${k.tarih.month}.${k.tarih.year}'),
              ReadonlyRow(label: 'Batch', value: k.batch),
              ReadonlyRow(label: 'Adet', value: '${k.adet}'),
              ReadonlyRow(label: 'KG', value: k.kg.toStringAsFixed(1)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showSahaDetay(BuildContext context, VoidCallback onEdited) {
    final s = widget.item.saha;
    final bolgeCtrl = TextEditingController(text: s.bolge);
    final siraCtrl = TextEditingController(text: s.sira);
    final etiketCtrl = TextEditingController(text: s.etiket);
    final batchCtrl = TextEditingController(text: s.batch);
    final adetCtrl = TextEditingController(text: s.adet.toString());
    final tabanCtrl = TextEditingController(text: s.taban);
    final ustSiraCtrl = TextEditingController(text: s.ustSira);
    final plusMinusCtrl = TextEditingController(text: s.plusMinus.toString());

    // Adet hesaplama fonksiyonu
    void hesaplaAdet() {
      final taban = int.tryParse(tabanCtrl.text) ?? 0;
      final ustSira = int.tryParse(ustSiraCtrl.text) ?? 0;
      final plusMinus = int.tryParse(plusMinusCtrl.text) ?? 0;

      final hesaplananAdet = (taban * ustSira) + plusMinus;
      adetCtrl.text = hesaplananAdet.toString();
    }

    // Her alan değiştiğinde adeti yeniden hesapla
    tabanCtrl.addListener(hesaplaAdet);
    ustSiraCtrl.addListener(hesaplaAdet);
    plusMinusCtrl.addListener(hesaplaAdet);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SheetHeader(
                  title: 'Saha Detayları',
                  subtitle: 'Sahadan girilecek alanlar',
                  icon: Icons.edit_note,
                ),
                const SizedBox(height: 16),

                EditRow(label: 'Bölge', controller: bolgeCtrl),
                EditRow(label: 'Sıra', controller: siraCtrl),
                EditRow(label: 'Etiket', controller: etiketCtrl),
                EditRow(label: 'Batch', controller: batchCtrl),

                const Divider(height: 24),

                // Hesaplama alanları - kompakt
                Column(
                  children: [
                    EditRow(
                      label: 'Taban',
                      controller: tabanCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    EditRow(
                      label: 'Üst Sıra',
                      controller: ustSiraCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    EditRow(
                      label: '+/-',
                      controller: plusMinusCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sayılan Adet - tema rengine uygun
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sayılan Adet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          adetCtrl.text,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            widget.item.saha = s.copyWith(
                              bolge: bolgeCtrl.text,
                              sira: siraCtrl.text,
                              etiket: etiketCtrl.text,
                              batch: batchCtrl.text,
                              adet: int.tryParse(adetCtrl.text) ?? s.adet,
                              taban: tabanCtrl.text,
                              ustSira: ustSiraCtrl.text,
                              plusMinus: int.tryParse(plusMinusCtrl.text) ?? s.plusMinus,
                              hesap: '',
                            );
                          });
                          onEdited();
                        },
                        child: const Text('Kaydet'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension _Copy on SahaDetay {
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