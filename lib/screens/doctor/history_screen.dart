// lib/screens/doctor/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key, required this.patientId}) : super(key: key);

  final String patientId;

  @override
  Widget build(BuildContext context) {
    final String? currentDoctorId = FirebaseAuth.instance.currentUser?.uid;

    if (currentDoctorId == null) {
      return const Center(child: Text('Doctor not logged in.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('prescriptions')
          .where('doctorId', isEqualTo: currentDoctorId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading history.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No prescriptions saved yet.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final history = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: history.length,
          itemBuilder: (context, index) {
            try {
              final record = history[index].data() as Map<String, dynamic>;
              return _buildPrescriptionCard(record);
            } catch (e) {
              print('Error processing document at index $index: $e');
              return Card(
                color: Colors.red.shade50,
                child: const ListTile(
                  title: Text('Error with this record.', style: TextStyle(color: Colors.red)),
                  subtitle: Text('This document could not be loaded due to a data error.'),
                ),
              );
            }
          },
        );
      },
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
    final String patientName = record['patientName'] as String? ?? 'N/A';
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
            // Patient Info
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
                    child: Text(
                      "RX for $patientName",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF2C3E50)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.blue, size: 36),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Doctor Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Doctor:", doctorName),
                  _buildDetailRow("Specialty:", doctorSpecialty),
                  _buildDetailRow("Clinic:", clinic),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
