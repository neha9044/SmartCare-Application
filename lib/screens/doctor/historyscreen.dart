import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key, required this.history}) : super(key: key);

  final List<Map<String, String>> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History & Records")),
      body: history.isEmpty
          ? const Center(
        child: Text(
          "No prescriptions saved yet.",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: history.length,
        itemBuilder: (context, index) {
          return _buildPrescriptionRecordCard(history[index]);
        },
      ),
    );
  }

  Widget _buildPrescriptionRecordCard(Map<String, String> record) {
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
                        record['date']!,
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.receipt_long,
                  color: Color(0xFF95A5A6),
                  size: 36,
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            _buildDetailRow("Doctor:", "${record['doctorName']}"),
            _buildDetailRow("Specialty:", "${record['doctorSpecialty']}"),
            _buildDetailRow("Clinic:", "${record['clinicAddress']}"),
            const SizedBox(height: 15),
            Text(
              "Patient Details:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
            ),
            _buildDetailRow("Patient:", "${record['name']} (Age: ${record['age']})"),
            _buildDetailRow("Address:", record['address']!),
            const SizedBox(height: 15),
            Text(
              "Prescription:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 5),
            Text(record['prescription']!),
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
