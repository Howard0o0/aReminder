import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PhotoSaveStrategy {
  appOnly,
  both,
}

class SettingsProvider with ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;

  SettingsProvider._internal();

  static SettingsProvider get instance => _instance;

  late SharedPreferences _prefs;
  PhotoSaveStrategy _photoSaveStrategy = PhotoSaveStrategy.appOnly;

  PhotoSaveStrategy get photoSaveStrategy => _photoSaveStrategy;

  int _cameraFPS = 30;
  int get cameraFPS => _cameraFPS;

  bool _isLivePhotoEnabled = false;
  bool get isLivePhotoEnabled => _isLivePhotoEnabled;

  bool _skipSplashAnimation = false;
  bool get skipSplashAnimation => _skipSplashAnimation;

  bool _nullTimeAsNow = false;
  bool get nullTimeAsNow => _nullTimeAsNow;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _photoSaveStrategy =
        PhotoSaveStrategy.values[_prefs.getInt('photo_save_strategy') ?? 0];
    _cameraFPS = _prefs.getInt('camera_fps') ?? 30;
    _isLivePhotoEnabled = _prefs.getBool('live_photo_enabled') ?? false;
    _skipSplashAnimation = _prefs.getBool('skip_splash_animation') ?? false;
    _nullTimeAsNow = _prefs.getBool('null_time_as_now') ?? false;

    _initialized = true;
    notifyListeners();
  }

  Future<void> setPhotoSaveStrategy(PhotoSaveStrategy strategy) async {
    print('设置保存策略: $strategy');
    _photoSaveStrategy = strategy;
    await _prefs.setInt('photo_save_strategy', strategy.index);
    notifyListeners();
  }

  void setCameraFPS(int fps) async {
    _cameraFPS = fps;
    await _prefs.setInt('camera_fps', fps);
    notifyListeners();
  }

  Future<void> setLivePhotoEnabled(bool enabled) async {
    _isLivePhotoEnabled = enabled;
    await _prefs.setBool('live_photo_enabled', enabled);
    notifyListeners();
  }

  Future<void> setSkipSplashAnimation(bool skip) async {
    _skipSplashAnimation = skip;
    await _prefs.setBool('skip_splash_animation', skip);
    notifyListeners();
  }

  Future<void> setNullTimeAsNow(bool value) async {
    _nullTimeAsNow = value;
    await _prefs.setBool('null_time_as_now', value);
    notifyListeners();
  }
}
