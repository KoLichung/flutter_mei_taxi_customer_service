import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://ai-taxi-api-5koy2twboa-de.a.run.app';
  static const String apiKey = 'customer_service_api_key_2024_temp';

  // 通用請求方法
  static Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = {
        'Content-Type': 'application/json',
        'X-API-Key': apiKey,
      };

      http.Response response;

      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw ApiException(
          message: responseData['message'] ?? '請求失敗',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(
        message: '網絡錯誤: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 獲取最近20筆司機對話列表
  static Future<List<Map<String, dynamic>>> getRecentDriverConversations() async {
    final response = await _request(
      'GET',
      '/api/customer-service/drivers/recent-conversations/',
    );

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['drivers'] ?? []);
    } else {
      throw ApiException(
        message: response['message'] ?? '獲取對話列表失敗',
        statusCode: 0,
      );
    }
  }

  // 獲取司機系統訊息（分頁）
  static Future<Map<String, dynamic>> getDriverSystemMessages({
    required int driverId,
    int? conversationId,
    String viewType = 'system',
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {
      'driver_id': driverId.toString(),
      'view_type': viewType,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (conversationId != null) {
      queryParams['conversation_id'] = conversationId.toString();
    }

    final response = await _request(
      'GET',
      '/api/customer-service/driver-system-messages/',
      queryParams: queryParams,
    );

    if (response['status'] == 'success') {
      return response;
    } else {
      throw ApiException(
        message: response['message'] ?? '獲取訊息失敗',
        statusCode: 0,
      );
    }
  }

  // 創建司機系統訊息
  static Future<Map<String, dynamic>> createDriverSystemMessage({
    required int driverId,
    required String content,
    int? conversationId,
  }) async {
    final body = <String, dynamic>{
      'driver_id': driverId,
      'content': content,
      'is_from_system': false,
    };

    if (conversationId != null) {
      body['conversation_id'] = conversationId;
    }

    final response = await _request(
      'POST',
      '/api/customer-service/driver-system-messages/create/',
      body: body,
    );

    if (response['status'] == 'success') {
      return response;
    } else {
      throw ApiException(
        message: response['message'] ?? '發送訊息失敗',
        statusCode: 0,
      );
    }
  }

  // 搜尋司機
  static Future<List<Map<String, dynamic>>> searchDrivers({
    String? phone,
    String? vehicleLicence,
    String? name,
  }) async {
    final queryParams = <String, String>{};

    if (phone != null && phone.isNotEmpty) {
      queryParams['phone'] = phone;
    }
    if (vehicleLicence != null && vehicleLicence.isNotEmpty) {
      queryParams['vehical_licence'] = vehicleLicence;
    }
    if (name != null && name.isNotEmpty) {
      queryParams['name'] = name;
    }

    if (queryParams.isEmpty) {
      return [];
    }

    final response = await _request(
      'GET',
      '/api/customer-service/drivers/search/',
      queryParams: queryParams,
    );

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(response['drivers'] ?? []);
    } else {
      throw ApiException(
        message: response['message'] ?? '搜尋司機失敗',
        statusCode: 0,
      );
    }
  }

  // 司機儲值
  static Future<Map<String, dynamic>> rechargeDriver({
    required int driverId,
    required double amount,
    String? memo,
  }) async {
    final body = <String, dynamic>{
      'driver_id': driverId,
      'amount': amount,
    };

    if (memo != null && memo.isNotEmpty) {
      body['memo'] = memo;
    }

    final response = await _request(
      'POST',
      '/api/customer-service/drivers/recharge/',
      body: body,
    );

    if (response['status'] == 'success') {
      return response;
    } else {
      throw ApiException(
        message: response['message'] ?? '儲值失敗',
        statusCode: 0,
      );
    }
  }

  // 獲取司機儲值記錄
  static Future<Map<String, dynamic>> getDriverRechargeRecords({
    required int driverId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = {
      'driver_id': driverId.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    final response = await _request(
      'GET',
      '/api/customer-service/drivers/store-money/',
      queryParams: queryParams,
    );

    if (response['status'] == 'success') {
      return response;
    } else {
      throw ApiException(
        message: response['message'] ?? '獲取儲值記錄失敗',
        statusCode: 0,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}

