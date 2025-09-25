import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // 알림 설정 키
  static const String urgentAlarmKey = 'urgent_alarm';
  static const String alarmDistanceKey = 'alarm_distance';
  static const String voiceGuideKey = 'voice_guide';
  static const String vibrationKey = 'vibration';
  static const String nightModeKey = 'night_mode';

  // 표시 설정 키
  static const String dangerOnlyKey = 'danger_only';
  static const String showCompletedKey = 'show_completed';
  static const String recent7DaysKey = 'recent_7days';

  // 기본값들
  static const bool defaultUrgentAlarm = true;
  static const double defaultAlarmDistance = 500.0;
  static const bool defaultVoiceGuide = true;
  static const bool defaultVibration = true;
  static const bool defaultNightMode = false;
  static const bool defaultDangerOnly = false;
  static const bool defaultShowCompleted = true;
  static const bool defaultRecent7Days = false;

  static SharedPreferences? _prefs;

  // SharedPreferences 인스턴스 초기화
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // SharedPreferences 인스턴스 getter
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
        'SettingsService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  // 알림 설정 - 긴급 알림
  static bool getUrgentAlarm() {
    return prefs.getBool(urgentAlarmKey) ?? defaultUrgentAlarm;
  }

  static Future<bool> setUrgentAlarm(bool value) {
    return prefs.setBool(urgentAlarmKey, value);
  }

  // 알림 설정 - 알림 거리
  static double getAlarmDistance() {
    return prefs.getDouble(alarmDistanceKey) ?? defaultAlarmDistance;
  }

  static Future<bool> setAlarmDistance(double value) {
    return prefs.setDouble(alarmDistanceKey, value);
  }

  // 알림 설정 - 음성 안내
  static bool getVoiceGuide() {
    return prefs.getBool(voiceGuideKey) ?? defaultVoiceGuide;
  }

  static Future<bool> setVoiceGuide(bool value) {
    return prefs.setBool(voiceGuideKey, value);
  }

  // 알림 설정 - 진동
  static bool getVibration() {
    return prefs.getBool(vibrationKey) ?? defaultVibration;
  }

  static Future<bool> setVibration(bool value) {
    return prefs.setBool(vibrationKey, value);
  }

  // 알림 설정 - 야간 모드
  static bool getNightMode() {
    return prefs.getBool(nightModeKey) ?? defaultNightMode;
  }

  static Future<bool> setNightMode(bool value) {
    return prefs.setBool(nightModeKey, value);
  }

  // 표시 설정 - 위험만 표시
  static bool getDangerOnly() {
    return prefs.getBool(dangerOnlyKey) ?? defaultDangerOnly;
  }

  static Future<bool> setDangerOnly(bool value) {
    return prefs.setBool(dangerOnlyKey, value);
  }

  // 표시 설정 - 완료 표시
  static bool getShowCompleted() {
    return prefs.getBool(showCompletedKey) ?? defaultShowCompleted;
  }

  static Future<bool> setShowCompleted(bool value) {
    return prefs.setBool(showCompletedKey, value);
  }

  // 표시 설정 - 최근 7일만
  static bool getRecent7Days() {
    return prefs.getBool(recent7DaysKey) ?? defaultRecent7Days;
  }

  static Future<bool> setRecent7Days(bool value) {
    return prefs.setBool(recent7DaysKey, value);
  }

  // 모든 설정 초기화
  static Future<void> resetAllSettings() async {
    await Future.wait([
      setUrgentAlarm(defaultUrgentAlarm),
      setAlarmDistance(defaultAlarmDistance),
      setVoiceGuide(defaultVoiceGuide),
      setVibration(defaultVibration),
      setNightMode(defaultNightMode),
      setDangerOnly(defaultDangerOnly),
      setShowCompleted(defaultShowCompleted),
      setRecent7Days(defaultRecent7Days),
    ]);
  }

  // 모든 설정값을 Map으로 반환 (디버그용)
  static Map<String, dynamic> getAllSettings() {
    return {
      'urgentAlarm': getUrgentAlarm(),
      'alarmDistance': getAlarmDistance(),
      'voiceGuide': getVoiceGuide(),
      'vibration': getVibration(),
      'nightMode': getNightMode(),
      'dangerOnly': getDangerOnly(),
      'showCompleted': getShowCompleted(),
      'recent7Days': getRecent7Days(),
    };
  }
}
