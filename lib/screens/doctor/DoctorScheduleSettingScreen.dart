// lib/screens/doctor/DoctorScheduleSettingScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:table_calendar/table_calendar.dart'; // NEW IMPORT

class DoctorScheduleSettingScreen extends StatefulWidget {
  final String doctorId;

  const DoctorScheduleSettingScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorScheduleSettingScreenState createState() => _DoctorScheduleSettingScreenState();
}

class _DoctorScheduleSettingScreenState extends State<DoctorScheduleSettingScreen> {
  // Map where key is the day name (e.g., 'Monday') and value is a list of time ranges (e.g., ['9:00 AM - 1:00 PM', '3:00 PM - 5:00 PM'])
  Map<String, List<String>> _schedule = {};
  bool _isLoading = true;
  final List<String> _daysOfWeek = const [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  // NEW STATE FOR CALENDAR
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
    _fetchDoctorSchedule();
    _selectedDay = _focusedDay; // Initialize selected day
  }

  void _initializeSchedule() {
    for (var day in _daysOfWeek) {
      _schedule[day] = [];
    }
  }

  Future<void> _fetchDoctorSchedule() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        final dynamic fetchedSlots = data['availableSlots'];
        if (fetchedSlots is Map<String, dynamic>) {
          // New map format
          setState(() {
            _schedule = fetchedSlots.map((key, value) => MapEntry(key, List<String>.from(value)));
            _isLoading = false;
          });
          // Ensure all 7 days are present after fetch
          for (var day in _daysOfWeek) {
            if (!_schedule.containsKey(day)) {
              _schedule[day] = [];
            }
          }
        } else if (fetchedSlots is List<dynamic>) {
          // Old list format migration
          final List<String> oldSlots = List<String>.from(fetchedSlots.map((e) => e.toString()));
          if (oldSlots.isNotEmpty) {
            _schedule.clear();
            for (var day in _daysOfWeek) {
              if (day != 'Sunday' && day != 'Saturday') {
                _schedule[day] = oldSlots;
              } else {
                _schedule[day] = [];
              }
            }
            await _saveSchedule();
          }
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching doctor schedule: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSchedule() async {
    try {
      // Remove empty days before saving to keep Firestore clean
      final Map<String, List<String>> scheduleToSave = {};
      _schedule.forEach((key, value) {
        if (value.isNotEmpty) {
          scheduleToSave[key] = value;
        }
      });

      await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).update({
        'availableSlots': scheduleToSave,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully!'),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save schedule.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editDayScheduleDialog(String day) {
    List<String> tempSlots = List.from(_schedule[day] ?? []);
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Set Availability for $day", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Ranges (e.g., 9:00 AM - 1:00 PM)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: tempSlots.map((slot) {
                        return Chip(
                          label: Text(slot, style: const TextStyle(fontSize: 11)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setDialogState(() {
                              tempSlots.remove(slot);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: "Add Slot Range",
                              hintText: "9:00 AM - 1:00 PM",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setDialogState(() {
                                  tempSlots.add(value.trim());
                                  controller.clear();
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF4CAF50)),
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              setDialogState(() {
                                tempSlots.add(controller.text.trim());
                                controller.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          tempSlots.clear();
                        });
                      },
                      icon: const Icon(Icons.delete_forever, color: AppColors.red),
                      label: const Text('Mark as Unavailable (Holiday)', style: TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _schedule[day] = tempSlots;
                    });
                    _saveSchedule();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // After dialog closes, ensure the selected day's info is refreshed
      setState(() {});
    });
  }


  // NEW METHOD: Handle day selection on the calendar
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!_isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      // Automatically open the edit dialog for the day of the week selected
      // Modulo 7 maps the 1-7 (Mon-Sun) to the 0-6 (Sun-Sat) list index
      final selectedDayName = _daysOfWeek[selectedDay.weekday % 7];
      _editDayScheduleDialog(selectedDayName);
    }
  }


  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextYear = DateTime(now.year + 1, now.month, now.day);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Set Availability', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoMessage(),
          const SizedBox(height: 16),
          // MODIFIED: Replaced the ListView of DayTiles with TableCalendar
          _buildCalendarSection(now, nextYear),
          const SizedBox(height: 16),
          // NEW: Display the current RECURRING schedule for the selected day of the week
          _buildSelectedDaySchedule(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Select a date on the calendar to set the RECURRING time ranges for that specific day of the week. This will affect all future instances of that day.',
              style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
            ),
          ),
        ],
      ),
    );
  }

  // NEW WIDGET: Calendar Section
  Widget _buildCalendarSection(DateTime now, DateTime nextYear) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(now.year, now.month - 3, 1), // Allow some past navigation
        lastDay: nextYear,
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        calendarFormat: CalendarFormat.month,
        availableGestures: AvailableGestures.horizontalSwipe,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primaryColor),
          rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primaryColor),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w700,
          ),
          weekendStyle: TextStyle(
            color: AppColors.primaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
          weekendTextStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        eventLoader: (day) => [], // No events for setting screen
      ),
    );
  }

  // NEW WIDGET: Display Schedule for Selected Day's Recurring Schedule
  Widget _buildSelectedDaySchedule() {
    final selectedDay = _selectedDay ?? DateTime.now();
    final selectedDayName = _daysOfWeek[selectedDay.weekday % 7];
    final daySlots = _schedule[selectedDayName] ?? [];
    final isAvailable = daySlots.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recurring Schedule for $selectedDayName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isAvailable ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: isAvailable ? AppColors.green : AppColors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isAvailable
                    ? Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: daySlots.map((slot) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                  ).toList(),
                )
                    : Text(
                  'Unavailable/Holiday',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _editDayScheduleDialog(selectedDayName),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Recurring Schedule'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for TableCalendar compatibility
  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}