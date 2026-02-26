import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import '../controllers/auth_controller.dart';
import '../controllers/todo_controller.dart';
import '../widgets/todo_item.dart';
import 'add_todo_screen.dart';
import '../models/todo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = "";
  bool _isSearching = false;
  int _sortStatus = 0;

  // GetX controllers
  final AuthController _authController = Get.find<AuthController>();
  final TodoController _todoController = Get.find<TodoController>();

  @override
  void initState() {
    super.initState();
    _todoController.fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isPastDate = _selectedDate.isBefore(today);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in tasks...',
                  border: InputBorder.none,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('My Todos',
                style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = "";
              });
            },
          ),
          IconButton(
            icon: Icon(_sortStatus == 1
                ? Icons.keyboard_double_arrow_down
                : _sortStatus == 2
                    ? Icons.keyboard_double_arrow_up
                    : Icons.sort),
            onPressed: () =>
                setState(() => _sortStatus = (_sortStatus + 1) % 3),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _todoController.setFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'all',
                  child: Row(children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('All')
                  ])),
              const PopupMenuItem(
                  value: 'active',
                  child: Row(children: [
                    Icon(Icons.pending),
                    SizedBox(width: 8),
                    Text('Active')
                  ])),
              const PopupMenuItem(
                  value: 'completed',
                  child: Row(children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Completed')
                  ])),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        // Obx ile todos otomatik güncellenir
        List<Todo> filteredTodos = _todoController.todos.where((todo) {
          if (_isSearching && _searchQuery.isNotEmpty) {
            return todo.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          } else {
            if (todo.dueDate == null) return false;
            return todo.dueDate!.year == _selectedDate.year &&
                todo.dueDate!.month == _selectedDate.month &&
                todo.dueDate!.day == _selectedDate.day;
          }
        }).toList();

        final priorityWeight = {'high': 3, 'medium': 2, 'low': 1};
        if (_sortStatus == 1) {
          filteredTodos.sort((a, b) => priorityWeight[b.priority]!
              .compareTo(priorityWeight[a.priority]!));
        } else if (_sortStatus == 2) {
          filteredTodos.sort((a, b) => priorityWeight[a.priority]!
              .compareTo(priorityWeight[b.priority]!));
        }

        return Column(
          children: [
            if (!_isSearching)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: EasyDateTimeLine(
                  initialDate: _selectedDate,
                  onDateChange: (selectedDate) {
                    setState(() => _selectedDate = selectedDate);
                  },
                  headerProps: const EasyHeaderProps(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    monthPickerType: MonthPickerType.switcher,
                    dateFormatter: DateFormatter.fullDateMonthAsStrDY(),
                  ),
                  dayProps: EasyDayProps(
                    height: 65.0,
                    width: 58.0,
                    dayStructure: DayStructure.dayStrDayNum,
                    activeDayStyle: DayStyle(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).primaryColor,
                      ),
                      dayNumStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      dayStrStyle:
                          const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    inactiveDayStyle: const DayStyle(
                      dayNumStyle: TextStyle(fontSize: 15),
                      dayStrStyle: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            if (!_isSearching)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildStatCard("Total", filteredTodos.length, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        "Done",
                        filteredTodos.where((t) => t.completed).length,
                        Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        "Pending",
                        filteredTodos.where((t) => !t.completed).length,
                        Colors.orange),
                  ],
                ),
              ),
            if (!_isSearching) const Divider(indent: 20, endIndent: 20),
            Expanded(
              child: _todoController.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTodos.isEmpty
                      ? _buildEmptyState(_isSearching)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = filteredTodos[index];
                            return Dismissible(
                              key: Key(todo.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await Get.dialog<bool>(
                                  AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15)),
                                    title: const Text("Görevi Sil"),
                                    content: const Text(
                                        "Bu görevi silmek istediğinizden emin misiniz?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Get.back(result: false),
                                        child: const Text("İPTAL"),
                                      ),
                                      TextButton(
                                        onPressed: () => Get.back(result: true),
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent),
                                        child: const Text("SİL"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                _todoController.deleteTodo(todo.id);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: InkWell(
                                  onTap: () => Get.to(
                                    () => AddTodoScreen(todo: todo),
                                  ),
                                  child: TodoItem(
                                    todo: todo,
                                    onToggle: () =>
                                        _todoController.toggleTodo(todo.id),
                                    onDelete: () async {
                                      final confirm = await Get.dialog<bool>(
                                        AlertDialog(
                                          title: const Text("Sil"),
                                          content: const Text(
                                              "Bu görevi silmek istiyor musunuz?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Get.back(result: false),
                                                child: const Text("HAYIR")),
                                            TextButton(
                                                onPressed: () =>
                                                    Get.back(result: true),
                                                child: const Text("EVET")),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _todoController.deleteTodo(todo.id);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      }),
      floatingActionButton: isPastDate
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Get.to(
                () => AddTodoScreen(initialDate: _selectedDate),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Todo'),
            ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearching ? Icons.search_off : Icons.task_alt,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(isSearching ? 'No results found' : 'No todos for this day',
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
