// lib/screens/patient/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: AppColors.lightGrey),
            SizedBox(height: 20),
            Text(
              'No new notifications.',
              style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
              textAlign: TextAlign.center,
            ),
            Text(
              'General announcements will appear here.',
              style: TextStyle(fontSize: 14, color: AppColors.lightGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}