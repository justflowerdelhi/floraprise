import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/crm_models.dart';
import '../../services/mobile_auth_service.dart';

typedef CloudEnquirySender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudEnquiryRepository {
  CloudEnquiryRepository({
    MobileAuthService? auth,
    CloudEnquirySender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudEnquirySender? _sender;

  Future<dynamic> _request(String method, Uri uri, {dynamic body}) async {
    final sender = _sender;
    if (sender != null) {
      return await sender(method, uri, body: body);
    }

    final token = await _auth.getStoredAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw StateError('Not authenticated with Floraprise Cloud.');
    }

    final client = http.Client();
    try {
      final request = http.Request(method, uri);
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 20));
      final text = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode >= 200 && streamedResponse.statusCode < 300) {
        if (text.trim().isEmpty) return null;
        return jsonDecode(text);
      }

      throw StateError(
          'Request to $uri failed [${streamedResponse.statusCode}]: $text');
    } finally {
      client.close();
    }
  }

  Future<CrmEnquiryItem> create(CrmEnquiryItem item) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/crm/enquiries');
    final payload = item.toCloudJson();

    final response = await _request('POST', uri, body: payload);
    if (response is! Map<String, dynamic>) {
      throw StateError('Invalid response when creating enquiry: $response');
    }

    return CrmEnquiryItem.fromCloudJson(response);
  }

  Future<List<CrmEnquiryItem>> listEnquiries({
    String? status,
    String? query,
    DateTime? fromEventDate,
    DateTime? toEventDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (status != null && status.trim().isNotEmpty && status.trim().toLowerCase() != 'all') {
      queryParams['status'] = status.trim();
    }
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (fromEventDate != null) {
      queryParams['fromEventDate'] = fromEventDate.toUtc().toIso8601String();
    }
    if (toEventDate != null) {
      queryParams['toEventDate'] = toEventDate.toUtc().toIso8601String();
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/crm/enquiries').replace(
      queryParameters: queryParams,
    );

    final response = await _request('GET', uri);
    if (response == null) return const [];

    List itemsRaw;
    if (response is Map<String, dynamic> && response.containsKey('items')) {
      itemsRaw = response['items'] as List? ?? [];
    } else if (response is List) {
      itemsRaw = response;
    } else {
      return const [];
    }

    return itemsRaw
        .whereType<Map<String, dynamic>>()
        .map((j) => CrmEnquiryItem.fromCloudJson(j))
        .toList();
  }

  Future<CrmEnquiryItem?> getById(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/crm/enquiries/$id');
    final response = await _request('GET', uri);
    if (response is! Map<String, dynamic>) return null;
    return CrmEnquiryItem.fromCloudJson(response);
  }

  Future<CrmEnquiryItem> update(CrmEnquiryItem item) async {
    if (item.cloudId == null || item.cloudId!.isEmpty) {
      throw StateError('Cannot update enquiry without a valid cloud ID');
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/crm/enquiries/${item.cloudId}');
    final payload = {
      'category': item.category,
      'requirement': item.requirement,
      'eventDate': item.eventDate?.toUtc().toIso8601String(),
      'budgetAmount': item.budgetPaise != null ? (item.budgetPaise! / 100.0) : null,
      'location': item.location,
      'notes': item.notes,
      'nextAction': item.nextAction,
      'nextFollowUpAtUtc': item.nextFollowUpAt?.toUtc().toIso8601String(),
      'status': item.status,
      'lostReason': item.lostReason,
      'quoteOrderId': item.quoteOrderId,
      'convertedOrderId': item.convertedOrderId,
    };

    final response = await _request('PUT', uri, body: payload);
    if (response is! Map<String, dynamic>) {
      throw StateError('Invalid response when updating enquiry: $response');
    }

    return CrmEnquiryItem.fromCloudJson(response);
  }

  Future<void> delete(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/crm/enquiries/$id');
    await _request('DELETE', uri);
  }

  Future<List<CrmEnquiryItem>> getTodayNewEnquiries(DateTime today) async {
    return listEnquiries(
      status: 'all',
      page: 1,
      pageSize: 50,
    );
  }
}
