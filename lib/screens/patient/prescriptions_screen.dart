// lib/screens/patient/prescriptions_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/constants/colors.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({Key? key}) : super(key: key);

  @override
  _PrescriptionsScreenState createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view prescriptions.'),
        ),
      );
    }

    final String patientId = currentUser!.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Prescriptions', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .collection('prescriptions')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading prescriptions.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 80, color: AppColors.lightGrey),
                    const SizedBox(height: 20),
                    Text(
                      'No prescriptions found.',
                      style: TextStyle(fontSize: 18, color: AppColors.lightGrey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final prescriptions = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final record = prescriptions[index].data() as Map<String, dynamic>;
              return _buildPrescriptionCard(record);
            },
          );
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> record) {
    String date = 'N/A';
    if (record['date'] is String) {
      date = record['date'] as String;
    } else if (record['date'] is Timestamp) {
      date = (record['date'] as Timestamp).toDate().toString();
    } else if (record['timestamp'] is Timestamp) {
      date = (record['timestamp'] as Timestamp).toDate().toString();
    }

    final List<dynamic> medicines = (record['medicines'] as List<dynamic>?) ?? [];
    final String diagnosis = record['diagnosis'] as String? ?? 'N/A';
    final String followUpDate = record['followUpDate'] as String? ?? 'N/A';
    final String doctorName = record['doctorName'] as String? ?? 'N/A';
    final String doctorSpecialty = record['doctorSpecialty'] as String? ?? 'N/A';
    final String clinic = record['clinicAddress'] as String? ?? 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Info
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          doctorSpecialty,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clinic,
                          style: const TextStyle(color: Colors.black45, fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.medical_services, color: Colors.blue, size: 36),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(color: Colors.black54, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Diagnosis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      diagnosis,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Medication
            Text(
              "Medications",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 8),

            if (medicines.isEmpty)
              const Text('No medication prescribed.', style: TextStyle(color: Colors.black54))
            else
              ...medicines.map((med) {
                final medMap = Map<String, dynamic>.from(med);
                final String instructions = (medMap['specialInstructions'] as String?) ?? '';
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medMap['medicineName'] as String? ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(medMap['dosageAndFrequency'] as String? ?? 'N/A', style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 10),
                          const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(medMap['duration'] as String? ?? 'N/A', style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      if (instructions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(child: Text(instructions, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 15),
            // Follow-up
            Row(
              children: [
                const Icon(Icons.event_note, color: Colors.purple, size: 18),
                const SizedBox(width: 6),
                Text("Follow-up: $followUpDate", style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
