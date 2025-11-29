import 'package:flutter/material.dart';
import 'notification.dart';
import 'splash.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const MedCheckApp());
}

class MedCheckApp extends StatelessWidget {
  const MedCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMedCheck',
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
