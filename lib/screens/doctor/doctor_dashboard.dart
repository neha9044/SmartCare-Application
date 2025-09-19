// lib/screens/doctor/doctor_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/services/auth_service.dart';
import 'package:smartcare_app/screens/doctor/appointments_screen.dart';
import 'package:smartcare_app/utils/appointment_status.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smartcare_app/screens/doctor/patient_record_screen.dart';
import 'package:smartcare_app/screens/doctor/DoctorProfileScreen.dart';
import 'package:smartcare_app/screens/doctor/chat_inbox_screen.dart'; // Import the chat inbox

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({Key? key}) : super(key: key);

  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String _doctorName = 'Doctor';
  String _profileImageUrl = '';
  String? _currentDoctorId;
  Map<String, String> _doctorDetails = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1976D2);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<QueryDocumentSnapshot>> _selectedAppointments;

  @override
  void initState() {
    super.initState();
    _currentDoctorId = _authService.currentUser?.uid;
    print('Current Logged-in User ID: $_currentDoctorId');
    _setupAnimations();
    _fetchDoctorData();
    _selectedDay = _focusedDay;
    _selectedAppointments = ValueNotifier([]);
    _getAppointmentsForDay(_selectedDay!);
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  Future<void> _fetchDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _authService.getDoctorData(user.uid);
      if (data.isNotEmpty) {
        final String? fullName = data['name'];
        final String? profileUrl = data['profileImageUrl'];
        if (fullName != null && fullName.isNotEmpty) {
          final List<String> nameParts = fullName.split(' ');
          setState(() {
            _doctorName = nameParts.first;
            _profileImageUrl = profileUrl ?? '';
            _doctorDetails['name'] = data['name'] ?? 'Dr. Alex Chen';
            _doctorDetails['specialty'] = data['specialty'] ?? 'General Physician';
            _doctorDetails['address'] = data['clinicAddress'] ?? 'N/A';
          });
        }
      }
    }
  }

  Future<void> _getAppointmentsForDay(DateTime day) async {
    if (_currentDoctorId == null) return;
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: _currentDoctorId)
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

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _selectedAppointments.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentDoctorId == null) {
      return const Center(child: Text('Doctor not logged in.'));
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildStylishHeader(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildQueueManagementCard(),
                        const SizedBox(height: 16),
                        _buildChatInboxCard(), // Added Chat Inbox card
                        const SizedBox(height: 24),
                        _buildCalendarView(),
                        const SizedBox(height: 24),
                        _buildDailyAppointmentsList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStylishHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, darkBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: darkBlue.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_currentDoctorId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DoctorProfileScreen(doctorId: _currentDoctorId!),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : null,
                child: _profileImageUrl.isEmpty
                    ? Icon(Icons.person, color: darkBlue, size: 40)
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Dr. $_doctorName",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQueueManagementCard() {
    if (_currentDoctorId == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentsScreen(doctorId: _currentDoctorId!),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3498DB).withOpacity(0.1),
                  const Color(0xFF3498DB).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                  const Expanded(
                    child: Text(
                      "Queue Management",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF3498DB),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatInboxCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatInboxScreen(),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3498DB).withOpacity(0.1),
                  const Color(0xFF3498DB).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      "Chat Inbox",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF3498DB),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
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
      ),
    );
  }

  Widget _buildDailyAppointmentsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
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
                              doctorDetails: _doctorDetails,
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
      ),
    );
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
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}