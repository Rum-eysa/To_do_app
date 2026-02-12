import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import 'add_todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TodoProvider>(context, listen: false).fetchTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: todoProvider.setFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all', 
                child: Row(children: [Icon(Icons.list), SizedBox(width: 8), Text('All')])
              ),
              const PopupMenuItem(
                value: 'active', 
                child: Row(children: [Icon(Icons.pending), SizedBox(width: 8), Text('Active')])
              ),
              const PopupMenuItem(
                value: 'completed', 
                child: Row(children: [Icon(Icons.check_circle), SizedBox(width: 8), Text('Completed')])
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: todoProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : todoProvider.todos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No todos yet', 
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600]
                        )
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first todo!', 
                        style: TextStyle(color: Colors.grey[500])
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: todoProvider.todos.length,
                  itemBuilder: (context, index) {
                    final todo = todoProvider.todos[index];
                    return TodoItem(
                      todo: todo,
                      onToggle: () => todoProvider.toggleTodo(todo.id),
                      onDelete: () => todoProvider.deleteTodo(todo.id),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTodoScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
    );
  }
}
