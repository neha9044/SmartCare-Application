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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.lightGrey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Prescriptions'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Reminders'),
        ],
      ),
    );
  }
}