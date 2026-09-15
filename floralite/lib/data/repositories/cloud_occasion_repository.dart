import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/mobile_auth_service.dart';
import 'occasion_repository.dart';

typedef CloudOccasionSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudOccasionRepository {
  CloudOccasionRepository({
    MobileAuthService? auth,
    CloudOccasionSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudOccasionSender? _sender;

  static const List<String> defaultRelationships = [
    'Self',
    'Spouse',
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Friend',
    'Colleague',
    'Client',
    'Partner',
    'Relative',
    'Other',
  ];

  static const List<String> defaultOccasions = [
    'Birthday',
    'Anniversary',
    'Valentine\'s Day',
    'Mother\'s Day',
    'Father\'s Day',
    'Women\'s Day',
    'Diwali',
    'New Year',
    'Christmas',
    'Corporate Event',
    'General Reminder',
    'Other',
  ];

  List<String> listRelationshipMaster() => defaultRelationships;
  List<String> listOccasionMaster() => defaultOccasions;

  Future<List<OccasionContactRecord>> listContacts({
    String? query,
    String? occasion,
    DateTime? from,
    DateTime? to,
    String? customerId,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      queryParams['query'] = query.trim();
    }
    if (occasion != null && occasion.trim().isNotEmpty) {
      queryParams['occasion'] = occasion.trim();
    }
    if (customerId != null && customerId.trim().isNotEmpty) {
      queryParams['customerId'] = customerId.trim();
    }
    if (from != null) {
      queryParams['from'] = from.toUtc().toIso8601String();
    }
    if (to != null) {
      queryParams['to'] = to.toUtc().toIso8601String();
    }

    final uri = Uri.parse('${_auth.baseUrl}/api/occasion-contacts').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(OccasionContactRecord.fromCloudJson)
        .toList();
  }

  Future<OccasionContactRecord> createContact({
    required String customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String? recipientPhone,
    String? company,
    String? notes,
    bool reminderEnabled = true,
    String source = 'Manual',
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/occasion-contacts');
    final body = {
      'customerId': customerId,
      'recipientName': recipientName.trim(),
      'relationship': relationship.trim(),
      'occasion': occasion.trim(),
      'occasionDate': occasionDate.toUtc().toIso8601String(),
      'recipientPhone': recipientPhone?.trim(),
      'company': company?.trim(),
      'notes': notes?.trim(),
      'reminderEnabled': reminderEnabled,
      'source': source,
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to create occasion contact');
    }

    return OccasionContactRecord.fromCloudJson(response);
  }

  Future<OccasionContactRecord> updateContact({
    required String id,
    required String customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String? recipientPhone,
    String? company,
    String? notes,
    bool reminderEnabled = true,
    String source = 'Manual',
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/occasion-contacts/$id');
    final body = {
      'customerId': customerId,
      'recipientName': recipientName.trim(),
      'relationship': relationship.trim(),
      'occasion': occasion.trim(),
      'occasionDate': occasionDate.toUtc().toIso8601String(),
      'recipientPhone': recipientPhone?.trim(),
      'company': company?.trim(),
      'notes': notes?.trim(),
      'reminderEnabled': reminderEnabled,
      'source': source,
    };

    final response = await _request('PUT', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to update occasion contact');
    }

    return OccasionContactRecord.fromCloudJson(response);
  }

  Future<void> deleteContact(String id) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/occasion-contacts/$id');
    await _request('DELETE', uri);
  }

  Future<List<Map<String, dynamic>>> listFollowUps({
    required DateTime from,
    required DateTime to,
  }) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/occasion-follow-ups').replace(
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];
    return response.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> markDone({
    required String sourceType,
    required String sourceId,
    required DateTime occurrenceDate,
  }) async {
    final dateStr = Uri.encodeComponent(occurrenceDate.toUtc().toIso8601String());
    final uri = Uri.parse(
      '${_auth.baseUrl}/api/occasion-follow-ups/$sourceType/$sourceId/$dateStr/done',
    );
    await _request('PUT', uri);
  }

  Future<void> snoozeTomorrow({
    required String sourceType,
    required String sourceId,
    required DateTime occurrenceDate,
  }) async {
    final dateStr = Uri.encodeComponent(occurrenceDate.toUtc().toIso8601String());
    final uri = Uri.parse(
      '${_auth.baseUrl}/api/occasion-follow-ups/$sourceType/$sourceId/$dateStr/snooze',
    );
    final snoozedTo = occurrenceDate.add(const Duration(days: 1));
    final body = {'snoozedTo': snoozedTo.toUtc().toIso8601String()};
    await _request('PUT', uri, body: body);
  }

  Future<OccasionScreenData> buildScreenData({
    required DateTime today,
    String search = '',
    String filter = 'All',
    DateTime? specificDate,
  }) async {
    final contacts = await listContacts(query: search);
    final fromDate = today.subtract(const Duration(days: 30));
    final toDate = today.add(const Duration(days: 90));
    final followUps = await listFollowUps(from: fromDate, to: toDate);

    final completedSet = <String>{};
    final snoozedMap = <String, DateTime>{};

    for (final fu in followUps) {
      final sType = (fu['sourceType'] ?? fu['SourceType'])?.toString() ?? '';
      final sId = (fu['sourceId'] ?? fu['SourceId'])?.toString() ?? '';
      final status = (fu['status'] ?? fu['Status'])?.toString().toLowerCase() ?? '';
      final occDate = (fu['occurrenceDate'] ?? fu['OccurrenceDate'])?.toString() ?? '';
      final key = '$sType:$sId:$occDate';

      if (status == 'completed') {
        completedSet.add(key);
      } else if (status == 'snoozed') {
        final snoozeStr = (fu['snoozedToDate'] ?? fu['SnoozedToDate'])?.toString();
        if (snoozeStr != null) {
          final dt = DateTime.tryParse(snoozeStr);
          if (dt != null) {
            snoozedMap[key] = dt;
          }
        }
      }
    }

    final todayDate = DateTime(today.year, today.month, today.day);
    final todayItems = <OccasionFollowUpRecord>[];
    final upcomingItems = <OccasionFollowUpRecord>[];
    final completedItems = <OccasionFollowUpRecord>[];
    final festivalItems = <OccasionFollowUpRecord>[];

    for (final c in contacts) {
      if (!c.reminderEnabled) continue;

      final originalDate = c.occasionDate;
      var effectiveDate = DateTime(today.year, originalDate.month, originalDate.day);
      if (effectiveDate.isBefore(todayDate.subtract(const Duration(days: 7)))) {
        effectiveDate = DateTime(today.year + 1, originalDate.month, originalDate.day);
      }

      final key = 'contact:${c.cloudId}:${effectiveDate.toUtc().toIso8601String()}';
      final isCompleted = completedSet.contains(key);
      if (snoozedMap.containsKey(key)) {
        effectiveDate = snoozedMap[key]!;
      }

      if (specificDate != null) {
        final spec = DateTime(specificDate.year, specificDate.month, specificDate.day);
        final eff = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
        if (!spec.isAtSameMomentAs(eff)) continue;
      }

      final record = OccasionFollowUpRecord(
        sourceType: 'contact',
        sourceId: c.id,
        cloudSourceId: c.cloudId,
        date: effectiveDate,
        title: '${c.recipientName} - ${c.occasion}',
        subtitle: '${c.customerName} (${c.relationship})',
        category: c.occasion,
        customerPhone: c.customerPhone,
        recipientPhone: c.recipientPhone,
        customerId: c.customerId,
        cloudCustomerId: c.cloudCustomerId,
        orderId: null,
        isCompleted: isCompleted,
        isManual: c.source.toLowerCase() == 'manual',
      );

      if (isCompleted) {
        completedItems.add(record);
        continue;
      }

      final effDateOnly = DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
      if (effDateOnly.isAtSameMomentAs(todayDate)) {
        todayItems.add(record);
      } else if (effDateOnly.isAfter(todayDate)) {
        upcomingItems.add(record);
      }
    }

    return OccasionScreenData(
      today: todayItems,
      upcoming: upcomingItems,
      completed: completedItems,
      festival: festivalItems,
    );
  }

  Future<OccasionDashboardSummary> getDashboardSummary(DateTime today) async {
    final data = await buildScreenData(today: today);
    return OccasionDashboardSummary(
      todayFollowUps: data.today.length,
      birthdayCount: data.today
          .where((i) => i.category.toLowerCase().contains('birthday'))
          .length,
      festivalCount: data.festival.length,
      pendingPayments: 0,
    );
  }

  Future<dynamic> _request(
    String method,
    Uri uri, {
    dynamic body,
  }) async {
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
        'Cloud API error ${streamedResponse.statusCode}: $text',
      );
    } finally {
      client.close();
    }
  }
}
