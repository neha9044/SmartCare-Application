import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'home_screen.dart';
import 'appointments_screen.dart';
import 'prescriptions_screen.dart';
import 'reminders_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AppointmentsScreen(),
    const PrescriptionsScreen(),
    const RemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Set scaffold background to transparent
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.glassmorphismGradient, // Apply the gradient to the container
        ),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.white, // Changed selected item color for better contrast
        unselectedItemColor: Colors.white.withOpacity(0.5), // Changed unselected item color
        backgroundColor: Colors.white.withOpacity(0.1), // Glassmorphic effect on navbar
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
        ],
      ),
    );
  }
}