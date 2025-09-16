import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> appointments = const [
    {
      'doctor': 'Dr. Emily Davis',
      'specialization': 'General Physician',
      'date': 'Sep 21, 2025',
      'time': '10:00 AM',
      'status': 'upcoming',
    },
    {
      'doctor': 'Dr. Sarah Johnson',
      'specialization': 'Cardiologist',
      'date': 'Oct 20, 2025',
      'time': '11:00 AM',
      'status': 'upcoming',
    },
    {
      'doctor': 'Dr. Michael Brown',
      'specialization': 'Dermatologist',
      'date': 'Sep 10, 2025',
      'time': '02:00 PM',
      'status': 'completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.glassmorphismGradient,
        ),
        child: appointments.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 80, color: AppColors.lightGrey),
                SizedBox(height: 20),
                Text(
                  'No upcoming appointments.',
                  style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(
                  Icons.person,
                  color: AppColors.primaryColor,
                ),
                title: Text(
                  appointment['doctor']!,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${appointment['specialization']!}\n${appointment['date']!} at ${appointment['time']!}'),
                trailing: Text(
                  appointment['status']!,
                  style: TextStyle(
                    color: appointment['status'] == 'upcoming' ? AppColors.green : AppColors.darkGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}