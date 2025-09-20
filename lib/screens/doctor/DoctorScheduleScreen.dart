// lib/screens/doctor/doctor_schedule_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smartcare_app/screens/doctor/patient_record_screen.dart';
import 'package:smartcare_app/utils/appointment_status.dart';

class DoctorScheduleScreen extends StatefulWidget {
  final String doctorId;
  final Map<String, String> doctorDetails;

  const DoctorScheduleScreen({
    Key? key,
    required this.doctorId,
    required this.doctorDetails,
  }) : super(key: key);

  @override
  _DoctorScheduleScreenState createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<QueryDocumentSnapshot>> _selectedAppointments;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedAppointments = ValueNotifier([]);
    _getAppointmentsForDay(_selectedDay!);
  }

  @override
  void dispose() {
    _selectedAppointments.dispose();
    super.dispose();
  }

  Future<void> _getAppointmentsForDay(DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    _selectedAppointments.value = querySnapshot.docs;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _getAppointmentsForDay(selectedDay);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Schedule'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendarView(),
              const SizedBox(height: 24),
              _buildDailyAppointmentsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16.0),
        Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueGrey,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: (day) {
              return [];
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyAppointmentsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Appointments for Selected Day',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<QueryDocumentSnapshot>>(
          valueListenable: _selectedAppointments,
          builder: (context, appointments, _) {
            if (appointments.isEmpty) {
              return const Center(child: Text('No appointments for this day.'));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                final data = appointment.data() as Map<String, dynamic>;
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(data['patientName']),
                    subtitle: Text('Time: ${data['time']}'),
                    trailing: PopupMenuButton<AppointmentStatus>(
                      onSelected: (AppointmentStatus result) {
                        _updateAppointmentStatus(appointment.id, result);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<AppointmentStatus>>[
                        const PopupMenuItem<AppointmentStatus>(
                          value: AppointmentStatus.inProgress,
                          child: Text('In Progress'),
                        ),
                        const PopupMenuItem<AppointmentStatus>(
                          value: AppointmentStatus.completed,
                          child: Text('Completed'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientRecordScreen(
                            patientId: data['patientId'],
                            patientName: data['patientName'],
                            doctorDetails: widget.doctorDetails,
                            scrollController: null,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}