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
  Future<void> createTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      await _apiService.createTask(task);
      await fetchTasks();
    } catch (e) {
      debugPrint("Error creating task: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleRecurring(Task task) async {
    final newDueDate = task.recurringType == 'Daily' ? task.dueDate.add(const Duration(days: 1)) : task.dueDate.add(const Duration(days: 7));
    final newTask = Task(
      id: 0,
      title: task.title,
      description: task.description,
      dueDate: newDueDate,
      status: 'To-Do',
      blockedById: task.blockedById,
      position: _tasks.length,
      isRecurring: true,
      recurringType: task.recurringType,
    );
    await createTask(newTask);
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
        if (_tasks[index].isRecurring && status == 'Done') {
          await handleRecurring(_tasks[index]);
        }
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
  Future<void> updateTask(Task task) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.updateTask(task);
      await fetchTasks();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> deleteTask(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}