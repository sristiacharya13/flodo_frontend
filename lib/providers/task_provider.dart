import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  /// Fetches the latest tasks from the backend
  Future<void> fetchTasks({String? search, String? status}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tasks = await _apiService.getTasks(search: search, status: status);
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new task and then refreshes the entire list from the server
  Future<void> addTask(String title, String description) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newTask = Task(
        id: 0, // Backend will assign the real ID
        title: title,
        description: description,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: 'To-Do',
        position: _tasks.length,
        isRecurring: false,
      );

      // 1. Send the new task to the backend
      await _apiService.createTask(newTask);

      // 2. Refresh the whole list from the server
      // This ensures local state perfectly matches the database
      await fetchTasks();
      
    } catch (e) {
      debugPrint("Error adding task: $e");
      rethrow; // Re-throwing allows the UI to catch and show an error SnackBar
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates status and handles the local state update
  Future<void> updateStatus(int id, String status) async {
    try {
      await _apiService.updateTaskStatus(id, status);
      
      // Update locally to avoid a full fetchTasks() call for a simple status toggle
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index] = Task(
          id: _tasks[index].id,
          title: _tasks[index].title,
          description: _tasks[index].description,
          dueDate: _tasks[index].dueDate,
          status: status,
          blockedById: _tasks[index].blockedById,
          position: _tasks[index].position,
          isRecurring: _tasks[index].isRecurring,
          recurringType: _tasks[index].recurringType,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
      rethrow; // Critical for showing the "Blocked" error message in the UI
    }
  }

  /// Sends the new task order to the backend and refreshes
  Future<void> reorderTasks(List<Map<String, int>> positions) async {
    try {
      await _apiService.reorderTasks(positions);
      // Optional: Refresh tasks to ensure the new positions are locked in
      await fetchTasks();
    } catch (e) {
      debugPrint("Error reordering tasks: $e");
    }
  }
}