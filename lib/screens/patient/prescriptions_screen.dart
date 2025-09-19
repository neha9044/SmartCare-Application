// lib/screens/patient/prescriptions_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> prescriptions = const [
    {
      'doctor': 'Dr. Michael Brown',
      'date': 'Sep 10, 2025',
      'medication': 'Amoxicillin (500mg) - 2 times a day',
      'notes': 'Take with food to avoid stomach upset.'
    },
    {
      'doctor': 'Dr. Emily Davis',
      'date': 'Aug 25, 2025',
      'medication': 'Vitamin D3 - 1 tablet daily',
      'notes': 'Take in the morning with breakfast.'
    },
  ];

  // Healthcare theme colors from home screen
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Prescriptions', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: prescriptions.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 80, color: AppColors.lightGrey),
              SizedBox(height: 20),
              Text(
                'No prescriptions found.',
                style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prescriptions.length,
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Icon(Icons.medical_services_outlined, color: primaryBlue),
              title: Text(
                prescription['doctor']!,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${prescription['medication']!}\nDate: ${prescription['date']!}\nNotes: ${prescription['notes']!}',
              ),
            ),
          );
        },
      ),
    );
  }
}