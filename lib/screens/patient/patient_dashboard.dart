// lib/screens/patient/patient_dashboard.dart

import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'home_screen.dart';
import 'package:flutter/services.dart';
import 'appointments_screen.dart';
import 'prescriptions_screen.dart';
import 'reminders_screen.dart';
import 'notifications_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/utils/appointment_status.dart';

import 'package:smartcare_app/screens/patient/rate_doctor_dialog.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _unreadNotifications = 0; // New state variable for notification count

  final User? currentUser = FirebaseAuth.instance.currentUser;

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color darkBlue = const Color(0xFF1976D2);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color glassWhite = Colors.white.withOpacity(0.95);

  final List<Widget> _screens = [
    const HomeScreen(),
    const AppointmentsScreen(),
    const PrescriptionsScreen(),
    const RemindersScreen(),
    const NotificationsScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {
      'icon': Icons.home_rounded,
      'activeIcon': Icons.home,
      'label': 'Home',
      'color': Color(0xFF4CAF50),
    },
    {
      'icon': Icons.calendar_month_rounded,
      'activeIcon': Icons.calendar_month,
      'label': 'Appointments',
      'color': Color(0xFF2196F3),
    },
    {
      'icon': Icons.receipt_long_rounded,
      'activeIcon': Icons.receipt_long,
      'label': 'Prescriptions',
      'color': Color(0xFFFF9800),
    },
    {
      'icon': Icons.notifications_rounded,
      'activeIcon': Icons.notifications,
      'label': 'Notifications',
      'color': Color(0xFFE91E63),
    },
    {
      'icon': Icons.access_alarms,
      'activeIcon': Icons.access_alarms,
      'label': 'Reminders',
      'color': Color(0xFF9C27B0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCompletedAppointments();
      _listenForUnreadNotifications(); // Start listening for notifications
    });
  }

  void _checkForCompletedAppointments() async {
    if (currentUser == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('patientId', isEqualTo: currentUser!.uid)
        .where('status', isEqualTo: AppointmentStatus.completed.toShortString())
        .where('rated', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final appointmentDoc = querySnapshot.docs.first;
      final appointmentData = appointmentDoc.data() as Map<String, dynamic>;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return RateDoctorDialog(
            appointmentId: appointmentDoc.id,
            doctorId: appointmentData['doctorId'] as String,
            doctorName: appointmentData['doctorName'] as String,
          );
        },
      );
    }
  }

  // New method to listen for unread notifications
  void _listenForUnreadNotifications() {
    if (currentUser == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('patientId', isEqualTo: currentUser!.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadNotifications = snapshot.docs.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });

      _animationController.reset();
      _animationController.forward();

      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  backgroundColor.withOpacity(0.8),
                ],
              ),
            ),
          ),
          _screens[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.15),
              blurRadius: 25,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                _navItems.length,
                    (index) => _buildNavItem(index),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];
    final itemColor = item['color'] as Color;
    final isNotificationTab = item['label'] == 'Notifications';

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 60,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 45 : 35,
                  height: isSelected ? 30 : 25,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? itemColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: isSelected ? _scaleAnimation :
                        const AlwaysStoppedAnimation(1.0),
                        child: Icon(
                          isSelected ? item['activeIcon'] : item['icon'],
                          size: isSelected ? 24 : 20,
                          color: isSelected ? itemColor : Colors.grey[600],
                        ),
                      ),
                      if (isNotificationTab && _unreadNotifications > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              _unreadNotifications.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(top: 2),
                  width: isSelected ? 6 : 0,
                  height: isSelected ? 6 : 0,
                  decoration: BoxDecoration(
                    color: itemColor,
                    shape: BoxShape.circle,
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