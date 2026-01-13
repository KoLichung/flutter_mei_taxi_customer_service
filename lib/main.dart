import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  // 注意：在運行應用之前，請確保已完成以下步驟：
  // 1. 在 Firebase Console (https://console.firebase.google.com/) 創建項目
  // 2. 安裝 FlutterFire CLI: dart pub global activate flutterfire_cli
  // 3. 運行: flutterfire configure 來生成 firebase_options.dart
  // 4. 將生成的 firebase_options.dart 文件添加到項目中
  // 5. 對於 Android：將 google-services.json 放到 android/app/ 目錄
  // 6. 對於 iOS：將 GoogleService-Info.plist 放到 ios/Runner/ 目錄
  try {
    await Firebase.initializeApp();
    
    // 初始化推送通知服務
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // 註冊 FCM 設備到服務器（user_id 可選，這裡設為 null）
    await notificationService.registerFCMDevice(userId: null);
  } catch (e) {
    debugPrint('Firebase 初始化失敗: $e');
    debugPrint('請確保已完成 Firebase 配置，詳見 main.dart 中的註釋');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mei派車客服',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
