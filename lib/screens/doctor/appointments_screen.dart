// appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/utils/appointment_status.dart'; // Make sure this path is correct

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key, required this.doctorId}) : super(key: key);
  final String doctorId;

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Queue Management"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2196F3),
          tabs: const [
            Tab(icon: Icon(Icons.timelapse), text: 'In Progress'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(AppointmentStatus.pending),
          _buildAppointmentsList(AppointmentStatus.inProgress),
          _buildAppointmentsList(AppointmentStatus.completed),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(AppointmentStatus status) {
    String statusString = status.toShortString();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('status', isEqualTo: statusString)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading appointments.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No ${statusString.toLowerCase()} appointments.',
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        final appointments = snapshot.data!.docs;
        final sortedAppointments = _sortAppointments(appointments);

        return ListView.builder(
          itemCount: sortedAppointments.length,
          itemBuilder: (context, index) {
            final appointment = sortedAppointments[index];
            final appointmentData = appointment.data() as Map<String, dynamic>;
            final patientName = appointmentData['patientName'] ?? 'Unknown Patient';
            final time = appointmentData['time'] ?? 'N/A';
            final date = (appointmentData['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF3498DB),
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

  List<QueryDocumentSnapshot> _sortAppointments(List<QueryDocumentSnapshot> appointments) {
    appointments.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = (aData['date'] as Timestamp).toDate();
      final bDate = (bData['date'] as Timestamp).toDate();
      final aTime = aData['time'] as String;
      final bTime = bData['time'] as String;

      int dateComparison = aDate.compareTo(bDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
      return _parseTime(aTime).compareTo(_parseTime(bTime));
    });
    return appointments;
  }

  // Improved _parseTime function to handle various formats robustly
  DateTime _parseTime(String time) {
    final parts = time.split(RegExp(r'[: ]'));
    if (parts.length < 3) {
      // Fallback for malformed time strings
      return DateTime(0);
    }
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    final period = parts[2].toUpperCase();

    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0; // Midnight case
    }
    return DateTime(1, 1, 1, hour, minute);
  }
}