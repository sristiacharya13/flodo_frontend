import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _selectedStatus = '';
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final List<String> _statuses = ['All', 'To-Do', 'In Progress', 'Done'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      provider.fetchTasks(search: _searchController.text, status: _selectedStatus.isEmpty ? null : _selectedStatus);
    });
  }

  void _onStatusChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedStatus = index == 0 ? '' : _statuses[index];
    });
    final provider = Provider.of<TaskProvider>(context, listen: false);
    provider.fetchTasks(search: _searchController.text, status: _selectedStatus.isEmpty ? null : _selectedStatus);
  }

  void _showTaskFormModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TaskFormModal(),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = provider.tasks;
    if (newIndex > oldIndex) newIndex -= 1;
    final task = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, task);

    // Update positions
    final positions = tasks.asMap().entries.map((e) => {'id': e.value.id, 'position': e.key}).toList();
    provider.reorderTasks(positions);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 180,
            backgroundColor: Colors.blue,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(180),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text(
                      'Flodo Tasks',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: List.generate(_statuses.length, (index) => index == _selectedIndex),
                      onPressed: _onStatusChanged,
                      children: _statuses.map((status) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(status),
                      )).toList(),
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.white,
                      fillColor: Colors.blueAccent,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: provider.isLoading && provider.tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink(),
          ),
          SliverReorderableList(
            itemCount: provider.tasks.length,
            itemBuilder: (context, index) {
              final task = provider.tasks[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(task.id),
                index: index,
                child: TaskCard(
                  task: task,
                  searchQuery: _searchController.text,
                  onStatusUpdate: (status) async {
                    HapticFeedback.lightImpact();
                    try {
                      await provider.updateStatus(task.id, status);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              );
            },
            onReorder: _onReorder,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskFormModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}