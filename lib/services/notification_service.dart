import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/models.dart';

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();
  static const messages = [
    'Un sorbo de agua ahora, gracias después.',
    'Tu cuerpo te lo va a agradecer. ¿Agua?',
    'Pausa breve: hidrátate con agua.',
    'El siguiente sorbo también cuenta.',
    'Tu ola sigue creciendo, ¡ánimo!',
    'Respira y toma un sorbo de agua.',
    'Hidratarte también es cuidarte.',
    'Un pequeño sorbo hace gran diferencia.',
    '¿Sed? Tu agua te está esperando.',
    'Agua lista: regálate un sorbo.',
    'Tu yo de la tarde agradecerá esta agua.',
    'Un sorbo y vuelves con más energía.',
    'Hidratación desbloqueada: toma agua.',
    'Tu recordatorio favorito: agua fresca.',
    'Sorbito pequeño, día más fluido.',
    'Haz una pausa azul: toma agua.',
    '¿Brindamos? Por ti y por tu agua.',
    'El agua también cuenta como autocuidado.',
    'Misión del momento: un sorbo.',
    'Tu ola pide un poquito de agua.',
    'Agua en mano, ¡seguimos!',
    'Un sorbo ahora mantiene el ritmo.',
    'La constancia empieza con agua.',
    'Toma agua antes de volver a lo tuyo.',
    'Tu cuerpo trabaja mejor hidratado.',
    'Un chorrito de agua para continuar.',
    'Pequeño recordatorio, gran hábito.',
    'Dale a tu día un sorbo de agua.',
    '¡Vamos! Suma otro sorbo a tu ola.',
    'Agua, pausa y a seguir.',
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception {
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await plugin.initialize(const InitializationSettings(android: android, iOS: ios));
  }

  Future<void> requestPermissions() async {
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    await plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true);
  }

  Future<void> schedule(ReminderSettings settings, {bool pause = false}) async {
    try {
      await _schedule(settings, pause: pause);
    } on Exception catch (e) {
      debugPrint('HydraFlow: no se pudieron programar recordatorios: $e');
    }
  }

  Future<void> _schedule(ReminderSettings settings, {required bool pause}) async {
    await plugin.cancelAll();
    if (!settings.enabled || pause) return;
    final now = tz.TZDateTime.now(tz.local);
    var count = 0;
    for (var day = 0; day < 2 && count < 64; day++) {
      var at = tz.TZDateTime(tz.local, now.year, now.month, now.day + day, settings.wakeHour, settings.wakeMinute);
      final end = tz.TZDateTime(tz.local, now.year, now.month, now.day + day, settings.sleepHour, settings.sleepMinute);
      final adjustedEnd = end.isAfter(at) ? end : end.add(const Duration(days: 1));
      while (at.isBefore(adjustedEnd) && count < 64) {
        if (at.isAfter(now)) {
          await plugin.zonedSchedule(
            1000 + count, 'HydraFlow', messages[(count + now.day * 7) % messages.length],
            at, _details(settings.sound),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          count++;
        }
        at = at.add(Duration(minutes: settings.intervalMinutes));
      }
    }
  }

  NotificationDetails detailsFor(String sound) => _details(sound);

  Future<void> sendTest(String sound) => plugin.show(
        9999,
        'HydraFlow',
        'Esta es una notificación de prueba. ¡Un sorbo cuando quieras!',
        _details(sound),
      );

  NotificationDetails _details(String sound) => NotificationDetails(
    android: AndroidNotificationDetails(
      'hydraflow_$sound', 'HydraFlow · $sound',
      channelDescription: 'Recordatorios de hidratación', importance: Importance.high,
      priority: Priority.high,
      playSound: sound != 'ninguno',
      sound: sound == 'ninguno' ? null : RawResourceAndroidNotificationSound(sound),
    ),
    iOS: DarwinNotificationDetails(sound: sound == 'ninguno' ? null : '$sound.caf'),
  );
}
