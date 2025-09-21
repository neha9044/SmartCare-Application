// book_appointment_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:smartcare_app/utils/appointment_status.dart';
import 'package:intl/intl.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;

  const BookAppointmentScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  _BookAppointmentScreenState createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AuthService _authService = AuthService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  DateTime _currentMonth = DateTime.now();

  List<String> _availableSlots = []; // New variable to hold fetched slots

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color darkBlue = const Color(0xFF1976D2);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _fetchDoctorTimeSlots(); // Fetch slots when the screen initializes
  }

  // New helper function to expand time slots
  List<String> _expandTimeSlots(List<String> timeRanges) {
    List<String> expandedSlots = [];
    final format = DateFormat("hh:mm a");

    for (String range in timeRanges) {
      if (range.contains(' - ')) {
        final parts = range.split(' - ');
        if (parts.length == 2) {
          try {
            DateTime start = format.parse(parts[0]);
            DateTime end = format.parse(parts[1]);

            // Add slots until the hour before the end time
            while (start.isBefore(end)) {
              expandedSlots.add(format.format(start));
              start = start.add(const Duration(hours: 1));
            }
            // Add the end time itself
            expandedSlots.add(format.format(end));
          } catch (e) {
            print('Error parsing time range: $e');
            // If parsing fails, just add the original string as a fallback
            expandedSlots.add(range);
          }
        }
      } else {
        // If the slot is not a range, add it directly
        expandedSlots.add(range);
      }
    }
    return expandedSlots;
  }

  Future<void> _fetchDoctorTimeSlots() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctor.id)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final List<String> fetchedRanges = List<String>.from(data['availableSlots'] ?? []);
        setState(() {
          _availableSlots = _expandTimeSlots(fetchedRanges);
        });
      }
    } catch (e) {
      print("Error fetching time slots: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = '';
    if (widget.doctor.name.isNotEmpty) {
      List<String> nameParts = widget.doctor.name.split(' ');
      if (nameParts.isNotEmpty) {
        initials += nameParts.first[0];
        if (nameParts.length > 1) {
          initials += nameParts[1][0];
        }
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryBlue.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(
                        initials.toUpperCase(),
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${widget.doctor.name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkBlue,
                          ),
                        ),
                        Text(
                          widget.doctor.specialization,
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${widget.doctor.consultationFee.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Date',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkBlue,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _currentMonth.month > DateTime.now().month ||
                                    _currentMonth.year > DateTime.now().year ? () {
                                  setState(() {
                                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                                  });
                                } : null,
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: (_currentMonth.month > DateTime.now().month ||
                                      _currentMonth.year > DateTime.now().year)
                                      ? primaryBlue : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _canGoToNextMonth() ? () {
                                  setState(() {
                                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                                  });
                                } : null,
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: _canGoToNextMonth() ? primaryBlue : Colors.grey[400],
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                  .map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                            Expanded(child: _buildCalendarGrid()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Time Slots',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _availableSlots.isEmpty
                          ? const Center(child: Text('No slots available.', style: TextStyle(fontStyle: FontStyle.italic)))
                          : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _availableSlots.map((slot) { // Use the fetched slots
                          bool isSelected = _selectedTimeSlot == slot;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTimeSlot = slot;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                  colors: [primaryBlue, darkBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                                    : null,
                                color: isSelected ? null : lightBlue,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? primaryBlue : primaryBlue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTimeSlot != null ? () {
                  _showConfirmationDialog();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  disabledBackgroundColor: Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _selectedTimeSlot != null ? 6 : 0,
                  shadowColor: primaryBlue.withOpacity(0.3),
                ),
                child: Text(
                  'Confirm Booking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTimeSlot != null ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canGoToNextMonth() {
    DateTime nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    DateTime maxMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
    return nextMonth.isBefore(maxMonth) || nextMonth.isAtSameMomentAs(maxMonth);
  }

  Widget _buildCalendarGrid() {
    DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    DateTime lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    int firstWeekday = firstDayOfMonth.weekday % 7;

    List<DateTime> days = [];
    for (int i = 0; i < firstWeekday; i++) {
      days.add(DateTime(0));
    }
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, day));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        DateTime date = days[index];
        if (date.year == 0) {
          return const SizedBox();
        }

        bool isToday = _isSameDay(date, DateTime.now());
        bool isSelected = _isSameDay(date, _selectedDate);
        bool isPastDate = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
        bool isSelectable = !isPastDate;

        return GestureDetector(
          onTap: isSelectable ? () {
            setState(() {
              _selectedDate = date;
              _selectedTimeSlot = null;
            });
          } : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                colors: [primaryBlue, darkBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected
                  ? null
                  : isToday
                  ? lightBlue
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: primaryBlue, width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isToday
                      ? primaryBlue
                      : isPastDate
                      ? Colors.grey[400]
                      : darkBlue,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.event_available,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Confirm Appointment?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Do you want to confirm this appointment?',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${widget.doctor.name}', style: const TextStyle(fontSize: 12)),
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 12)),
                    Text('$_selectedTimeSlot', style: const TextStyle(fontSize: 12)),
                    Text('₹${widget.doctor.consultationFee.toInt()}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showBookingConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showBookingConfirmation() async {
    final patientId = _authService.currentUser?.uid;
    if (patientId == null) return;

    try {
      final patientData = await _authService.getPatientData(patientId);
      final patientName = patientData['name'] as String? ?? 'Patient';

      await _authService.saveAppointment(
        doctorId: widget.doctor.id,
        doctorName: widget.doctor.name,
        doctorSpecialty: widget.doctor.specialization,
        patientId: patientId,
        patientName: patientName,
        date: _selectedDate,
        time: _selectedTimeSlot!,
        status: AppointmentStatus.pending.toShortString(),
      );

      Random random = Random();
      int queueNumber = random.nextInt(5) + 1;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
                SizedBox(width: 8),
                Text('Booking Confirmed!', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your appointment has been successfully booked.', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${widget.doctor.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at $_selectedTimeSlot', style: const TextStyle(fontSize: 12)),
                      Text('Fee: ₹${widget.doctor.consultationFee.toInt()}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('Queue number: $queueNumber', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to book appointment. Please try again.')),
      );
    }
  }
}