import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String title;
  final String description;
  bool completed;
  final String priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isSynced; // <--- HİBRİT YAPI İÇİN KRİTİK: Bulutla eşitlendi mi?

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false, // Varsayılan olarak false
  });

  // --- 1. FIREBASE'DEN OKUMA ---
  factory Todo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseTime(dynamic field) {
      if (field is Timestamp) return field.toDate();
      if (field is String) return DateTime.parse(field);
      return DateTime.now();
    }

    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      completed: data['completed'] ?? false,
      priority: data['priority'] ?? 'medium',
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      createdAt: parseTime(data['createdAt']),
      updatedAt: parseTime(data['updatedAt']),
      isSynced: true, // Firebase'den geliyorsa zaten senkronize olmuştur
    );
  }

  // --- 2. SQLITE VE JSON'DAN OKUMA ---
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      completed: map['completed'] == 1 || map['completed'] == true,
      priority: map['priority'] ?? 'medium',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      isSynced: (map['isSynced'] == 1 || map['isSynced'] == true),
    );
  }

  // --- 3. FIREBASE'E YAZMA (toJson) ---
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'createdAt': createdAt, // Firebase Timestamp otomatik çevirir
      'updatedAt': FieldValue.serverTimestamp(),
      'isSynced': true,
    };
  }

  // --- 4. SQLITE'A YAZMA (toMap) ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0, // SQLite bool sevmez, 0-1 tutarız
      'priority': priority,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }
}
