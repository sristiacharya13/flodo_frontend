import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flodo_frontend/providers/task_provider.dart'; // Ensure this path matches Kilo's output

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskProvider()..fetchTasks(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flodo Backend Test')),
        body: Consumer<TaskProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                // 1. Test the 2-second Delay & Create
                ElevatedButton(
                  onPressed: provider.isLoading 
                    ? null 
                    : () => provider.addTask("Test Task", "Testing 2s delay"),
                  child: provider.isLoading 
                    ? const Text("Saving... (2s)") 
                    : const Text("Add Task (Test Delay)"),
                ),
                
                const Divider(),
                
                // 2. Display List
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text("Status: ${task.status}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () async {
                            // 3. Test the "BLOCKED" 400 Error logic
                            try {
                              await provider.updateStatus(task.id, "Done");
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')), // Cleans up the text
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}