import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ApiService _apiService = ApiService();
  // NotificationService singleton olduğu için bu şekilde de kullanabilirsin
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    final todos = await _apiService.getTodos();
    if (todos != null && mounted) {
      setState(() {
        _todos = todos;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Görev Hatırlatıcı (JWT)"),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadTodos)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? Center(child: Text("Henüz görev yok veya yükleniyor..."))
              : ListView.builder(
                  itemCount: _todos.length,
                  itemBuilder: (context, index) {
                    final todo = _todos[index];
                    return ListTile(
                      leading: Icon(Icons.today, color: Colors.blueAccent),
                      title: Text(todo['title'] ?? "Başlıksız Görev"),
                      subtitle: Text("Durum: ${todo['status'] ?? 'Bekliyor'}"),
                      trailing: IconButton(
                        icon: Icon(Icons.alarm_add, color: Colors.orange),
                        onPressed: () async {
                          // Dinamik Hatırlatıcı: 10 saniye sonra çalacak
                          // Gerçek projede buradan bir TimePicker da açabilirsin
                          final scheduledTime =
                              DateTime.now().add(Duration(seconds: 10));

                          await NotificationService.scheduleNotification(
                            id: todo['id'].hashCode,
                            title: "🔔 Görev Zamanı Geldi!",
                            body: "Unutma: ${todo['title']}",
                            scheduledDate: scheduledTime,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Bildirim 10 saniye sonrasına kuruldu! 🚀"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
