import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  final List<String> reminders = const [
    'Your appointment with Dr. Sarah Johnson is tomorrow at 11:00 AM.',
    'Remember to take your Amoxicillin at 8:00 PM tonight.',
    'Your queue number for Dr. Emily Davis is now 2. Please be ready.',
  ];

  // Healthcare theme colors from home screen
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Reminders', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: reminders.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_active, size: 80, color: AppColors.lightGrey),
              SizedBox(height: 20),
              Text(
                'No reminders set.',
                style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(Icons.notifications, color: primaryBlue),
              title: Text(reminder),
            ),
          );
        },
      ),
    );
  }
}