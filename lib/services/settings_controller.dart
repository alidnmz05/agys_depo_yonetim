import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController._();
  static final instance = SettingsController._();

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

  late SharedPreferences _sp;

  Future<void> init() async => _sp = await SharedPreferences.getInstance();

  // API key (eski)
  String get apiKey => _sp.getString('api_key') ?? '';
  set apiKey(String v) => _sp.setString('api_key', v);

  // JWT token (YENİ)
  String get token => _sp.getString('token') ?? '';
  set token(String v) => _sp.setString('token', v);
  Future<void> clearToken() async => _sp.remove('token');

  // Antrepo ve Base URL
  int get antrepoId => _sp.getInt('antrepo_id') ?? 1;
  set antrepoId(int v) => _sp.setInt('antrepo_id', v);

  String get baseUrl =>
      _sp.getString('base_url') ?? 'http://213.159.6.209:65062';
  set baseUrl(String v) => _sp.setString('base_url', v);
}
