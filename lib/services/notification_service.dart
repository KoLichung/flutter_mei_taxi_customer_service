import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'api_service.dart';

// 處理前台消息的頂層函數（必須是頂層函數）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('背景消息處理: ${message.messageId}');
  debugPrint('標題: ${message.notification?.title}');
  debugPrint('內容: ${message.notification?.body}');
  debugPrint('數據: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? _deviceId;
  String? get fcmToken => _fcmToken;
  String? get deviceId => _deviceId;

  // 初始化推送通知服務
  Future<void> initialize() async {
    // 初始化本地通知
    await _initializeLocalNotifications();

    // 請求通知權限
    await _requestPermission();

    // 設置背景消息處理器
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 獲取 FCM Token
    await _getFCMToken();

    // 監聽 Token 更新
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      debugPrint('========================================');
      debugPrint('🔄 FCM Token 已更新 (Registration ID):');
      debugPrint('$newToken');
      debugPrint('========================================');
      // 重新註冊設備
      if (_deviceId != null) {
        registerFCMDevice();
      }
    });

    // 處理前台消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 處理點擊通知打開應用的情況
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 檢查應用是否通過通知啟動
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  // 初始化本地通知
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 通知頻道設置
    const androidChannel = AndroidNotificationChannel(
      'mei_taxi_customer_service_channel',
      'Mei派車客服通知',
      description: '接收客服相關的推送通知',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // 請求通知權限
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('通知權限狀態: ${settings.authorizationStatus}');
  }

  // 獲取 FCM Token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('========================================');
      debugPrint('📱 FCM Registration Token (Registration ID):');
      debugPrint('$_fcmToken');
      debugPrint('========================================');
      // 這裡可以將 token 發送到後端服務器
      // await ApiService.updateFCMToken(_fcmToken);
    } catch (e) {
      debugPrint('❌ 獲取 FCM Token 失敗: $e');
    }
  }

  // 處理前台消息
  // 注意：當 app 在前台時，不顯示通知（只記錄日誌）
  // 當 app 在背景時，系統會自動顯示通知
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('========================================');
    debugPrint('📨 收到前台消息（App 在前台，不顯示通知）:');
    debugPrint('消息 ID: ${message.messageId}');
    debugPrint('標題: ${message.notification?.title}');
    debugPrint('內容: ${message.notification?.body}');
    debugPrint('數據: ${message.data}');
    debugPrint('========================================');
    
    // 不顯示通知，因為 app 在前台
    // 如果需要，可以在這裡觸發 UI 更新或其他邏輯
  }

  // 顯示本地通知
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    const androidDetails = AndroidNotificationDetails(
      'mei_taxi_customer_service_channel',
      'Mei派車客服通知',
      channelDescription: '接收客服相關的推送通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification?.title ?? '新消息',
      notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  // 處理點擊通知
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知被點擊: ${response.payload}');
    // 這裡可以處理導航邏輯，例如打開特定頁面
    // 可以通過 response.payload 獲取數據
  }

  // 處理通過通知打開應用的情況
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('通過通知打開應用: ${message.messageId}');
    debugPrint('數據: ${message.data}');
    // 這裡可以處理導航邏輯，例如打開特定頁面
    // 可以通過 message.data 獲取數據
  }

  // 訂閱主題（可選）
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('已訂閱主題: $topic');
  }

  // 取消訂閱主題（可選）
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('已取消訂閱主題: $topic');
  }

  // 獲取設備唯一 ID
  Future<String> _getDeviceId() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android ID
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? const Uuid().v4();
      }
      
      return const Uuid().v4();
    } catch (e) {
      debugPrint('❌ 獲取設備 ID 失敗: $e');
      return const Uuid().v4();
    }
  }

  // 註冊 FCM 設備到服務器
  Future<bool> registerFCMDevice({int? userId}) async {
    try {
      // 確保有 FCM Token
      if (_fcmToken == null) {
        await _getFCMToken();
      }
      
      if (_fcmToken == null) {
        debugPrint('❌ FCM Token 為空，無法註冊設備');
        return false;
      }

      // 獲取設備 ID
      if (_deviceId == null) {
        _deviceId = await _getDeviceId();
      }

      // 獲取設備類型
      String deviceType = Platform.isAndroid ? 'android' : 'ios';

      debugPrint('========================================');
      debugPrint('📱 開始註冊 FCM 設備:');
      debugPrint('Device ID: $_deviceId');
      debugPrint('Device Type: $deviceType');
      debugPrint('FCM Token: $_fcmToken');
      debugPrint('========================================');

      // 調用註冊 API
      await ApiService.registerFCMDevice(
        registrationId: _fcmToken!,
        deviceId: _deviceId!,
        type: deviceType,
        userId: userId,
      );

      debugPrint('✅ FCM 設備註冊成功');
      return true;
    } catch (e) {
      debugPrint('❌ FCM 設備註冊失敗: $e');
      return false;
    }
  }

  // 停用 FCM 設備
  Future<bool> unregisterFCMDevice() async {
    try {
      if (_deviceId == null) {
        _deviceId = await _getDeviceId();
      }

      debugPrint('========================================');
      debugPrint('📱 開始停用 FCM 設備:');
      debugPrint('Device ID: $_deviceId');
      debugPrint('========================================');

      await ApiService.unregisterFCMDevice(deviceId: _deviceId!);

      debugPrint('✅ FCM 設備已停用');
      return true;
    } catch (e) {
      debugPrint('❌ FCM 設備停用失敗: $e');
      return false;
    }
  }
}

