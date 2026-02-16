import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';
import 'package:weekly_date_picker/weekly_date_picker.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'medium';
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now(), // Takvimden seçilen günden başlasın
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate =
            picked; // Alttan seçilince üstteki WeeklyDatePicker da güncellenir
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Todo')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // Hafif bir arka plan rengi
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: WeeklyDatePicker(
                    selectedDay: _selectedDate ?? DateTime.now(),
                    changeDay: (value) => setState(() {
                      _selectedDate = value;
                    }),
                    selectedDigitBackgroundColor:
                        Theme.of(context).primaryColor,
                    digitsColor: Colors.black,
                  ),
                ),
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

                            // JWT yetkilendirmesi ile backend'e gönderiyoruz.
                            final success = await todoProvider.addTodo(
                              _titleController.text,
                              _descriptionController.text,
                              _selectedPriority,
                              reminderDateTime,
                            );

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
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Kayıt başarısız!')));
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
                      : const Text('Add Todo & Reminder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
