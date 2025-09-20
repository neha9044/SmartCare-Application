// lib/screens/patient/appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/patient/queue_status_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view prescriptions.',
            style: TextStyle(color: AppColors.darkGrey),
          ),
        ),
      );
    }
    final String patientId = currentUser.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch appointments where the patientId matches the current user's ID
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: patientId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading appointments.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 80, color: AppColors.lightGrey),
                    const SizedBox(height: 20),
                    Text(
                      'No upcoming appointments.',
                      style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointmentData = appointments[index].data() as Map<String, dynamic>;
              // Convert Firestore Timestamp to DateTime
              final Timestamp timestamp = appointmentData['date'] as Timestamp;
              final DateTime date = timestamp.toDate();

              // Display patient-friendly date format
              final String formattedDate = '${date.day}/${date.month}/${date.year}';
              final String status = appointmentData['status'] ?? 'N/A';
              final String doctorId = appointmentData['doctorId']; // Get the doctorId

              // Determine if the appointment is for today
              final bool isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(
                    Icons.person,
                    color: primaryBlue,
                  ),
                  title: Text(
                    'Dr. ' + (appointmentData['doctorName'] ?? 'N/A'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${appointmentData['doctorSpecialty'] ?? 'N/A'}\n'
                        '$formattedDate at ${appointmentData['time'] ?? 'N/A'}',
                  ),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      color: status == 'pending' ? AppColors.green : AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    if (isToday && (status == 'pending' || status == 'inProgress')) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QueueStatusScreen(
                            doctorId: doctorId,
                            patientId: patientId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Queue status is only available for today\'s pending or in-progress appointments.')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}