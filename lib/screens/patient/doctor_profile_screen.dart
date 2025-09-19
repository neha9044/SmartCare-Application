// lib/screens/patient/doctor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/widgets/info_section.dart';
import 'book_appointment_screen.dart';
import 'chat_screen.dart'; // Import the new chat screen

class DoctorProfileScreen extends StatelessWidget {
  final Doctor doctor;

  const DoctorProfileScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Corrected logic to safely get initials
    String initials = '';
    if (doctor.name.isNotEmpty) {
      List<String> nameParts = doctor.name.split(' ');
      if (nameParts.isNotEmpty) {
        initials += nameParts.first[0];
        if (nameParts.length > 1) {
          initials += nameParts[1][0];
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Doctor Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryColor,
                    child: Text(
                      initials.toUpperCase(), // Use the safely-generated initials here
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.orange, size: 20),
                      Text(
                        ' ${doctor.rating} (${doctor.reviewCount} reviews)',
                        style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            InfoSection(title: 'About', content: [
              Text(
                doctor.about,
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey),
              ),
            ]),
            const SizedBox(height: 16),
            InfoSection(title: 'Experience & Qualifications', content: [
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: AppColors.darkGrey),
                  const SizedBox(width: 8),
                  Text('${doctor.experience} of experience'),
                ],
              ),
              const SizedBox(height: 8),
              ...doctor.qualifications.map((qual) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: AppColors.darkGrey),
                    const SizedBox(width: 8),
                    Text(qual),
                  ],
                ),
              )).toList(),
            ]),
            const SizedBox(height: 16),
            InfoSection(title: 'Hospital & Location', content: [
              Row(
                children: [
                  const Icon(Icons.local_hospital, size: 16, color: AppColors.darkGrey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(doctor.hospital)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.darkGrey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(doctor.location)),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            InfoSection(title: 'Consultation Fee', content: [
              Text(
                '₹${doctor.consultationFee}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientChatScreen(doctor: doctor),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Chat with Doctor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: doctor.isAvailableToday ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(doctor: doctor),
                    ),
                  );
                } : null,
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(doctor.isAvailableToday ? 'Book Appointment' : 'Not Available Today'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}