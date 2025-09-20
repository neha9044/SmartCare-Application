// lib/screens/patient/queue_status_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/utils/appointment_status.dart'; //
import 'package:smartcare_app/constants/colors.dart'; //
import 'package:smartcare_app/models/appointment.dart'; //
import 'package:smartcare_app/services/websocket_queue_service.dart'; //

class QueueStatusScreen extends StatefulWidget {
  final String doctorId;
  final String patientId;

  const QueueStatusScreen({
    Key? key,
    required this.doctorId,
    required this.patientId,
  }) : super(key: key);

  @override
  _QueueStatusScreenState createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  late final WebSocketQueueService _websocketQueueService;

  @override
  void initState() {
    super.initState();
    // Initialize the service with both patientId and doctorId
    _websocketQueueService = WebSocketQueueService(
      patientId: widget.patientId,
      doctorId: widget.doctorId,
    );
  }

  @override
  void dispose() {
    _websocketQueueService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Status'),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _websocketQueueService.getAppointmentsStream(widget.doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading queue: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No appointments in the queue today.'));
          }

          final allAppointments = snapshot.data!;
          allAppointments.sort((a, b) => a.queueNumber.compareTo(b.queueNumber));

          final myIndex = allAppointments.indexWhere((app) => app.patientId == widget.patientId);

          if (myIndex == -1) {
            return const Center(child: Text('Your appointment was not found in the queue.'));
          }

          final appointmentsAhead = allAppointments.take(myIndex).where((app) => app.status != AppointmentStatus.completed.toShortString()).length;
          final myAppointment = allAppointments[myIndex];
          final myQueueNumber = appointmentsAhead + 1;
          final appointmentsBehind = allAppointments.skip(myIndex + 1).length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You are currently:',
                  style: TextStyle(fontSize: 20, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 10),
                Text(
                  '#$myQueueNumber',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'in the queue.',
                  style: TextStyle(fontSize: 20, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 20),
                _buildQueueItem(
                  myAppointment.time,
                  myAppointment.status,
                  true,
                ),
                const SizedBox(height: 20),
                Text(
                  'There are $appointmentsAhead people ahead of you.',
                  style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
                ),
                const SizedBox(height: 10),
                Text(
                  'There are $appointmentsBehind people behind you.',
                  style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueueItem(String time, String status, bool isMe) {
    IconData icon;
    Color color;
    if (status == AppointmentStatus.inProgress.toShortString()) {
      icon = Icons.forward;
      color = Colors.blue;
    } else {
      icon = Icons.access_time;
      color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? Colors.blue : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'You' : 'Patient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.blue.shade800 : Colors.black87,
                  ),
                ),
                Text('Appointment at: $time', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}