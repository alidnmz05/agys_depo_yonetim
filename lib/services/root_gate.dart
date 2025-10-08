import 'package:agys_depo_yonetim/pages/beyanname_liste_page.dart';
import 'package:agys_depo_yonetim/pages/ilk_acilis_konum.dart';
import 'package:agys_depo_yonetim/services/settings_controller.dart';
import 'package:flutter/material.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});
  @override
  State<RootGate> createState() => _RG();
}

class _RG extends State<RootGate> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeFirstRun();
  }

  Future<void> _maybeFirstRun() async {
    if (SettingsController.instance.firstRunDone) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FirstRunSettingsPage()),
      );
      setState(() {}); // döndükten sonra yenile
    });
  }

  @override
  Widget build(BuildContext context) => const BeyannameListePage();
}
