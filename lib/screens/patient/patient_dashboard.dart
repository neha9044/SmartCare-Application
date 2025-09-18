import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'home_screen.dart';
import 'package:flutter/services.dart';
import 'appointments_screen.dart';
import 'prescriptions_screen.dart';
import 'reminders_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Healthcare theme colors
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
  ];

  // Navigation items with enhanced styling
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
      'label': 'Reminders',
      'color': Color(0xFFE91E63),
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

      // Trigger animation for selection
      _animationController.reset();
      _animationController.forward();

      // Add haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true, // Allows body to extend behind the bottom navigation
      body: Stack(
        children: [
          // Background gradient
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
          // Main content
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
            height: 75,
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

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          height: 75,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with animated container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 50 : 40,
                  height: isSelected ? 35 : 30,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? itemColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ScaleTransition(
                    scale: isSelected ? _scaleAnimation :
                    const AlwaysStoppedAnimation(1.0),
                    child: Icon(
                      isSelected ? item['activeIcon'] : item['icon'],
                      size: isSelected ? 26 : 22,
                      color: isSelected ? itemColor : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Label with animation
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: isSelected ? 11 : 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? itemColor : Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                  child: Text(
                    item['label'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Active indicator dot
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