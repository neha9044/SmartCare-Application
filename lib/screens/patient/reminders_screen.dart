// lib/screens/patient/reminders_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Healthcare theme colors
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Reminders', style: TextStyle(color: Colors.white)),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view reminders.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Reminders', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading reminders: ${snapshot.error}'));
          }

          final List<String> reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_active, size: 80, color: AppColors.lightGrey),
                    const SizedBox(height: 20),
                    Text(
                      'No reminders found.',
                      style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
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
          );
        },
      ),
    );
  }

  Future<List<String>> _fetchReminders() async {
    final patientId = currentUser!.uid;
    final List<String> reminders = [];

    // Fetch Appointments
    final appointmentsQuery = await FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .where('status', whereIn: ['pending', 'inProgress']) // Only show upcoming or active appointments
        .orderBy('timestamp', descending: true)
        .limit(5) // Limit to the most recent 5 appointments
        .get();

    for (var doc in appointmentsQuery.docs) {
      final data = doc.data();
      final String doctorName = data['doctorName'] ?? 'N/A';
      final String date = data['date'] ?? 'N/A';
      final String time = data['time'] ?? 'N/A';
      reminders.add('Your appointment with $doctorName is on $date at $time.');
    }

    // Fetch Prescription Reminders (e.g., for today's medication)
    final prescriptionsQuery = await FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('prescriptions')
        .orderBy('timestamp', descending: true)
        .limit(1) // Get the most recent prescription
        .get();

    for (var doc in prescriptionsQuery.docs) {
      final data = doc.data();
      final List<dynamic> medicines = data['medicines'] ?? [];
      for (var med in medicines) {
        final medMap = med as Map<String, dynamic>;
        final String medName = medMap['medicineName'] as String? ?? 'N/A';
        final String dosage = medMap['dosageAndFrequency'] as String? ?? 'N/A';
        reminders.add('Remember to take your $medName ($dosage).');
      }
    }

    // You can add logic for other reminder types here (e.g., queue reminders)

    return reminders;
  }
}