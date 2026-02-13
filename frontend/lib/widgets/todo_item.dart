import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoItem(
      {super.key,
      required this.todo,
      required this.onToggle,
      required this.onDelete});

  Color _getPriorityColor() {
    switch (todo.priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(value: todo.completed, onChanged: (_) => onToggle()),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  todo.description,
                  style: TextStyle(
                      decoration:
                          todo.completed ? TextDecoration.lineThrough : null,
                      color: todo.completed ? Colors.grey : null),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (todo.dueDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('//',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: _getPriorityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(todo.priority.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor())),
            ),
            // TodoItem içindeki build metodunda:
            IconButton(
              icon: const Icon(Icons.alarm_add, color: Colors.blue),
              onPressed: () async {
                // 1. Saat Seçiciyi Aç
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (pickedTime != null) {
                  final now = DateTime.now();
                  final scheduledDate = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  // Eğer seçilen saat geçmişse yarına kur
                  var finalDate = scheduledDate;
                  if (scheduledDate.isBefore(now)) {
                    finalDate = scheduledDate.add(const Duration(days: 1));
                  }

                  // 2. Bildirimi Planla
                  await NotificationService().scheduleNotification(
                    todo.id
                        .hashCode, // Benzersiz ID (todo.id String ise hashCode kullan)
                    "Görev Zamanı! 🔔",
                    todo.title,
                    finalDate,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Bildirim kuruldu: ${pickedTime.format(context)}")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
