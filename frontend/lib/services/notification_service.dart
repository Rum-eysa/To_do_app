import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    try {
      final String timeZoneName =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("Timezone hatası: $e");
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Bildirime tıklandı: ${details.payload}");
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // --- METOD ADI DÜZELTİLDİ ---
  // Statik yaparak AddTodoScreen içinden kolayca çağrılmasını sağlıyoruz
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Geçmiş tarihe bildirim kurma
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await NotificationService().flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'todo_reminders',
              'Görev Hatırlatıcılar',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
  }

  // Anlık test bildirimi
  Future<void> showInstantNotification(String title, String body) async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
