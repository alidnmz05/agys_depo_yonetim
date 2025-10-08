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
}
