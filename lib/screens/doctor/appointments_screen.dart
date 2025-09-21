// lib/screens/doctor/appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/utils/appointment_status.dart';
import 'package:smartcare_app/screens/doctor/patient_record_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/screens/doctor/prescription_screen.dart';
import 'package:smartcare_app/screens/doctor/history_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key, required this.doctorId}) : super(key: key);
  final String doctorId;

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, String> _doctorDetails = {
    'name': 'Dr. Alex Chen',
    'specialty': 'APOLLO DOCTOR',
    'address': '123 Anywhere St., Any City',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDoctorDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        setState(() {
          _doctorDetails['name'] = data['name'] ?? 'Dr. Alex Chen';
          _doctorDetails['specialty'] = data['specialty'] ?? 'General Physician';
          _doctorDetails['address'] = data['clinicAddress'] ?? 'N/A';
        });
      }
    } catch (e) {
      print('Error fetching doctor details: $e');
    }
  }

  Future<void> _updateAppointmentStatus(String docId, AppointmentStatus newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'status': newStatus.toShortString()});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment status updated to ${newStatus.toShortString()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status.')),
      );
    }
  }

  void _showPatientRecordBottomSheet(String patientId, String patientName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (BuildContext context, ScrollController scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: PatientRecordScreen(
                patientId: patientId,
                patientName: patientName,
                doctorDetails: _doctorDetails,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Queue Management", style: TextStyle(color: Color(0xFF212121), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
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
          _buildAppointmentsList(AppointmentStatus.inProgress),
          _buildAppointmentsList(AppointmentStatus.pending),
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
            final patientId = appointmentData['patientId'] ?? '';
            final time = appointmentData['time'] ?? 'N/A';
            final date = (appointmentData['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF3498DB),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
                subtitle: Text(
                  'Time: $time | Date: ${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: PopupMenuButton<AppointmentStatus>(
                  onSelected: (AppointmentStatus result) {
                    _updateAppointmentStatus(appointment.id, result);
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<AppointmentStatus>>[
                    const PopupMenuItem<AppointmentStatus>(
                      value: AppointmentStatus.pending,
                      child: Text('Pending'),
                    ),
                    const PopupMenuItem<AppointmentStatus>(
                      value: AppointmentStatus.inProgress,
                      child: Text('In Progress'),
                    ),
                    const PopupMenuItem<AppointmentStatus>(
                      value: AppointmentStatus.completed,
                      child: Text('Completed'),
                    ),
                    const PopupMenuItem<AppointmentStatus>(
                      value: AppointmentStatus.canceled,
                      child: Text('Canceled'),
                    ),
                  ],
                ),
                onTap: () {
                  _showPatientRecordBottomSheet(patientId, patientName);
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

  DateTime _parseTime(String time) {
    final parts = time.split(RegExp(r'[: ]'));
    if (parts.length < 3) {
      return DateTime(0);
    }
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    final period = parts[2].toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    return DateTime(1, 1, 1, hour, minute);
  }
}
