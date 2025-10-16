import 'package:agys_depo_yonetim/pages/ayarlar.dart';
import 'package:agys_depo_yonetim/pages/beyanname_liste_page.dart';
import 'package:agys_depo_yonetim/pages/bolgeler.dart';
import 'package:agys_depo_yonetim/pages/login_page.dart';
import 'package:agys_depo_yonetim/pages/qr/qr_scan_page.dart';
import 'package:agys_depo_yonetim/services/settings_controller.dart';
import 'package:flutter/material.dart';
// import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsController.instance.load();
  await SettingsController.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsController.instance,
      builder: (context, _) {
        return MaterialApp(
          routes: {
            '/ayarlar': (_) => const AyarlarPage(),
            '/bolge': (ctx) => const BolgePage(),
            '/login': (_) => const LoginPage(),
            '/qr/scan': (_) => const QrScanPage(),
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          debugShowCheckedModeBanner: false,
          home: const BeyannameListePage(),
        );
      },
    );
  }
}
