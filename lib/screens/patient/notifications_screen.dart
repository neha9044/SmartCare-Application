// lib/screens/patient/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  // Method to mark a notification as read
  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notificationId).update({'read': true});
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view notifications.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('patientId', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: AppColors.lightGrey),
                  const SizedBox(height: 20),
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
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notificationDoc = notifications[index];
              final data = notificationDoc.data() as Map<String, dynamic>;
              final bool isRead = data['read'] ?? false;

              return Card(
                color: isRead ? Colors.white : Colors.blue.shade50,
                elevation: isRead ? 2 : 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => _markAsRead(notificationDoc.id),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(
                    isRead ? Icons.notifications : Icons.notifications_active,
                    color: isRead ? Colors.grey : primaryBlue,
                  ),
                  title: Text(
                    data['message'] ?? 'New Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}