// lib/screens/doctor/history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key, required this.patientId}) : super(key: key);

  final String patientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
              return _buildPrescriptionRecordCard(record);
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

  Widget _buildPrescriptionRecordCard(Map<String, dynamic> record) {
    String date = 'N/A';
    if (record['date'] is String) {
      date = record['date'] as String;
    } else if (record['date'] is Timestamp) {
      date = (record['date'] as Timestamp).toDate().toString();
    } else if (record['timestamp'] is Timestamp) {
      date = (record['timestamp'] as Timestamp).toDate().toString();
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "RX for ${record['name']}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF34495E)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF95A5A6),
                  size: 36,
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            _buildDetailRow("Doctor:", record['doctorName'] as String? ?? 'N/A'),
            _buildDetailRow("Specialty:", record['doctorSpecialty'] as String? ?? 'N/A'),
            _buildDetailRow("Clinic:", record['clinicAddress'] as String? ?? 'N/A'),
            const SizedBox(height: 15),
            Text(
              "Patient Details:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
            ),
            _buildDetailRow("Patient:", "${record['name']} (Age: ${record['age']})"),
            _buildDetailRow("Address:", record['address'] as String? ?? 'N/A'),
            const SizedBox(height: 15),
            Text(
              "Prescription:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 5),
            Text(record['prescription'] as String? ?? 'N/A'),
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
            width: 80,
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