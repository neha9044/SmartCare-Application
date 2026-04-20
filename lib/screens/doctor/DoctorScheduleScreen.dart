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
  bool _isLoading = true;

  // Enhanced color palette
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color pastelGreen = Color(0xFFE8F5E8);
  static const Color pastelOrange = Color(0xFFFFF3E0);
  static const Color softBlue = Color(0xFFF0F8FF);
  static const Color cardShadow = Color(0x1A1565C0);

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
    setState(() => _isLoading = true);
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Filter appointments locally to hide completed AND canceled ones
      final filteredAppointments = querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        return status != AppointmentStatus.completed.toShortString() &&
            status != AppointmentStatus.canceled.toShortString();
      }).toList();

      _selectedAppointments.value = filteredAppointments;
    } catch (e) {
      print('Error fetching appointments: $e');
      _selectedAppointments.value = [];
    } finally {
      setState(() => _isLoading = false);
    }
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

      await _getAppointmentsForDay(_selectedDay!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Appointment marked as ${newStatus.toShortString()}'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Failed to update status.'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, now.day);

    return Scaffold(
      backgroundColor: softBlue,
      body: CustomScrollView(
        slivers: [
          // Reduced App Bar height
          SliverAppBar(
            expandedHeight: 80, // Reduced from 120
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Schedule',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20, // Reduced from 22
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryBlue,
                      primaryBlue.withBlue(200),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0), // Reduced from 16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected date card - reduced size
                  _buildDateCard(),
                  const SizedBox(height: 12), // Reduced from 16

                  // Calendar section - removed title
                  _buildCalendarSection(now, nextMonth),
                  const SizedBox(height: 16), // Reduced from 24

                  // Appointments section
                  _buildAppointmentsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, lightBlue.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 8, // Reduced from 12
            offset: const Offset(0, 3), // Reduced from 4
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10), // Reduced from 12
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(10), // Reduced from 12
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: 20, // Reduced from 24
            ),
          ),
          const SizedBox(width: 12), // Reduced from 16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Date',
                  style: TextStyle(
                    fontSize: 12, // Reduced from 14
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2), // Reduced from 4
                Text(
                  _getFormattedDate(_selectedDay),
                  style: const TextStyle(
                    fontSize: 16, // Reduced from 18
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<List<QueryDocumentSnapshot>>(
            valueListenable: _selectedAppointments,
            builder: (context, appointments, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                decoration: BoxDecoration(
                  color: appointments.isEmpty ? Colors.grey[100] : pastelGreen,
                  borderRadius: BorderRadius.circular(16), // Reduced from 20
                ),
                child: Text(
                  '${appointments.length}',
                  style: TextStyle(
                    fontSize: 11, // Reduced from 12
                    fontWeight: FontWeight.w600,
                    color: appointments.isEmpty ? Colors.grey[600] : Colors.green[700],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(DateTime now, DateTime nextMonth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 8, // Reduced from 12
            offset: const Offset(0, 3), // Reduced from 4
          ),
        ],
      ),
      child: _buildCalendarView(now, nextMonth), // Removed title section
    );
  }

  Widget _buildCalendarView(DateTime now, DateTime nextMonth) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 12), // Reduced padding
      child: TableCalendar(
        firstDay: DateTime(now.year, now.month, 1),
        lastDay: DateTime(nextMonth.year, nextMonth.month + 1, 0),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16, // Reduced from 18
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          leftChevronIcon: Container(
            padding: const EdgeInsets.all(6), // Reduced from 8
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(6), // Reduced from 8
            ),
            child: Icon(Icons.chevron_left, color: primaryBlue, size: 16), // Reduced from 18
          ),
          rightChevronIcon: Container(
            padding: const EdgeInsets.all(6), // Reduced from 8
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(6), // Reduced from 8
            ),
            child: Icon(Icons.chevron_right, color: primaryBlue, size: 16), // Reduced from 18
          ),
          headerMargin: const EdgeInsets.only(bottom: 12), // Reduced from 16
          headerPadding: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 12, // Reduced from 13
          ),
          weekendStyle: TextStyle(
            color: primaryBlue.withOpacity(0.7),
            fontWeight: FontWeight.w700,
            fontSize: 12, // Reduced from 13
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          todayDecoration: BoxDecoration(
            color: accentBlue.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentBlue.withOpacity(0.3),
                blurRadius: 3, // Reduced from 4
                offset: const Offset(0, 1), // Reduced from 2
              ),
            ],
          ),
          selectedDecoration: BoxDecoration(
            color: primaryBlue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                blurRadius: 3, // Reduced from 4
                offset: const Offset(0, 1), // Reduced from 2
              ),
            ],
          ),
          defaultTextStyle: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 14, // Reduced from 15
          ),
          weekendTextStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 14, // Reduced from 15
          ),
          outsideTextStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14, // Reduced from 15
          ),
          tablePadding: const EdgeInsets.symmetric(horizontal: 12), // Reduced from 16
          cellMargin: const EdgeInsets.all(4), // Reduced from 6
        ),
        eventLoader: (day) => [],
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Reduced from 20
        boxShadow: [
          BoxShadow(
            color: cardShadow,
            blurRadius: 8, // Reduced from 12
            offset: const Offset(0, 3), // Reduced from 4
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16), // Reduced from 20
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6), // Reduced from 8
                  decoration: BoxDecoration(
                    color: pastelGreen,
                    borderRadius: BorderRadius.circular(6), // Reduced from 8
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Colors.green[700],
                    size: 18, // Reduced from 20
                  ),
                ),
                const SizedBox(width: 10), // Reduced from 12
                const Text(
                  'Appointments',
                  style: TextStyle(
                    fontSize: 18, // Reduced from 20
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          _buildAppointmentsList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList() {
    if (_isLoading) {
      return Container(
        height: 150, // Reduced from 200
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: primaryBlue,
                strokeWidth: 3,
              ),
              const SizedBox(height: 12), // Reduced from 16
              Text(
                'Loading appointments...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13, // Reduced from 14
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<List<QueryDocumentSnapshot>>(
      valueListenable: _selectedAppointments,
      builder: (context, appointments, _) {
        if (appointments.isEmpty) {
          return Container(
            height: 150, // Reduced from 200
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), // Reduced from 16
                    decoration: BoxDecoration(
                      color: lightBlue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      size: 36, // Reduced from 48
                      color: primaryBlue.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16
                  const Text(
                    'No appointments scheduled',
                    style: TextStyle(
                      fontSize: 16, // Reduced from 18
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6), // Reduced from 8
                  Text(
                    'Enjoy your free day!',
                    style: TextStyle(
                      fontSize: 13, // Reduced from 14
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12), // Reduced from 16
          child: Column(
            children: appointments.map((appointment) {
              final data = appointment.data() as Map<String, dynamic>;
              return _buildAppointmentCard(appointment, data);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(QueryDocumentSnapshot appointment, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 12, right: 12), // Reduced margins
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced from 16
        border: Border.all(color: lightBlue.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.05),
            blurRadius: 6, // Reduced from 8
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced from 16
            child: Row(
              children: [
                // Enhanced avatar - smaller
                Container(
                  width: 44, // Reduced from 56
                  height: 44, // Reduced from 56
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [lightBlue, lightBlue.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 3, // Reduced from 4
                        offset: const Offset(0, 1), // Reduced from 2
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: primaryBlue,
                    size: 22, // Reduced from 28
                  ),
                ),
                const SizedBox(width: 12), // Reduced from 16

                // Patient info - flexible to prevent overflow
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data['patientName'] ?? 'Unknown Patient',
                        style: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3), // Reduced from 4
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4), // Reduced from 6
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 12, // Reduced from 14
                              color: accentBlue,
                            ),
                          ),
                          const SizedBox(width: 6), // Reduced from 8
                          Flexible(
                            child: Text(
                              data['time'] ?? 'No time',
                              style: TextStyle(
                                fontSize: 12, // Reduced from 14
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Complete tick icon - compact
                Container(
                  width: 36, // Fixed width to prevent overflow
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _updateAppointmentStatus(appointment.id, AppointmentStatus.completed),
                      child: Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.green[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}