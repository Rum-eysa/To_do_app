import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';
import '../models/todo.dart';

class AddTodoScreen extends StatefulWidget {
  final Todo? todo;
  const AddTodoScreen({super.key, this.todo});

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? "");
    _descriptionController =
        TextEditingController(text: widget.todo?.description ?? "");
    _selectedPriority = widget.todo?.priority ?? 'medium';
    _selectedDate = widget.todo?.dueDate ?? DateTime.now();

    if (widget.todo?.dueDate != null) {
      _selectedTime = TimeOfDay.fromDateTime(widget.todo!.dueDate!);
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
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true);

                            final todoProvider = Provider.of<TodoProvider>(
                                context,
                                listen: false);

                            DateTime? reminderDateTime;
                            if (_selectedDate != null &&
                                _selectedTime != null) {
                              reminderDateTime = DateTime(
                                _selectedDate!.year,
                                _selectedDate!.month,
                                _selectedDate!.day,
                                _selectedTime!.hour,
                                _selectedTime!.minute,
                              );
                            }

                            bool success;
                            if (isEditing) {
                              success = await todoProvider.updateTodo(
                                widget.todo!.id,
                                _titleController.text,
                                _descriptionController.text,
                                _selectedPriority,
                                reminderDateTime,
                              );
                            } else {
                              success = await todoProvider.addTodo(
                                _titleController.text,
                                _descriptionController.text,
                                _selectedPriority,
                                reminderDateTime,
                              );
                            }

                            if (!mounted) return;

                            if (success && reminderDateTime != null) {
                              if (reminderDateTime.isAfter(DateTime.now())) {
                                await NotificationService()
                                    .scheduleNotification(
                                  _titleController.text.hashCode,
                                  "Görev Hatırlatıcı 🔔",
                                  _titleController.text,
                                  reminderDateTime,
                                );
                              }
                            }

                            if (success) {
                              Navigator.pop(context);
                            } else {
                              setState(() => _isLoading = false);

                              // --- EKLEME: GEÇMİŞ TARİH VE HATA KONTROLÜ ---
                              final now = DateTime.now();
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final selectedDateOnly = _selectedDate != null
                                  ? DateTime(_selectedDate!.year,
                                      _selectedDate!.month, _selectedDate!.day)
                                  : null;

                              String errorMessage = 'İşlem başarısız!';

                              if (selectedDateOnly != null &&
                                  selectedDateOnly.isBefore(today)) {
                                errorMessage =
                                    'Geçmiş bir tarihe görev ekleyemezsiniz! 🛑';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(isEditing ? 'Update Todo' : 'Add Todo & Reminder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
