import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._internal();
  static final LocalNotificationsService _instance = LocalNotificationsService._internal();
  factory LocalNotificationsService.instance() => _instance;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  final _androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');

  final _iosInitializationSettings = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  final _androidChannel = const AndroidNotificationChannel(
    'channel_id',
    'Channel name',
    description: 'Android push notification channel',
    importance: Importance.max,
  );
  final _deadlineChannel = const AndroidNotificationChannel(
    'deadline_channel',
    'Deadline Reminders',
    description: 'Notifications for upcoming order deadlines',
    importance: Importance.max,
  );
  bool _isFlutterLocalNotificationInitialized = false;
  int _notificationIdCounter = 0;

  Future<void> init() async {
    if (_isFlutterLocalNotificationInitialized) {
      return;
    }
    tz.initializeTimeZones();
    // Resolve local timezone using the device's UTC offset — no native plugin needed.
    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    final String tzName = _tzNameFromOffset(offsetMinutes);
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final initializationSettings = InitializationSettings(
      android: _androidInitializationSettings,
      iOS: _iosInitializationSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Foreground notification has been tapped: ${response.payload}');
      },
    );
    final androidImpl = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_androidChannel);
    await androidImpl?.createNotificationChannel(_deadlineChannel);
    _isFlutterLocalNotificationInitialized = true;
  }

  Future<void> showNotification(
    String? title,
    String? body,
    String? payload,
  ) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      _notificationIdCounter++,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Schedules deadline reminder notifications at 9:00 AM on the days that are
  /// [daysBeforeList] before [deadline]. Existing notifications for this order
  /// are cancelled first.
  ///
  /// Notification IDs are deterministic: orderId * 10 + daysOffset
  /// e.g. orderId=5, 3 days before → id 53, 2 days before → 52, 1 day before → 51
  Future<void> scheduleDeadlineNotifications({
    required int orderId,
    required String orderName,
    required String clientName,
    required DateTime deadline,
    List<int> daysBeforeList = const [3, 2, 1],
  }) async {
    await cancelDeadlineNotifications(orderId);

    final now = DateTime.now();
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final today = DateTime(now.year, now.month, now.day);

    // If deadline is already in the past, skip entirely
    if (deadlineDay.isBefore(today)) {
      print('⚠️ Deadline for order $orderId is in the past, no notifications scheduled');
      return;
    }

    final String langCode = GetStorage().read('langCode') ?? 'tm';

    // Always fire an immediate notification now if deadline is within 3 days
    final daysUntilDeadline = deadlineDay.difference(today).inDays;
    if (daysUntilDeadline <= 3) {
      final String urgencyText = _deadlineBody(langCode, clientName, daysUntilDeadline);
      final androidDetails = AndroidNotificationDetails(
        _deadlineChannel.id,
        _deadlineChannel.name,
        channelDescription: _deadlineChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      await _flutterLocalNotificationsPlugin.show(
        orderId * 10,
        orderName,
        urgencyText,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'order_$orderId',
      );
      print('🔔 Fired immediate notification for order $orderId ($daysUntilDeadline days until deadline)');
    }

    // Schedule future 9 AM reminders for days that haven't passed yet
    for (final daysBefore in daysBeforeList) {
      // Use Duration subtraction to correctly handle month/year boundaries
      final reminderDay = deadlineDay.subtract(Duration(days: daysBefore));
      final scheduledDate = DateTime(reminderDay.year, reminderDay.month, reminderDay.day, 9, 0);

      // Skip if this reminder time is already in the past
      if (scheduledDate.isBefore(now)) continue;

      final tzScheduled = tz.TZDateTime.from(scheduledDate, tz.local);
      final notifId = orderId * 10 + daysBefore;

      final androidDetails = AndroidNotificationDetails(
        _deadlineChannel.id,
        _deadlineChannel.name,
        channelDescription: _deadlineChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      final notifDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        orderName,
        _deadlineBody(langCode, clientName, daysBefore),
        tzScheduled,
        notifDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'order_$orderId',
      );
      print('⏰ Scheduled notification id=$notifId for order $orderId ($daysBefore days before deadline on ${scheduledDate.toIso8601String()})');
    }
  }

  /// Returns localized notification body based on [langCode] and [daysLeft].
  static String _deadlineBody(String langCode, String clientName, int daysLeft) {
    switch (langCode) {
      case 'ru':
        if (daysLeft == 0) return '$clientName — срок СЕГОДНЯ!';
        if (daysLeft == 1) return '$clientName — 1 дн. до срока!';
        return '$clientName — $daysLeft дн. до срока';
      case 'tr':
        if (daysLeft == 0) return '$clientName — son tarih BUGÜN!';
        if (daysLeft == 1) return '$clientName — son tarihe 1 gün kaldı!';
        return '$clientName — son tarihe $daysLeft gün kaldı';
      case 'en':
        if (daysLeft == 0) return '$clientName — deadline is TODAY!';
        if (daysLeft == 1) return '$clientName — 1 day left until deadline!';
        return '$clientName — $daysLeft days left until deadline';
      case 'ch':
        if (daysLeft == 0) return '$clientName — 截止日期是今天！';
        if (daysLeft == 1) return '$clientName — 距截止日期还有1天！';
        return '$clientName — 距截止日期还有$daysLeft天';
      case 'uz':
        if (daysLeft == 0) return '$clientName — muddat BUGUN!';
        if (daysLeft == 1) return '$clientName — muddatga 1 kun qoldi!';
        return '$clientName — muddatga $daysLeft kun qoldi';
      default: // 'tm'
        if (daysLeft == 0) return '$clientName — möhlet ŞU GÜN!';
        if (daysLeft == 1) return '$clientName — möhlete 1 gün galdy!';
        return '$clientName — möhlete $daysLeft gün galdy';
    }
  }

  /// Cancels all deadline reminder notifications for the given order.
  Future<void> cancelDeadlineNotifications(int orderId, {List<int> daysBeforeList = const [3, 2, 1]}) async {
    // Cancel the immediate notification (id = orderId * 10 + 0)
    await _flutterLocalNotificationsPlugin.cancel(orderId * 10);
    for (final daysBefore in daysBeforeList) {
      final notifId = orderId * 10 + daysBefore;
      await _flutterLocalNotificationsPlugin.cancel(notifId);
    }
    print('🗑️ Cancelled deadline notifications for order $orderId');
  }

  /// Returns a timezone name that matches the given UTC offset in minutes.
  /// Falls back to a UTC±HH representative if no exact match is found.
  static String _tzNameFromOffset(int offsetMinutes) {
    // Common UTC offsets → representative IANA timezone name
    const offsetMap = <int, String>{
      -720: 'Etc/GMT+12',
      -660: 'Pacific/Apia',
      -600: 'Pacific/Honolulu',
      -540: 'America/Anchorage',
      -480: 'America/Los_Angeles',
      -420: 'America/Denver',
      -360: 'America/Chicago',
      -300: 'America/New_York',
      -240: 'America/Halifax',
      -180: 'America/Sao_Paulo',
      -120: 'Atlantic/South_Georgia',
      -60: 'Atlantic/Azores',
      0: 'Europe/London',
      60: 'Europe/Paris',
      120: 'Europe/Helsinki',
      180: 'Europe/Moscow',
      210: 'Asia/Tehran',
      240: 'Asia/Dubai',
      270: 'Asia/Kabul',
      300: 'Asia/Karachi',
      330: 'Asia/Kolkata',
      345: 'Asia/Kathmandu',
      360: 'Asia/Dhaka',
      390: 'Asia/Rangoon',
      420: 'Asia/Bangkok',
      480: 'Asia/Shanghai',
      540: 'Asia/Tokyo',
      570: 'Australia/Adelaide',
      600: 'Australia/Sydney',
      660: 'Pacific/Noumea',
      720: 'Pacific/Auckland',
      780: 'Pacific/Apia',
    };
    return offsetMap[offsetMinutes] ?? 'Etc/UTC';
  }
}
