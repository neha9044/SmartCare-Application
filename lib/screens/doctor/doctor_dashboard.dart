import 'package:flutter/material.dart';
import 'PrescriptionScreen.dart';
import 'historyscreen.dart'; // Import the new history screen

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  _DoctorDashboardScreenState createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
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
  ];

  List<Map<String, String>> history = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doctor Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ...cardData.map((data) => _buildDashboardCard(context, data)).toList(),
            const SizedBox(height: 20),
            _buildHistoryCard(context),
          ],
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
          if (data['title'] == 'Prescriptions') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PrescriptionScreen(
                  onSave: (record) {
                    setState(() {
                      history.add(record);
                    });
                  },
                ),
              ),
            );
          } else if (data['route'] != null) {
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

  Widget _buildHistoryCard(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryScreen(history: history),
            ),
          );
        },
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(0xFF95A5A6).withOpacity(0.1),
                Color(0xFF95A5A6).withOpacity(0.05),
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
                    color: Color(0xFF95A5A6),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF95A5A6).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(Icons.folder_open, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "History & Records",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF95A5A6),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "View all past prescriptions",
                        style: TextStyle(
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
