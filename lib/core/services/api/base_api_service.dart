import 'dart:convert';
import 'package:http/http.dart' as http;
import '../logging/app_logger.dart';

/// HTTP API 호출을 위한 기본 서비스 클래스
class BaseApiService {
  static const String baseUrl = 'https://goormthon-1.goorm.training/api';
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
      };

  /// GET 요청
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final requestHeaders = {..._defaultHeaders, ...?headers};

      AppLogger.info('GET Request: $uri');

      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(timeout);

      return _handleResponse(response, 'GET', endpoint);
    } catch (e) {
      AppLogger.error('GET request failed for $endpoint: $e');
      rethrow;
    }
  }

  /// POST 요청
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = {..._defaultHeaders, ...?headers};
      final body = json.encode(data);

      AppLogger.info('POST Request: $uri');
      AppLogger.info('POST Body: $body');

      final response = await http
          .post(uri, headers: requestHeaders, body: body)
          .timeout(timeout);

      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      AppLogger.error('POST request failed for $endpoint: $e');
      rethrow;
    }
  }

  /// PUT 요청
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = {..._defaultHeaders, ...?headers};
      final body = json.encode(data);

      AppLogger.info('PUT Request: $uri');

      final response = await http
          .put(uri, headers: requestHeaders, body: body)
          .timeout(timeout);

      return _handleResponse(response, 'PUT', endpoint);
    } catch (e) {
      AppLogger.error('PUT request failed for $endpoint: $e');
      rethrow;
    }
  }

  /// DELETE 요청
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final requestHeaders = {..._defaultHeaders, ...?headers};

      AppLogger.info('DELETE Request: $uri');

      final response = await http
          .delete(uri, headers: requestHeaders)
          .timeout(timeout);

      return _handleResponse(response, 'DELETE', endpoint);
    } catch (e) {
      AppLogger.error('DELETE request failed for $endpoint: $e');
      rethrow;
    }
  }

  /// List 데이터를 반환하는 GET 요청
  static Future<List<dynamic>> getList(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final requestHeaders = {..._defaultHeaders, ...?headers};

      AppLogger.info('GET List Request: $uri');

      final response = await http
          .get(uri, headers: requestHeaders)
          .timeout(timeout);

      return _handleListResponse(response, 'GET', endpoint);
    } catch (e) {
      AppLogger.error('GET list request failed for $endpoint: $e');
      rethrow;
    }
  }

  /// URI 빌드 헬퍼
  static Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final url = endpoint.startsWith('http') ? endpoint : '$baseUrl$endpoint';
    final uri = Uri.parse(url);

    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }

    return uri;
  }

  /// HTTP 응답 처리 (Object 반환)
  static Map<String, dynamic> _handleResponse(
    http.Response response,
    String method,
    String endpoint,
  ) {
    AppLogger.info('$method $endpoint - Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return <String, dynamic>{};
      }

      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          return {'data': decoded};
        }
      } catch (e) {
        AppLogger.error('Failed to parse response body: $e');
        throw Exception('Invalid JSON response');
      }
    } else {
      final errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      AppLogger.error('$method $endpoint failed - $errorMessage');
      AppLogger.error('Response body: ${response.body}');
      throw HttpException(
        message: errorMessage,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }

  /// HTTP 응답 처리 (List 반환)
  static List<dynamic> _handleListResponse(
    http.Response response,
    String method,
    String endpoint,
  ) {
    AppLogger.info('$method $endpoint - Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return [];
      }

      try {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map<String, dynamic>) {
          // 다양한 가능한 키 패턴 확인
          if (decoded.containsKey('data') && decoded['data'] is List) {
            return decoded['data'] as List;
          } else if (decoded.containsKey('potholes') && decoded['potholes'] is List) {
            return decoded['potholes'] as List;
          } else if (decoded.containsKey('result') && decoded['result'] is List) {
            return decoded['result'] as List;
          } else if (decoded.containsKey('items') && decoded['items'] is List) {
            return decoded['items'] as List;
          } else if (decoded.containsKey('list') && decoded['list'] is List) {
            return decoded['list'] as List;
          } else {
            // 응답 구조 로깅
            AppLogger.error('Unknown response structure. Available keys: ${decoded.keys.toList()}');
            AppLogger.error('Response body: ${response.body}');
            throw Exception('Response does not contain a recognizable list field. Available keys: ${decoded.keys.join(', ')}');
          }
        } else {
          throw Exception('Response is neither a list nor an object. Type: ${decoded.runtimeType}');
        }
      } catch (e) {
        if (e.toString().contains('Response does not contain') || e.toString().contains('Response is neither')) {
          rethrow; // 이미 처리된 구조적 오류는 재던짐
        }
        AppLogger.error('Failed to parse JSON response: $e');
        AppLogger.error('Raw response body: ${response.body}');
        throw Exception('Invalid JSON response: $e');
      }
    } else {
      final errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      AppLogger.error('$method $endpoint failed - $errorMessage');
      AppLogger.error('Response body: ${response.body}');
      throw HttpException(
        message: errorMessage,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
  }
}

/// HTTP 예외 클래스
class HttpException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  const HttpException({
    required this.message,
    required this.statusCode,
    required this.responseBody,
  });

  @override
  String toString() => 'HttpException: $message';
}