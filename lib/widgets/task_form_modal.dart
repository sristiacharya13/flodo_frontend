import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskFormModal extends StatefulWidget {
  final Task? task;

  const TaskFormModal({super.key, this.task});

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _status = 'To-Do';
  int? _blockedById;
  bool _isRecurring = false;
  String? _recurringType;
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _dueDate = widget.task!.dueDate;
      _status = widget.task!.status;
      _blockedById = widget.task!.blockedById;
      _isRecurring = widget.task!.isRecurring;
      _recurringType = widget.task!.recurringType;
    } else {
      _loadDrafts();
      _titleController.addListener(_saveDrafts);
      _descriptionController.addListener(_saveDrafts);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleController.text = prefs.getString('draft_title') ?? '';
      _descriptionController.text = prefs.getString('draft_description') ?? '';
    });
  }

  void _saveDrafts() {
    if (widget.task != null) return;
    
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_title', _titleController.text);
      await prefs.setString('draft_description', _descriptionController.text);
    });
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final taskData = Task(
      id: widget.task?.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueDate: _dueDate,
      status: _status,
      blockedById: _blockedById,
      position: widget.task?.position ?? 0,
      isRecurring: _isRecurring,
      recurringType: _recurringType,
    );

    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      
      if (widget.task == null) {
        await provider.createTask(taskData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('draft_title');
        await prefs.remove('draft_description');
      } else {
        await provider.updateTask(taskData);
      }
      
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get all tasks to populate the "Blocked By" dropdown
    final allTasks = Provider.of<TaskProvider>(context).tasks;
    
    // Filter out the current task so it can't block itself
    final potentialBlockers = allTasks.where((t) => t.id != widget.task?.id).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.task == null ? 'Create New Task' : 'Edit Task',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Due Date: ${_dueDate.toLocal().toString().split(' ')[0]}'),
                    ),
                    TextButton(
                      onPressed: () => _selectDueDate(context),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'To-Do', child: Text('To-Do')),
                    DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'Done', child: Text('Done')),
                  ],
                  onChanged: (value) => setState(() => _status = value!),
                ),
                const SizedBox(height: 16),
                
                // UPDATED: Blocked By Dropdown (Task Titles instead of IDs)
                DropdownButtonFormField<int?>(
                  value: _blockedById,
                  decoration: const InputDecoration(
                    labelText: 'Blocked By Task',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None (No Dependency)'),
                    ),
                    ...potentialBlockers.map((t) => DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text(t.title, overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (value) => setState(() => _blockedById = value),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Recurring:'),
                    Switch(
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                          if (!value) _recurringType = null;
                        });
                      },
                    ),
                  ],
                ),
                if (_isRecurring)
                  DropdownButtonFormField<String>(
                    value: _recurringType,
                    decoration: const InputDecoration(
                      labelText: 'Recurring Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                    ],
                    onChanged: (value) => setState(() => _recurringType = value),
                    validator: (value) => (_isRecurring && value == null) ? 'Recurring type is required' : null,
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveTask,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}