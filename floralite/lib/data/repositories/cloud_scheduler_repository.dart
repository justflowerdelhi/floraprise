import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/scheduler_task.dart';
import '../../services/mobile_auth_service.dart';

typedef CloudSchedulerSender = Future<dynamic> Function(
  String method,
  Uri uri, {
  dynamic body,
});

class CloudSchedulerRepository {
  CloudSchedulerRepository({
    MobileAuthService? auth,
    CloudSchedulerSender? sender,
  })  : _auth = auth ?? MobileAuthService(),
        _sender = sender;

  final MobileAuthService _auth;
  final CloudSchedulerSender? _sender;

  Future<List<SchedulerTask>> listTasks({
    DateTime? from,
    DateTime? to,
    String? status,
    String? producer,
    String? query,
  }) async {
    final queryParams = <String, String>{};
    if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
    if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (producer != null && producer.isNotEmpty) queryParams['producer'] = producer;
    if (query != null && query.trim().isNotEmpty) queryParams['query'] = query.trim();

    final uri = Uri.parse('${_auth.baseUrl}/api/scheduler-records').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await _request('GET', uri);
    if (response is! List) return const [];

    return response
        .whereType<Map<String, dynamic>>()
        .map(SchedulerTask.fromCloudJson)
        .toList();
  }

  Future<SchedulerTask> publishTask(SchedulerTask task) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/scheduler-records');
    final body = {
      'title': task.title.trim(),
      'type': task.type.name,
      'category': task.category.name,
      'priority': task.priority.name,
      'scheduledAt': task.scheduledAt.toUtc().toIso8601String(),
      'nextReminderAt': task.nextReminderAt?.toUtc().toIso8601String(),
      'deadlineAt': task.deadlineAt?.toUtc().toIso8601String(),
      'notes': task.notes?.trim(),
      'linkedCustomerId': task.cloudLinkedCustomerId,
      'linkedOrderId': task.cloudLinkedOrderId,
      'assignedStaffId': task.cloudAssignedStaffId,
      'producer': task.producer.name,
      'sourceRef': task.sourceRef ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      'requiresConfirmation': task.requiresConfirmation,
      'requiresAlarm': task.requiresAlarm,
    };

    final response = await _request('POST', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to publish cloud scheduler task');
    }
    return SchedulerTask.fromCloudJson(response);
  }

  Future<SchedulerTask> updateTask(String cloudId, SchedulerTask task) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/scheduler-records/$cloudId');
    final body = {
      'title': task.title.trim(),
      'type': task.type.name,
      'category': task.category.name,
      'priority': task.priority.name,
      'scheduledAt': task.scheduledAt.toUtc().toIso8601String(),
      'nextReminderAt': task.nextReminderAt?.toUtc().toIso8601String(),
      'deadlineAt': task.deadlineAt?.toUtc().toIso8601String(),
      'notes': task.notes?.trim(),
      'linkedCustomerId': task.cloudLinkedCustomerId,
      'linkedOrderId': task.cloudLinkedOrderId,
      'assignedStaffId': task.cloudAssignedStaffId,
      'producer': task.producer.name,
      'sourceRef': task.sourceRef ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      'requiresConfirmation': task.requiresConfirmation,
      'requiresAlarm': task.requiresAlarm,
    };

    final response = await _request('PUT', uri, body: body);
    if (response is! Map<String, dynamic>) {
      throw StateError('Failed to update cloud scheduler task');
    }
    return SchedulerTask.fromCloudJson(response);
  }

  Future<void> setStatus(String cloudId, TaskStatus status) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/scheduler-records/$cloudId/status');
    final body = {'status': status.name};
    await _request('PUT', uri, body: body);
  }

  Future<void> deleteTask(String cloudId) async {
    final uri = Uri.parse('${_auth.baseUrl}/api/scheduler-records/$cloudId');
    await _request('DELETE', uri);
  }

  Future<List<SchedulerTask>> getOperationalQueue({
    required DateTime selectedDate,
    String searchQuery = '',
  }) async {
    final from = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final to = from.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final tasks = await listTasks(from: from, to: to, query: searchQuery);
    return tasks.where((t) => t.status != TaskStatus.cancelled).toList();
  }

  Future<List<SchedulerTask>> getTodayScheduledTasks(DateTime date) async {
    final from = DateTime(date.year, date.month, date.day);
    final to = from.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return listTasks(from: from, to: to);
  }

  Future<SchedulerTodaySummary> getTodaySummary() async {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final tasks = await listTasks(from: from, to: to);

    var pending = 0;
    var completed = 0;
    var overdue = 0;
    var urgent = 0;
    var deliveries = 0;
    var pickups = 0;

    for (final task in tasks) {
      if (task.status == TaskStatus.completed) {
        completed++;
      } else if (task.status == TaskStatus.pending || task.status == TaskStatus.inProgress) {
        pending++;
        if (task.isOverdue) overdue++;
        if (task.priority == TaskPriority.urgent) urgent++;
      }

      if (task.type == TaskType.delivery) deliveries++;
      if (task.type == TaskType.pickup) pickups++;
    }

    return SchedulerTodaySummary(
      pending: pending,
      completed: completed,
      overdue: overdue,
      urgent: urgent,
      todayDeliveries: deliveries,
      todayPickups: pickups,
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
