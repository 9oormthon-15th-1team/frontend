import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/pothole_report.dart';
import '../logging/app_logger.dart';
import 'pothole_api_service.dart';

/// 포트홀 신고 데이터를 서버로 전송하는 서비스
class PotholeReportService {
  /// 포트홀 신고를 JSON 형태로 전송합니다.
  static Future<void> pushReport(PotholeReport report) async {
    final uri = Uri.parse('${PotholeApiService.baseUrl}/potholes');
    final payload = jsonEncode(report.toJson());

    AppLogger.info('포트홀 신고 전송 시작: ${report.id}');

    try {
      final response = await http.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      AppLogger.info(
        '포트홀 신고 응답: ${response.statusCode}, body: ${response.body}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('포트홀 신고 전송 실패: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('포트홀 신고 중 오류', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
