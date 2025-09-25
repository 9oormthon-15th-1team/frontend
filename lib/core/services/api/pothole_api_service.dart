import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/pothole.dart';
import '../logging/app_logger.dart';
import 'base_api_service.dart';

class PotholeApiService {
  static const String baseUrl = 'https://goormthon-1.goorm.training/api';

  static Future<List<Pothole>> getPotholes() async {
    try {
      AppLogger.info('Fetching potholes from API...');

      final response = await http.get(
        Uri.parse('$baseUrl/potholes'),
        headers: {'Content-Type': 'application/json'},
      );

      print('=== API Response Debug ===');
      print('URL: $baseUrl/potholes');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body Type: ${response.body.runtimeType}');
      print('Response Body Length: ${response.body.length}');
      print('Response Body: ${response.body}');
      print('========================');

      if (response.statusCode == 200) {
        print('=== JSON Parsing Debug ===');
        final dynamic responseData;

        try {
          responseData = json.decode(response.body);
          print('JSON Decode Success');
          print('Decoded Data Type: ${responseData.runtimeType}');
          if (responseData is Map) {
            print('Map Keys: ${responseData.keys.toList()}');
            responseData.forEach((key, value) {
              print('Key: $key, Value Type: ${value.runtimeType}, Value: $value');
            });
          } else if (responseData is List) {
            print('List Length: ${responseData.length}');
            if (responseData.isNotEmpty) {
              print('First Item Type: ${responseData[0].runtimeType}');
              print('First Item: ${responseData[0]}');
            }
          }
        } catch (e) {
          print('JSON Decode Failed: $e');
          AppLogger.error('JSON decode error: $e');
          throw Exception('Failed to decode JSON response: $e');
        }

        print('===========================');

        // 응답이 List인지 Object인지 확인
        List<dynamic> jsonData;
        if (responseData is List) {
          print('Processing as List directly');
          jsonData = responseData;
        } else if (responseData is Map<String, dynamic>) {
          print('Processing as Map, looking for array field');
          // 서버 응답이 객체 형태인 경우 data 필드에서 배열 추출
          if (responseData.containsKey('data') && responseData['data'] is List) {
            print('Found data field with List');
            jsonData = responseData['data'];
          } else if (responseData.containsKey('potholes') && responseData['potholes'] is List) {
            print('Found potholes field with List');
            jsonData = responseData['potholes'];
          } else if (responseData.containsKey('result') && responseData['result'] is List) {
            print('Found result field with List');
            jsonData = responseData['result'];
          } else {
            // 다른 가능한 키들 체크
            print('No recognizable list field found');
            AppLogger.error('Unknown response structure. Keys: ${responseData.keys.toList()}');
            AppLogger.error('Full response: $responseData');
            throw Exception('Invalid response format: expected list or object with data array. Available keys: ${responseData.keys.join(', ')}');
          }
        } else {
          print('Invalid response type: ${responseData.runtimeType}');
          AppLogger.error('Invalid response type: ${responseData.runtimeType}');
          throw Exception('Invalid response type: ${responseData.runtimeType}');
        }

        final List<Pothole> potholes = jsonData
            .map((json) => Pothole.fromJson(json))
            .toList();

        AppLogger.info('Successfully fetched ${potholes.length} potholes');
        print('=== Parsed Potholes ===');
        for (var pothole in potholes) {
          print(
            'ID: ${pothole.id}, Status: ${pothole.status.toDisplayName()}',
          );
        }
        print('=====================');
        return potholes;
      } else {
        AppLogger.error('Failed to fetch potholes: ${response.statusCode}');
        throw Exception('Failed to load potholes: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching potholes: $e');
      rethrow;
    }
  }

  /// 위치 기반 포트홀 조회 API
  /// GET /potholes/search/location?latitude=&longitude=&distance=
  static Future<List<Pothole>> getPotholesByLocation({
    required double latitude,
    required double longitude,
    required double distance,
  }) async {
    try {
      final List<dynamic> jsonData = await BaseApiService.getList(
        '/potholes/search/location',
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'distance': distance.toString(),
        },
      );

      final List<Pothole> potholes = jsonData
          .map((json) => Pothole.fromJson(json))
          .toList();

      AppLogger.info(
        'Successfully fetched ${potholes.length} potholes near location (${latitude}, ${longitude}) within ${distance}m',
      );

      return potholes;
    } catch (e) {
      AppLogger.error('Error fetching potholes by location: $e');
      rethrow;
    }
  }
}
