import 'package:flutter/material.dart';

enum PotholeStatus {
  danger('DANGER', '위험'),
  caution('CAUTION', '주의'),
  verificationRequired('VERIFICATION_REQUIRED', '검증필요');

  const PotholeStatus(this.serverValue, this.displayName);

  final String serverValue;
  final String displayName;

  /// 서버 응답값으로부터 PotholeStatus 생성
  static PotholeStatus fromServerValue(String? serverValue) {
    if (serverValue == null) return PotholeStatus.verificationRequired;

    for (final status in PotholeStatus.values) {
      if (status.serverValue == serverValue) {
        return status;
      }
    }
    return PotholeStatus.verificationRequired; // 기본값
  }

  /// 서버로 전송할 값
  String toServerValue() => serverValue;

  /// 화면 표시용 텍스트
  String toDisplayName() => displayName;

  /// 상태에 따른 색상 반환
  Color toColor() {
    switch (this) {
      case PotholeStatus.danger:
        return const Color(0xFFE53E3E); // 빨간색 (위험)
      case PotholeStatus.caution:
        return const Color(0xFFF59E0B); // 노란색 (주의)
      case PotholeStatus.verificationRequired:
        return const Color(0xFF9CA3AF); // 회색 (검증필요)
    }
  }
}