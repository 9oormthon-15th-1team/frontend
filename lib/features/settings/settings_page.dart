import 'package:flutter/material.dart';

import 'settings_controller.dart';
import 'widgets/setting_switch_tile.dart';
import 'widgets/setting_slider_tile.dart';
import 'widgets/settings_section.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsController _controller = SettingsController();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // 알림 설정 섹션
          _buildNotificationSection(),
          const SizedBox(height: 24),

          // 표시 설정 섹션
          _buildDisplaySection(),
          const SizedBox(height: 24),

          // 기타 설정 섹션
          _buildOtherSection(),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return SettingsSection(
      title: '알림 설정',
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _controller.urgentAlarmNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: Icons.notification_important,
              iconColor: Colors.red,
              title: '긴급 알림',
              subtitle: '위험한 포트홀에 접근 시 알림',
              value: value,
              onChanged: _controller.setUrgentAlarm,
            );
          },
        ),
        const Divider(height: 1),
        ValueListenableBuilder<double>(
          valueListenable: _controller.alarmDistanceNotifier,
          builder: (context, value, child) {
            return SettingSliderTile(
              icon: Icons.straighten,
              title: '알림 거리',
              subtitle: _controller.formatDistance(value),
              value: value,
              min: 100.0,
              max: 1000.0,
              divisions: 18,
              onChanged: _controller.setAlarmDistance,
              formatLabel: _controller.formatDistance,
            );
          },
        ),
        const Divider(height: 1),
        ValueListenableBuilder<bool>(
          valueListenable: _controller.voiceGuideNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: Icons.volume_up,
              title: '음성 안내',
              subtitle: '알림 시 음성으로 안내',
              value: value,
              onChanged: _controller.setVoiceGuide,
            );
          },
        ),
        const Divider(height: 1),
        ValueListenableBuilder<bool>(
          valueListenable: _controller.vibrationNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: Icons.vibration,
              title: '진동',
              subtitle: '알림 시 진동 피드백',
              value: value,
              onChanged: _controller.setVibration,
            );
          },
        ),
      ],
    );
  }

  Widget _buildDisplaySection() {
    return SettingsSection(
      title: '표시 설정',
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _controller.dangerOnlyNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: Icons.warning,
              iconColor: Colors.amber,
              title: '위험만 표시',
              subtitle: '위헙 등급의 포트홀만 표시',
              value: value,
              onChanged: _controller.setDangerOnly,
            );
          },
        ),
        const Divider(height: 1),
        ValueListenableBuilder<bool>(
          valueListenable: _controller.recent7DaysNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: Icons.calendar_today,
              iconColor: Colors.blue,
              title: '최근 7일만',
              subtitle: '최근 7일 내 신고된 포트홀만 표시',
              value: value,
              onChanged: _controller.setRecent7Days,
            );
          },
        ),
      ],
    );
  }


  Widget _buildOtherSection() {
    return SettingsSection(
      title: '기타',
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.refresh,
              color: Colors.red,
              size: 24,
            ),
          ),
          title: const Text('설정 초기화'),
          subtitle: const Text('모든 설정을 기본값으로 초기화'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showResetDialog,
        ),
      ],
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('설정 초기화'),
          content: const Text('정말로 모든 설정을 기본값으로 초기화하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _controller.resetSettings();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('설정이 초기화되었습니다'),
                      backgroundColor: Color(0xFFFF5722),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
              ),
              child: const Text('초기화'),
            ),
          ],
        );
      },
    );
  }
}