import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzData.initializeTimeZones();

    // 🌍 Cihazın yerel zaman dilimini ayarla
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
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
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Bildirime tıklandı: ${details.payload}");
      },
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Android 13+ için bildirim izni
      await androidPlugin.requestNotificationsPermission();
      // Android 12+ için tam zamanlı alarm izni
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // 🚀 TEST İÇİN ANLIK BİLDİRİM (Bunu çağırınca hemen gelmeli)
  Future<void> showInstantNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_test_channel',
      'Test Bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  // NotificationService sınıfının içine ekle
  Future<void> showImmediateTest() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'immediate_test_channel',
      'Test Kanali',
      importance: Importance.max,
      priority: Priority.high,
    );
    await flutterLocalNotificationsPlugin.show(
        12345,
        "Anlık Test",
        "Bu bildirimi görüyorsan izinler TAMAM demektir!",
        const NotificationDetails(android: androidDetails));
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Eğer zaman geçtiyse kurma
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Hata: Geçmiş bir zamana bildirim kurulamaz.");
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders_v4', // ID'yi her seferinde değiştirmek yeni kanal açar
          'Görev Hatırlatıcılar',
          channelDescription: 'Görevleriniz için hatırlatmalar',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint("✅ Bildirim Planlandı: $tzDate");
  }
}
