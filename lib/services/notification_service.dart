import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task_model.dart';

// Notification ID ranges:
//   1–9999   → task reminders (ใช้ task.id)
//   10000+   → budget alerts  (walletId + 10000)
//   20000+   → low balance    (walletId + 20000)
//   30000+   → recurring expense

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ─── init ─────────────────────────────────────────────
  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── Task reminder (default: 1 วันก่อน เวลา 09:00) ───
  Future<void> scheduleTaskReminder(TaskItem task) async {
    if (task.id == null) return;
    final reminderDay = task.deadline.subtract(const Duration(days: 1));
    final scheduledTime = tz.TZDateTime(
      tz.local,
      reminderDay.year, reminderDay.month, reminderDay.day, 9, 0,
    );
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: task.id!,
      title: '⏰ ใกล้ครบกำหนดแล้ว!',
      body: '"${task.title}" จะครบกำหนดพรุ่งนี้',
      scheduledDate: scheduledTime,
      notificationDetails: _taskChannel(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// แจ้งเตือนที่เวลาที่ผู้ใช้กำหนดเอง
  Future<void> scheduleTaskReminderAt(TaskItem task, DateTime notifyAt) async {
    if (task.id == null) return;
    final scheduledTime = tz.TZDateTime(
      tz.local,
      notifyAt.year, notifyAt.month, notifyAt.day,
      notifyAt.hour, notifyAt.minute,
    );
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final diff = task.deadline.difference(notifyAt);
    final String timeLabel;
    if (diff.inDays >= 1) {
      timeLabel = 'อีก ${diff.inDays} วัน';
    } else if (diff.inHours >= 1) {
      timeLabel = 'อีก ${diff.inHours} ชั่วโมง';
    } else {
      timeLabel = 'อีก ${diff.inMinutes} นาที';
    }

    await _plugin.zonedSchedule(
      id: task.id!,
      title: '⏰ แจ้งเตือนงาน',
      body: '"${task.title}" จะครบกำหนด $timeLabel',
      scheduledDate: scheduledTime,
      notificationDetails: _taskChannel(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(int taskId) async {
    await _plugin.cancel(id: taskId);
  }

  // ─── Budget alert ─────────────────────────────────────
  Future<void> sendBudgetAlert({
    required int walletId,
    required String walletName,
    required String emoji,
    required double spent,
    required double budget,
    required bool isExceeded,
  }) async {
    final percent = (spent / budget * 100).toStringAsFixed(0);
    final title = isExceeded
        ? '$emoji $walletName — เกินงบแล้ว!'
        : '$emoji $walletName — ใกล้ถึงงบแล้ว';
    final body = isExceeded
        ? 'ใช้ไป ฿${spent.toStringAsFixed(0)} จากงบ ฿${budget.toStringAsFixed(0)} ($percent%)'
        : 'ใช้ไปแล้ว $percent% ของงบ ฿${budget.toStringAsFixed(0)} เดือนนี้';

    await _plugin.show(
      id: walletId + 10000,
      title: title,
      body: body,
      notificationDetails: _budgetChannel(),
    );
  }

  // ─── Low balance alert ────────────────────────────────
  Future<void> sendLowBalanceAlert({
    required int walletId,
    required String walletName,
    required String emoji,
    required double balance,
    required double threshold,
  }) async {
    await _plugin.show(
      id: walletId + 20000,
      title: '$emoji $walletName — เงินเหลือน้อย!',
      body: 'คงเหลือ ฿${balance.toStringAsFixed(2)} (ต่ำกว่า ฿${threshold.toStringAsFixed(0)})',
      notificationDetails: _budgetChannel(),
    );
  }

  Future<void> cancelBudgetAlerts(int walletId) async {
    await _plugin.cancel(id: walletId + 10000);
    await _plugin.cancel(id: walletId + 20000);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ─── Recurring expense alert ──────────────────────────
  Future<void> sendRecurringExpenseAlert({
    required int walletId,
    required String label,
    required double amount,
  }) async {
    await _plugin.show(
      id: walletId + 30000,
      title: '💸 หักรายจ่ายประจำแล้ว',
      body: '"$label" หักไป ฿${amount.toStringAsFixed(0)} อัตโนมัติ',
      notificationDetails: _budgetChannel(),
    );
  }

  // ─── Channel helpers ──────────────────────────────────
  NotificationDetails _taskChannel() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminder_channel',
          'แจ้งเตือนตารางงาน',
          channelDescription: 'แจ้งเตือนก่อนงานครบกำหนด',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  NotificationDetails _budgetChannel() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alert_channel',
          'แจ้งเตือนงบประมาณ',
          channelDescription: 'แจ้งเตือนเมื่อใช้เงินเกินงบหรือเหลือน้อย',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
