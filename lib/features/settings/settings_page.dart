import 'package:flutter/material.dart';

import 'settings_controller.dart';
import 'widgets/setting_switch_tile.dart';
import 'widgets/setting_slider_tile.dart';
import 'widgets/settings_section.dart';
import 'widgets/setting_accordion_tile.dart';
import 'widgets/setting_info_tile.dart';

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
        toolbarHeight: 56,
        titleSpacing: 0,

        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 100),
        physics: const BouncingScrollPhysics(),
        children: [
          // 알림 설정 섹션
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '알림 설정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2A2A),
              ),
            ),
          ),
          _buildNotificationSection(),
          const SizedBox(height: 40),

          // 정보 섹션
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A2A2A),
              ),
            ),
          ),
          _buildDisplaySection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return SettingsSection(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _controller.urgentAlarmNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: 'assets/svg/Ico_Emer.svg',
              title: '긴급 알림',
              subtitle: '',
              value: value,
              onChanged: _controller.setUrgentAlarm,
            );
          },
        ),
        ValueListenableBuilder<double>(
          valueListenable: _controller.alarmDistanceNotifier,
          builder: (context, value, child) {
            return SettingSliderTile(
              icon: 'assets/svg/Ico_Distance.svg',
              title: '알림 거리',
              subtitle: '',
              value: value,
              min: 0.0,
              max: 1000.0,
              divisions: 20,
              onChanged: _controller.setAlarmDistance,
              formatLabel: _controller.formatDistance,
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _controller.voiceGuideNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: 'assets/svg/Ico_Sound.svg',
              title: '음성 안내',
              subtitle: '',
              value: value,
              onChanged: _controller.setVoiceGuide,
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _controller.vibrationNotifier,
          builder: (context, value, child) {
            return SettingSwitchTile(
              icon: 'assets/svg/Ico_Bell.svg',
              title: '진동',
              subtitle: '',
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
      children: [
        SettingInfoTile(title: '버전 정보', value: '1.00'),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: Color(0xFFE0E0E0),
          indent: 20,
          endIndent: 20,
        ),
        SettingAccordionTile(
          title: '이용 약관',
          content: '''제1조 (목적)
이 약관은 포트홀 알림 서비스(이하 "서비스")의 이용과 관련하여 회사와 이용자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (서비스의 내용)
1. 포트홀 위치 정보 제공
2. 실시간 알림 서비스
3. 사용자 신고 기능

제3조 (이용자의 의무)
1. 이용자는 정확한 정보를 제공해야 합니다.
2. 허위 신고를 하지 않아야 합니다.
3. 서비스를 악용하지 않아야 합니다.

제4조 (서비스의 중단)
회사는 정기점검, 서버 장애 등의 사유로 서비스를 일시 중단할 수 있습니다.''',
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: Color(0xFFE0E0E0),
          indent: 20,
          endIndent: 20,
        ),
        SettingAccordionTile(
          title: '개인정보 처리방침',
          content: '''제1조 (개인정보의 수집 및 이용목적)
회사는 다음의 목적을 위하여 개인정보를 처리합니다.
1. 서비스 제공 및 운영
2. 위치 기반 서비스 제공
3. 고객 문의 대응

제2조 (수집하는 개인정보 항목)
1. 위치 정보 (GPS 좌표)
2. 기기 식별 정보
3. 서비스 이용 기록

제3조 (개인정보의 보유 및 이용기간)
개인정보는 수집 및 이용목적이 달성된 후에는 지체없이 파기합니다.

제4조 (개인정보의 제3자 제공)
회사는 원칙적으로 개인정보를 제3자에게 제공하지 않습니다.

제5조 (개인정보 처리의 위탁)
회사는 개인정보 처리업무를 외부에 위탁할 경우 안전한 처리를 위해 필요한 사항을 규정합니다.''',
        ),
      ],
    );
  }
}
