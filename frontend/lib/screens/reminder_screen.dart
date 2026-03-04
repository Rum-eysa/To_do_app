import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/todo_controller.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TodoController todoController = Get.find<TodoController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görev Hatırlatıcılar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => todoController.fetchTodos(),
          ),
        ],
      ),
      body: Obx(() {
        if (todoController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = todoController.todos;

        if (todos.isEmpty) {
          return const Center(child: Text('Henüz görev yok.'));
        }

        return ListView.builder(
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todo = todos[index];
            return ListTile(
              leading: const Icon(Icons.today, color: Colors.blueAccent),
              title: Text(todo.title),
              subtitle: Text(todo.completed ? 'Tamamlandı' : 'Bekliyor'),
              trailing: IconButton(
                icon: const Icon(Icons.alarm_add, color: Colors.orange),
                onPressed: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {
                    final now = DateTime.now();
                    var scheduledDate = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );

                    if (scheduledDate.isBefore(now)) {
                      scheduledDate =
                          scheduledDate.add(const Duration(days: 1));
                    }

                    await NotificationService.scheduleNotification(
                      id: todo.id.hashCode,
                      title: '🔔 Görev Zamanı Geldi!',
                      body: 'Unutma: ${todo.title}',
                      scheduledDate: scheduledDate,
                    );

                    Get.snackbar(
                      'Bildirim Kuruldu',
                      '${todo.title} için hatırlatıcı kuruldu!',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }
}
