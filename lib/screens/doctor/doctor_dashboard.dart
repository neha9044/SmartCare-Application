import 'package:flutter/material.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);
  final cardData = const [
    {
      "title": "Queue Management",
      "subtitle": "5 patients waiting",
      "icon": Icons.queue,
      "color": Color(0xFF3498DB),
      "route": null,
    },
    {
      "title": "Chat with Patients",
      "subtitle": "Real-time communication",
      "icon": Icons.chat_bubble_outline,
      "color": Color(0xFF2C3E50),
      "route": '/patientList',
    },
    {
      "title": "Prescriptions",
      "subtitle": "Manage and send prescriptions",
      "icon": Icons.medical_services_outlined,
      "color": Color(0xFF34495E),
      "route": null,
    },
    {
      "title": "Medical Outlets",
      "subtitle": "Send prescriptions to stores",
      "icon": Icons.storefront,
      "color": Color(0xFF16A085),
      "route": '/medicalOutlets',
    },
    {
      "title": "History & Records",
      "subtitle": "Full patient details",
      "icon": Icons.folder_open,
      "color": Color(0xFF95A5A6),
      "route": '/patientList',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: cardData.map((data) => _buildDashboardCard(context, data)).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          if (data['route'] != null) {
            Navigator.pushNamed(context, data['route']);
          }
        },
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                (data['color'] as Color).withOpacity(0.1),
                (data['color'] as Color).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: data['color'],
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: (data['color'] as Color).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(data['icon'], color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: data['color'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['subtitle'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}