import 'package:flutter/material.dart';

/// Settings 페이지의 비즈니스 로직을 담당하는 컨트롤러
class SettingsController {
  final ValueNotifier<bool> _notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _darkModeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<double> _textScale = ValueNotifier<double>(1.0);

  /// 알림 설정 notifier
  ValueNotifier<bool> get notificationsEnabledNotifier => _notificationsEnabled;

  /// 다크 모드 설정 notifier
  ValueNotifier<bool> get darkModeEnabledNotifier => _darkModeEnabled;

  /// 텍스트 크기 설정 notifier
  ValueNotifier<double> get textScaleNotifier => _textScale;

  /// 현재 설정 값들
  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get darkModeEnabled => _darkModeEnabled.value;
  double get textScale => _textScale.value;

  /// 컨트롤러 초기화
  void initialize() {
    _loadSettings();
  }

  /// 설정 로드 (실제 앱에서는 SharedPreferences 등을 사용)
  void _loadSettings() {
    // TODO: 실제 저장된 설정 로드
    _notificationsEnabled.value = true;
    _darkModeEnabled.value = false;
    _textScale.value = 1.0;
  }

  /// 알림 설정 변경
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled.value = enabled;
    _saveSettings();
  }

  /// 다크 모드 설정 변경
  void setDarkModeEnabled(bool enabled) {
    _darkModeEnabled.value = enabled;
    _saveSettings();
  }

  /// 텍스트 크기 설정 변경
  void setTextScale(double scale) {
    if (scale >= 0.8 && scale <= 1.5) {
      _textScale.value = scale;
      _saveSettings();
    }
  }

  /// 모든 설정 초기화
  void resetSettings() {
    _notificationsEnabled.value = true;
    _darkModeEnabled.value = false;
    _textScale.value = 1.0;
    _saveSettings();
  }

  /// 설정 저장 (실제 앱에서는 SharedPreferences 등을 사용)
  void _saveSettings() {
    // TODO: 실제 설정 저장 로직 구현
    // SharedPreferences 등을 사용하여 로컬에 저장
  }

  /// 설정을 Map으로 변환 (디버그용)
  Map<String, dynamic> toMap() {
    return {
      'notifications_enabled': _notificationsEnabled.value,
      'dark_mode_enabled': _darkModeEnabled.value,
      'text_scale': _textScale.value,
    };
  }

  /// 메모리 해제
  void dispose() {
    _notificationsEnabled.dispose();
    _darkModeEnabled.dispose();
    _textScale.dispose();
  }
}