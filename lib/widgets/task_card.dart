import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'task_form_modal.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final String searchQuery;
  final Function(String) onStatusUpdate;

  const TaskCard({
    super.key,
    required this.task,
    required this.searchQuery,
    required this.onStatusUpdate,
  });

  bool _isBlocked(List<Task> allTasks) {
    if (task.blockedById == null) return false;
    // Using firstWhere with orElse to avoid crashes if a blocker task is missing
    final blocker = allTasks.cast<Task?>().firstWhere(
          (t) => t?.id == task.blockedById,
          orElse: () => null,
        );
    return blocker != null && blocker.status != 'Done';
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);
    if (start == -1) {
      return Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
    }
    final end = start + query.length;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: text.substring(0, start),
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          TextSpan(
              text: text.substring(start, end),
              style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  backgroundColor: Colors.yellow,
                  fontSize: 18)),
          TextSpan(
              text: text.substring(end),
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ],
      ),
    );
  }

  void _showEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TaskFormModal(task: task),
    );
  }

  void _deleteTask(BuildContext context) async {
    // Show confirmation dialog before deleting
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      try {
        await provider.deleteTask(task.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = Provider.of<TaskProvider>(context).tasks;
    final isBlocked = _isBlocked(allTasks);

    return Card(
      elevation: 2,
      color: isBlocked ? Colors.grey[200] : Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          // 1. Status Badge - Positioned at top right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(task.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(task.status), width: 1),
              ),
              child: Text(
                task.status,
                style: TextStyle(
                  color: _getStatusColor(task.status),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 2. Main content area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (Constraints expanded to avoid overlapping status)
                Padding(
                  padding: const EdgeInsets.only(right: 80), 
                  child: _highlightText(task.title, searchQuery),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  task.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Meta Info: Due Date and Blocked status
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    if (task.blockedById != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.lock_outline, size: 14, color: isBlocked ? Colors.red : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        isBlocked ? 'Blocked by #${task.blockedById}' : 'Unblocked',
                        style: TextStyle(
                          fontSize: 12,
                          color: isBlocked ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),

                // 3. Action Buttons - Bottom Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.indigo, size: 22),
                      onPressed: isBlocked ? null : () => _showEditModal(context),
                      tooltip: 'Edit Task',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                      onPressed: () => _deleteTask(context),
                      tooltip: 'Delete Task',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}