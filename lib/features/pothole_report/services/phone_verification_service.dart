import '../../../core/services/logging/app_logger.dart';

/// 전화번호 인증을 담당하는 서비스
class PhoneVerificationService {
  /// 인증번호 발송
  ///
  /// [phoneNumber] 전화번호
  ///
  /// Returns: true if successful
  /// Throws: [PhoneVerificationException] 발송 실패 시
  static Future<bool> sendVerificationCode(String phoneNumber) async {
    try {
      // 전화번호 검증
      if (!_isValidPhoneNumber(phoneNumber)) {
        throw PhoneVerificationException('올바른 전화번호 형식이 아닙니다');
      }

      AppLogger.info('인증번호 발송 시작: $phoneNumber');

      // TODO: 실제 SMS API 호출
      // 현재는 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));

      AppLogger.info('인증번호 발송 성공');
      return true;
    } catch (e) {
      if (e is PhoneVerificationException) {
        rethrow;
      }
      AppLogger.error('인증번호 발송 실패', error: e);
      throw PhoneVerificationException('인증번호 발송 중 오류가 발생했습니다');
    }
  }

  /// 인증번호 검증
  ///
  /// [phoneNumber] 전화번호
  /// [code] 인증번호
  ///
  /// Returns: true if verification is successful
  /// Throws: [PhoneVerificationException] 검증 실패 시
  static Future<bool> verifyCode(String phoneNumber, String code) async {
    try {
      if (code.trim().isEmpty) {
        throw PhoneVerificationException('인증번호를 입력해주세요');
      }

      AppLogger.info('인증번호 검증 시작: $phoneNumber');

      // TODO: 실제 서버 검증 API 호출
      // 현재는 시뮬레이션 (1234가 올바른 코드)
      await Future.delayed(const Duration(milliseconds: 500));

      if (code == '1234') {
        AppLogger.info('인증번호 검증 성공');
        return true;
      } else {
        throw PhoneVerificationException('잘못된 인증번호입니다');
      }
    } catch (e) {
      if (e is PhoneVerificationException) {
        rethrow;
      }
      AppLogger.error('인증번호 검증 실패', error: e);
      throw PhoneVerificationException('인증번호 검증 중 오류가 발생했습니다');
    }
  }

  /// 전화번호 형식 검증
  ///
  /// 한국 휴대전화 번호 형식을 검증합니다 (010-xxxx-xxxx)
  static bool _isValidPhoneNumber(String phoneNumber) {
    // 숫자만 추출
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // 한국 휴대전화 번호 형식: 010으로 시작하고 11자리
    if (digitsOnly.length != 11) {
      return false;
    }

    if (!digitsOnly.startsWith('010')) {
      return false;
    }

    return true;
  }

  /// 전화번호 포맷팅 (010-1234-5678)
  static String formatPhoneNumber(String phoneNumber) {
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length != 11) {
      return phoneNumber; // 유효하지 않으면 그대로 반환
    }

    return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 7)}-${digitsOnly.substring(7)}';
  }
}

/// 전화번호 인증 관련 예외
class PhoneVerificationException implements Exception {
  final String message;

  PhoneVerificationException(this.message);

  @override
  String toString() => message;
}
