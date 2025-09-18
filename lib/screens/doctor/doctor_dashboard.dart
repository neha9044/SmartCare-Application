import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/services/auth_service.dart';
import 'package:smartcare_app/screens/doctor/PrescriptionScreen.dart';
import 'package:smartcare_app/screens/doctor/historyscreen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String _doctorName = 'Doctor';
  String? _currentDoctorId;
  int _queueCount = 0;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Healthcare theme colors
  final Color primaryBlue = const Color(0xFF2196F3);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color darkBlue = const Color(0xFF1976D2);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _currentDoctorId = _authService.currentUser?.uid;
    _setupAnimations();
    _fetchAndSetData();
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

  Future<void> _fetchAndSetData() async {
    await _fetchDoctorName();
  }

  Future<void> _fetchDoctorName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final String? fullName = doc.data()!['name'];
        if (fullName != null && fullName.isNotEmpty) {
          final List<String> nameParts = fullName.split(' ');
          setState(() {
            _doctorName = nameParts.first;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildSliverHeader(),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        _buildQueueManagementCard(),
                        const SizedBox(height: 20),
                        _buildDashboardCards(),
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

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hello ',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[700],
                              ),
                            ),
                            TextSpan(
                              text: 'Dr. $_doctorName',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome to your dashboard.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLocationSection(),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildHeaderIconButton(
                      Icons.chat_bubble_outline_rounded,
                      const Color(0xFFFF6B9D),
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chatbot coming soon!')),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildHeaderIconButton(
                      Icons.person_outline_rounded,
                      primaryBlue,
                          () {
                        // TODO: Navigate to doctor profile screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Doctor Profile Screen coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildLocationSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.location_on_rounded,
            color: primaryBlue,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Location',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Text(
                    'Mumbai, India',
                    style: TextStyle(
                      fontSize: 14,
                      color: darkBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Queue Management",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3498DB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$_queueCount patients waiting",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "Upcoming Appointments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildAppointmentsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildDashboardCard(
            context: context,
            title: "Chat with Patients",
            subtitle: "Real-time communication",
            icon: Icons.chat_bubble_outline,
            color: const Color(0xFF2C3E50),
            route: '/patientList',
          ),
          _buildDashboardCard(
            context: context,
            title: "Prescriptions",
            subtitle: "Manage and send prescriptions",
            icon: Icons.medical_services_outlined,
            color: const Color(0xFF34495E),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrescriptionScreen(onSave: (record) {})),
              );
            },
          ),
          _buildDashboardCard(
            context: context,
            title: "History & Records",
            subtitle: "View all past prescriptions",
            icon: Icons.folder_open,
            color: const Color(0xFF95A5A6),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen(history: [])),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? route,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap ??
                () {
              if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: _currentDoctorId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading appointments.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No appointments booked yet.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          );
        }

        final appointments = snapshot.data!.docs;
        _queueCount = appointments.length;

        // Rebuild the parent widget to update the queue count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {});
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            final appointmentData = appointment.data() as Map<String, dynamic>;
            final patientName = appointmentData['patientName'] ?? 'Unknown Patient';
            final time = appointmentData['time'] ?? 'N/A';
            final date = (appointmentData['date'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF3498DB),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Time: $time | Date: ${date.day}/${date.month}/${date.year}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navigate to patient profile or start chat
                },
              ),
            );
          },
        );
      },
    );
  }
}