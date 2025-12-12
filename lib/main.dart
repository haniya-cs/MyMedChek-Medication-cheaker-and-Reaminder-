import 'package:flutter/material.dart';
import 'notification.dart';
import 'splash.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedCheckApp());
}

class MedCheckApp extends StatelessWidget {
  const MedCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: NotificationService.messengerKey,
      title: 'MyMedCheck',
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
