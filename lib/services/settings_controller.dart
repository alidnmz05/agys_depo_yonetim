// lib/services/settings_controller.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final instance = SettingsController._();

  // Eski anahtarlar (mevcut yapıyı koru)
  static const _kShowLocation = 'show_location';
  static const _kFirstRunDone = 'first_run_done';

  bool _showLocation = false;
  bool get showLocation => _showLocation;

  bool _firstRunDone = false;
  bool get firstRunDone => _firstRunDone;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _showLocation = p.getBool(_kShowLocation) ?? false;
    _firstRunDone = p.getBool(_kFirstRunDone) ?? false;
  }

  Future<void> setShowLocation(bool v) async {
    _showLocation = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowLocation, v);
    notifyListeners();
  }

  Future<void> setFirstRunDone() async {
    _firstRunDone = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFirstRunDone, true);
  }

  // Yeni ayarlar
  SharedPreferences? _sp;

  Future<void> init() async {
    _sp ??= await SharedPreferences.getInstance();

    // Yanlış kaydı düzelt: apiKey'e URL yazılmışsa taşı
    final savedKey = _sp!.getString('api_key') ?? '';
    if (savedKey.startsWith('http')) {
      await _sp!.setString('base_url', savedKey);
      await _sp!.setString('api_key', '');
    }
    // Varsayılan base url
    if ((_sp!.getString('base_url') ?? '').isEmpty) {
      await _sp!.setString('base_url', 'http://213.159.6.209:65062');
    }
    // Varsayılan antrepo
    _sp!.getInt('antrepo_id') ?? await _sp!.setInt('antrepo_id', 1);
  }

  // Güvenli getter'lar
  String get apiKey => (_sp?.getString('api_key')) ?? '';
  int get antrepoId => (_sp?.getInt('antrepo_id')) ?? 1;
  String get baseUrl =>
      (_sp?.getString('base_url')) ?? 'http://213.159.6.209:65062';

  // Setter'lar (init çağrılmamışsa kendileri hazırlar)
  set apiKey(String v) {
    _setAsync((p) => p.setString('api_key', v.trim()));
  }

  set antrepoId(int v) {
    _setAsync((p) => p.setInt('antrepo_id', v));
  }

  set baseUrl(String v) {
    _setAsync((p) => p.setString('base_url', v.trim()));
  }

  void _setAsync(Future<bool> Function(SharedPreferences) fn) async {
    final p = _sp ??= await SharedPreferences.getInstance();
    await fn(p);
  }
}
