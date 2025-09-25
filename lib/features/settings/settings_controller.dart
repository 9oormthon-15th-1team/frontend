import 'package:flutter/material.dart';
import 'services/settings_service.dart';

/// Settings 페이지의 비즈니스 로직을 담당하는 컨트롤러
class SettingsController {
  // 알림 설정
  final ValueNotifier<bool> _urgentAlarm = ValueNotifier<bool>(true);
  final ValueNotifier<double> _alarmDistance = ValueNotifier<double>(500.0);
  final ValueNotifier<bool> _voiceGuide = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _vibration = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _nightMode = ValueNotifier<bool>(false);

  // 표시 설정
  final ValueNotifier<bool> _dangerOnly = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _showCompleted = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _recent7Days = ValueNotifier<bool>(false);

  // 알림 설정 notifiers
  ValueNotifier<bool> get urgentAlarmNotifier => _urgentAlarm;
  ValueNotifier<double> get alarmDistanceNotifier => _alarmDistance;
  ValueNotifier<bool> get voiceGuideNotifier => _voiceGuide;
  ValueNotifier<bool> get vibrationNotifier => _vibration;
  ValueNotifier<bool> get nightModeNotifier => _nightMode;

  // 표시 설정 notifiers
  ValueNotifier<bool> get dangerOnlyNotifier => _dangerOnly;
  ValueNotifier<bool> get showCompletedNotifier => _showCompleted;
  ValueNotifier<bool> get recent7DaysNotifier => _recent7Days;

  // 현재 설정 값들
  bool get urgentAlarm => _urgentAlarm.value;
  double get alarmDistance => _alarmDistance.value;
  bool get voiceGuide => _voiceGuide.value;
  bool get vibration => _vibration.value;
  bool get nightMode => _nightMode.value;
  bool get dangerOnly => _dangerOnly.value;
  bool get showCompleted => _showCompleted.value;
  bool get recent7Days => _recent7Days.value;

  /// 컨트롤러 초기화
  Future<void> initialize() async {
    await SettingsService.initialize();
    _loadSettings();
  }

  /// 설정 로드
  void _loadSettings() {
    // 알림 설정 로드
    _urgentAlarm.value = SettingsService.getUrgentAlarm();
    _alarmDistance.value = SettingsService.getAlarmDistance();
    _voiceGuide.value = SettingsService.getVoiceGuide();
    _vibration.value = SettingsService.getVibration();
    _nightMode.value = SettingsService.getNightMode();

    // 표시 설정 로드
    _dangerOnly.value = SettingsService.getDangerOnly();
    _showCompleted.value = SettingsService.getShowCompleted();
    _recent7Days.value = SettingsService.getRecent7Days();
  }

  // 알림 설정 변경 메서드들
  Future<void> setUrgentAlarm(bool enabled) async {
    _urgentAlarm.value = enabled;
    await SettingsService.setUrgentAlarm(enabled);
  }

  Future<void> setAlarmDistance(double distance) async {
    if (distance >= 100.0 && distance <= 1000.0) {
      _alarmDistance.value = distance;
      await SettingsService.setAlarmDistance(distance);
    }
  }

  Future<void> setVoiceGuide(bool enabled) async {
    _voiceGuide.value = enabled;
    await SettingsService.setVoiceGuide(enabled);
  }

  Future<void> setVibration(bool enabled) async {
    _vibration.value = enabled;
    await SettingsService.setVibration(enabled);
  }

  Future<void> setNightMode(bool enabled) async {
    _nightMode.value = enabled;
    await SettingsService.setNightMode(enabled);
  }

  // 표시 설정 변경 메서드들
  Future<void> setDangerOnly(bool enabled) async {
    _dangerOnly.value = enabled;
    await SettingsService.setDangerOnly(enabled);
  }

  Future<void> setShowCompleted(bool enabled) async {
    _showCompleted.value = enabled;
    await SettingsService.setShowCompleted(enabled);
  }

  Future<void> setRecent7Days(bool enabled) async {
    _recent7Days.value = enabled;
    await SettingsService.setRecent7Days(enabled);
  }

  /// 모든 설정 초기화
  Future<void> resetSettings() async {
    await SettingsService.resetAllSettings();
    _loadSettings();
  }

  /// 거리를 문자열로 포맷
  String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  /// 설정을 Map으로 변환 (디버그용)
  Map<String, dynamic> toMap() {
    return SettingsService.getAllSettings();
  }

  /// 메모리 해제
  void dispose() {
    // 알림 설정 dispose
    _urgentAlarm.dispose();
    _alarmDistance.dispose();
    _voiceGuide.dispose();
    _vibration.dispose();
    _nightMode.dispose();

    // 표시 설정 dispose
    _dangerOnly.dispose();
    _showCompleted.dispose();
    _recent7Days.dispose();
  }
}