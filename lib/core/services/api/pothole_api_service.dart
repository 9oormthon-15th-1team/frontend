import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/pothole.dart';
import '../logging/app_logger.dart';

class PotholeApiService {
  static const String baseUrl = 'https://goormthon-1.goorm.training/api/api';

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
      print('Response Body: ${response.body}');
      print('========================');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Pothole> potholes = jsonData
            .map((json) => Pothole.fromJson(json))
            .toList();

        AppLogger.info('Successfully fetched ${potholes.length} potholes');
        print('=== Parsed Potholes ===');
        for (var pothole in potholes) {
          print(
            'ID: ${pothole.id}, Severity: ${pothole.severity}, Status: ${pothole.status}',
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
}
