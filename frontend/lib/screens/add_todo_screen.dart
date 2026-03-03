import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/todo_controller.dart';
import '../services/notification_service.dart';
import '../models/todo.dart';

class AddTodoScreen extends StatefulWidget {
  final Todo? todo;
  final DateTime? initialDate;

  const AddTodoScreen({super.key, this.todo, this.initialDate});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _setReminder = true;

  // GetX controller
  final TodoController _todoController = Get.find<TodoController>();

  // isLoading artık GetX ile yönetiliyor
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? "");
    _descriptionController =
        TextEditingController(text: widget.todo?.description ?? "");
    _selectedPriority = widget.todo?.priority ?? 'medium';
    _selectedDate =
        widget.todo?.dueDate ?? widget.initialDate ?? DateTime.now();

    if (widget.todo?.dueDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.todo!.dueDate!);
    } else {
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (_selectedDate != null && _selectedDate!.isAfter(today))
          ? _selectedDate!
          : today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;

    final dateToUse = _selectedDate ?? DateTime.now();
    final timeToUse = _selectedTime ?? TimeOfDay.now();
    final reminderDateTime = DateTime(
      dateToUse.year,
      dateToUse.month,
      dateToUse.day,
      timeToUse.hour,
      timeToUse.minute,
    );

    bool success;
    final isEditing = widget.todo != null;

    if (isEditing) {
      success = await _todoController.updateTodo(
        widget.todo!.id,
        _titleController.text,
        _descriptionController.text,
        _selectedPriority,
        reminderDateTime,
      );
    } else {
      success = await _todoController.addTodo(
        _titleController.text,
        _descriptionController.text,
        _selectedPriority,
        reminderDateTime,
      );
    }

    if (success) {
      if (_setReminder) {
        await NotificationService.scheduleNotification(
          id: widget.todo?.id.hashCode ?? DateTime.now().millisecond,
          title: "🔔 Görev: ${_titleController.text}",
          body: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : "Görev vakti geldi!",
          scheduledDate: reminderDateTime,
        );
      }
      Get.back(); // ← Navigator.pop yerine
    } else {
      _isLoading.value = false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDateOnly = _selectedDate != null
          ? DateTime(
              _selectedDate!.year, _selectedDate!.month, _selectedDate!.day)
          : null;

      String errorMessage = 'İşlem başarısız!';
      if (selectedDateOnly != null && selectedDateOnly.isBefore(today)) {
        errorMessage = 'Geçmiş bir tarihe görev ekleyemezsiniz! 🛑';
      }

      // ← ScaffoldMessenger yerine Get.snackbar
      Get.snackbar(
        'Hata',
        errorMessage,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Todo' : 'Add New Todo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Title', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                      labelText: 'Priority', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (val) => setState(() => _selectedPriority = val!),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Due Date', border: OutlineInputBorder()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedDate == null
                            ? 'No due date'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Reminder Time',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(_selectedTime == null
                        ? 'No time set'
                        : _selectedTime!.format(context)),
                  ),
                ),
                SwitchListTile(
                  title: const Text("Set Notification Alarm"),
                  subtitle: const Text("Receive a reminder at selected time"),
                  value: _setReminder,
                  onChanged: (val) => setState(() => _setReminder = val),
                  secondary: const Icon(Icons.notifications_active,
                      color: Colors.amber),
                ),
                const SizedBox(height: 24),

                // Obx ile isLoading değişince otomatik güncellenir
                Obx(() => ElevatedButton(
                      onPressed: _isLoading.value ? null : _submit,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: _isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(isEditing
                              ? 'Update Todo'
                              : 'Add Todo & Reminder'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
