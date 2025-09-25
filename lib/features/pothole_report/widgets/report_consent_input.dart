import 'package:flutter/material.dart';
import 'package:frontend/core/theme/design_system.dart';

class ReportConsentInput extends StatefulWidget {
  const ReportConsentInput({super.key});

  @override
  State<ReportConsentInput> createState() => _ReportConsentInputState();
}

class _ReportConsentInputState extends State<ReportConsentInput> {
  bool _isConsentChecked = false; // 체크박스 상태
  final TextEditingController _consentController =
      TextEditingController(); // 입력값 저장

  @override
  void dispose() {
    _consentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 체크박스
        Row(
          children: [
            const Text('민원제출 동의', style: AppTypography.bodyDefault),
            Checkbox(
              value: _isConsentChecked,
              onChanged: (value) {
                setState(() {
                  _isConsentChecked = value ?? false;
                });
              },
            ),
          ],
        ),

        // 조건부 입력 필드
        if (_isConsentChecked) ...[
          const SizedBox(height: 8),
          Text('동의 사유를 입력해주세요', style: AppTypography.bodyDefault),
          const SizedBox(height: 4),
          TextField(
            controller: _consentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '내용을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ],
    );
  }
}
