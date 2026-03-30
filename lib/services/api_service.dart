import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class ApiService {
  // Ensure this IP matches your current laptop IP on the Wi-Fi network
  static const String baseUrl = 'http://192.168.1.5:8000';

  Future<List<Task>> getTasks({String? search, String? status}) async {
    final Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/tasks/').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: Check if Backend is running at $baseUrl');
    }
  }

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    // FastAPI returns 200 or 201 for successful creation usually
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Failed to create task');
    }
  }

  Future<void> updateTaskStatus(int id, String status) async {
    // Note: Ensure your FastAPI endpoint matches this structure
    final uri = Uri.parse('$baseUrl/tasks/$id/status').replace(
      queryParameters: {'status': status},
    );

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Success - no action needed
      return;
    } else {
      // Logic for handling errors (400, 404, 500)
      try {
        final errorData = json.decode(response.body);
        // This grabs the "detail" string we wrote in FastAPI (e.g., "Task is blocked by...")
        throw Exception(errorData['detail'] ?? 'Failed to update task status');
      } catch (e) {
        throw Exception('Server Error: ${response.statusCode}');
      }
    }
  }

  Future<void> reorderTasks(List<Map<String, int>> positions) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/reorder'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(positions),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tasks');
    }
  }
}