import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // Backend'den (JWT ile) görevleri çekiyoruz
  Future<void> _loadTodos() async {
    final todos = await _apiService.getTodos();
    if (todos != null) {
      setState(() {
        _todos = todos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Görev Hatırlatıcı (JWT)")),
      body: _todos.isEmpty
          ? Center(child: Text("Henüz görev yok veya yükleniyor..."))
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return ListTile(
                  title: Text(todo['title']),
                  subtitle: Text("ID: ${todo['id']}"),
                  trailing: IconButton(
                    icon: Icon(Icons.alarm_add, color: Colors.blue),
                    onPressed: () {
                      // Örnek: 10 saniye sonrasına hatırlatıcı kur
                      _notificationService.scheduleNotification(
                        todo['id'].hashCode,
                        "Görev Zamanı!",
                        todo['title'],
                        DateTime.now().add(Duration(seconds: 10)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "10 saniye sonrasına hatılatıcı kuruldu!")),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
