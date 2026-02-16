import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
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
  DateTime _selectedDate = DateTime.now();
  // --- ARAMA İÇİN EKLENEN DEĞİŞKENLER ---
  String _searchQuery = "";
  bool _isSearching = false;

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

    // --- SADECE SÖYLEDİĞİN ŞEKİLDE GÜNCELLENEN FİLTRELEME ---
    final filteredTodos = todoProvider.todos.where((todo) {
      if (_isSearching && _searchQuery.isNotEmpty) {
        // Arama yapılıyorsa: Sadece kelime eşleşmesine bak (tarihi boşver)
        return todo.title.toLowerCase().contains(_searchQuery.toLowerCase());
      } else {
        // Arama yapılmıyorsa: Senin orijinal tarih filtren
        if (todo.dueDate == null) return false;
        return todo.dueDate!.year == _selectedDate.year &&
            todo.dueDate!.month == _selectedDate.month &&
            todo.dueDate!.day == _selectedDate.day;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        // --- ARAMA ÇUBUĞU EKLEMESİ ---
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
          // --- ARAMA BUTONU ---
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = "";
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: todoProvider.setFilter,
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
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama yaparken takvimi gizlemek daha iyi bir deneyim sunar
          if (!_isSearching)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: EasyDateTimeLine(
                initialDate: _selectedDate,
                onDateChange: (selectedDate) {
                  setState(() {
                    _selectedDate = selectedDate;
                  });
                },
                headerProps: const EasyHeaderProps(
                  monthPickerType: MonthPickerType.switcher,
                  dateFormatter: DateFormatter.fullDateMonthAsStrDY(),
                ),
                dayProps: EasyDayProps(
                  dayStructure: DayStructure.dayStrDayNum,
                  activeDayStyle: DayStyle(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).primaryColor,
                    ),
                    dayNumStyle: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    dayStrStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          if (!_isSearching) const Divider(indent: 20, endIndent: 20),
          Expanded(
            child: todoProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTodos.isEmpty
                    ? _buildEmptyState(
                        _isSearching) // Arama durumunu gönderiyoruz
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTodos.length,
                        itemBuilder: (context, index) {
                          final todo = filteredTodos[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              // --- TIKLAYINCA DÜZENLEME İÇİN NAVIGASYON ---
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          AddTodoScreen(todo: todo)),
                                );
                              },
                              child: TodoItem(
                                todo: todo,
                                onToggle: () =>
                                    todoProvider.toggleTodo(todo.id),
                                onDelete: () =>
                                    todoProvider.deleteTodo(todo.id),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
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

  // --- BOŞ DURUM MESAJINI ARAMAYA GÖRE GÜNCELLEDİK ---
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
