import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../services/notification_service.dart';

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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  // EKLEME: İşlem sırasında butonu pasif yapmak için
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
                  value:
                      _selectedPriority, // Hata düzeltildi: initialValue yerine value kullanıldı.
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
                          // EKLEME: Yükleniyorsa butonu kapat
                          if (_formKey.currentState!.validate()) {
                            setState(() => _isLoading = true); // İşlem başladı

                            final todoProvider = Provider.of<TodoProvider>(
                                context,
                                listen: false);
                            final title = _titleController.text;
                            final desc = _descriptionController.text;

                            // --- ÖNEMLİ: Tarih ve Saati Birleştir ---
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

                            // 1. Görevi Backend'e Kaydet (Provider içinde JWT Token kullanılmalı)
                            final success = await todoProvider.addTodo(
                              title,
                              desc,
                              _selectedPriority,
                              reminderDateTime, // Backend'e tarih nesnesi olarak gönderiyoruz
                            );

                            if (!mounted) return;

                            // 2. Başarılıysa Bildirimi Planla
                            if (success && reminderDateTime != null) {
                              if (reminderDateTime.isAfter(DateTime.now())) {
                                await NotificationService()
                                    .scheduleNotification(
                                  title.hashCode, // Benzersiz ID
                                  "Görev Hatırlatıcı 🔔",
                                  title,
                                  reminderDateTime,
                                );
                              }
                            }

                            // 3. Ekranı kapat
                            if (success) {
                              if (!mounted) return;
                              Navigator.pop(context);
                            } else {
                              setState(() => _isLoading =
                                  false); // Hata varsa butonu geri aç
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Kayıt başarısız. Lütfen tekrar deneyin.')));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading
                      ? const CircularProgressIndicator()
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
