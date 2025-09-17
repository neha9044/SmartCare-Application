import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/services/auth_service.dart';
import 'PrescriptionScreen.dart';
import 'historyscreen.dart'; // Import the new history screen

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  @override
  _DoctorDashboardScreenState createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final AuthService _authService = AuthService();
  late String? _currentDoctorId;
  int _queueCount = 0;

  @override
  void initState() {
    super.initState();
    _currentDoctorId = _authService.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentDoctorId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Doctor Dashboard")),
        body: const Center(
          child: Text("User not logged in as a doctor."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF4A90E2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildQueueManagementCard(),
            const SizedBox(height: 20),
            _buildDashboardCard(
              context: context,
              title: "Chat with Patients",
              subtitle: "Real-time communication",
              icon: Icons.chat_bubble_outline,
              color: const Color(0xFF2C3E50),
              route: '/patientList',
            ),
            _buildDashboardCard(
              context: context,
              title: "Prescriptions",
              subtitle: "Manage and send prescriptions",
              icon: Icons.medical_services_outlined,
              color: const Color(0xFF34495E),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrescriptionScreen(onSave: (record) {})),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildHistoryCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? route,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap ??
                () {
              if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
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
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
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

  Widget _buildQueueManagementCard() {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // This card now acts as a display for the queue.
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(0xFF3498DB).withOpacity(0.1),
                Color(0xFF3498DB).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3498DB),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3498DB).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.queue, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Queue Management",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3498DB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$_queueCount patients waiting",
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
                const SizedBox(height: 20),
                const Text(
                  "Upcoming Appointments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildAppointmentsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: _currentDoctorId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading appointments.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No appointments booked yet.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        final appointments = snapshot.data!.docs;
        _queueCount = appointments.length;

        // Rebuild the parent widget to update the queue count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            final appointmentData = appointment.data() as Map<String, dynamic>;
            final patientName = appointmentData['patientName'] ?? 'Unknown Patient';
            final time = appointmentData['time'] ?? 'N/A';
            final date = (appointmentData['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xFF3498DB),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Time: $time | Date: ${date.day}/${date.month}/${date.year}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to patient profile or start chat
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    // ... This remains unchanged
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // You need to pass history data to HistoryScreen. This is currently static.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HistoryScreen(history: []), // Replace [] with your history data
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