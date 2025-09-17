import 'package:flutter/material.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

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

  @override
  Widget build(BuildContext context) {
    // Corrected logic to safely get initials
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
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryColor,
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.doctor.specialization,
                          style: const TextStyle(color: AppColors.primaryColor, fontSize: 14),
                        ),
                        Text(
                          '₹${widget.doctor.consultationFee}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  DateTime date = DateTime.now().add(Duration(days: index));
                  bool isSelected = _selectedDate.day == date.day;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        _selectedTimeSlot = null;
                      });
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.darkGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1],
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.darkGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Time Slots',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              children: widget.doctor.availableSlots.map((slot) {
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
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryColor : AppColors.lightGrey,
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTimeSlot != null ? () {
                  _showBookingConfirmation();
                } : null,
                child: const Text('Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingConfirmation() async {
    // 1. Get current patient's ID and name
    final patientId = _authService.currentUser?.uid;
    if (patientId == null) {
      // Handle the case where the patient is not logged in
      return;
    }

    try {
      final patientData = await _authService.getPatientData(patientId);
      final patientName = patientData['name'] as String? ?? 'Patient';

      // 2. Save the appointment to Firestore
      await _authService.saveAppointment(
        doctorId: widget.doctor.id,
        patientId: patientId,
        patientName: patientName,
        date: _selectedDate,
        time: _selectedTimeSlot!,
      );

      // 3. Show a confirmation dialog
      Random random = Random();
      int queueNumber = random.nextInt(5) + 1;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppColors.green, size: 28),
                SizedBox(width: 8),
                Text('Booking Confirmed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your appointment has been successfully booked.'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Appointment Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Doctor: ${widget.doctor.name}'),
                      Text('Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      Text('Time: $_selectedTimeSlot'),
                      Text('Fee: ₹${widget.doctor.consultationFee}'),
                      const SizedBox(height: 8),
                      Text('You are number $queueNumber in the queue.', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book appointment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}