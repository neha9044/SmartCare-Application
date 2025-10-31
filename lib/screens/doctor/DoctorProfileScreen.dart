// lib/screens/doctor/DoctorProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/services/auth_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  _DoctorProfileScreenState createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final AuthService _authService = AuthService();
  // UPDATED: Now stores schedule as a map for display
  Map<String, List<String>> _schedule = {};
  bool _isLoading = true;

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1976D2);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;

  final List<String> _daysOfWeek = const [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;

        // Handle new map format or old list format migration for display
        final dynamic fetchedSlots = data['availableSlots'];
        if (fetchedSlots is Map<String, dynamic>) {
          setState(() {
            _schedule = fetchedSlots.map((key, value) => MapEntry(key, List<String>.from(value)));
            _isLoading = false;
          });
        } else if (fetchedSlots is List<dynamic>) {
          // Simple migration logic for display: apply old list to Mon-Fri if it exists
          _schedule.clear();
          final List<String> oldSlots = List<String>.from(fetchedSlots.map((e) => e.toString()));
          for (var day in _daysOfWeek) {
            if (day != 'Sunday' && day != 'Saturday' && oldSlots.isNotEmpty) {
              _schedule[day] = oldSlots;
            } else {
              _schedule[day] = [];
            }
          }
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching doctor data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // REMOVED: _saveTimeSlots() and _editTimeSlotsDialog()

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return Center(
              child: CircularProgressIndicator(color: primaryBlue),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data."));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Doctor profile not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'N/A';
          final String email = data['email'] ?? 'N/A';
          final String phone = data['phone'] ?? 'N/A';
          final String specialty = data['specialty'] ?? 'N/A';
          final String license = data['licenseNumber'] ?? 'N/A';
          final String experience = data['experience'] ?? 'N/A';
          final String qualification = data['qualification'] ?? 'N/A';
          final String location = data['location'] ?? 'N/A';
          final String clinicName = data['clinicName'] ?? 'N/A';
          final String consultationFees = data['consultationFees']?.toString() ?? 'N/A';
          final String profileImageUrl = data['profileImageUrl'] ?? '';

          return Column(
            children: [
              // Header Section with Profile
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryBlue, darkBlue],
                  ),
                ),
                child: Column(
                  children: [
                    // Custom App Bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          padding: EdgeInsets.zero,
                        ),
                        const Expanded(
                          child: Text(
                            'My Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        // REMOVED: Edit button was here
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Profile Info
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl.isEmpty
                                ? Icon(Icons.person, size: 32, color: primaryBlue)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dr. $name",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                specialty,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$experience Experience',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Quick Info Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.attach_money,
                              title: 'Fee',
                              value: '₹$consultationFees',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.school,
                              title: 'Qualification',
                              value: qualification,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickInfoCard(
                              icon: Icons.badge,
                              title: 'License',
                              value: license,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Contact & Clinic Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCompactInfoRow(Icons.email, 'Email', email),
                            const SizedBox(height: 8),
                            _buildCompactInfoRow(Icons.phone, 'Phone', phone),
                            const SizedBox(height: 8),
                            _buildCompactInfoRow(Icons.local_hospital, 'Clinic', clinicName),
                            const SizedBox(height: 8),
                            _buildCompactInfoRow(Icons.location_on, 'Location', location),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time Slots Section (Now a read-only summary)
                      _buildTimeSlotsSection(),
                      const Spacer(),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.signOut();
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          },
                          icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                          label: const Text(
                            "Log Out",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    final List<Widget> dayWidgets = [];
    final List<String> sortedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (var day in sortedDays) {
      final slots = _schedule[day] ?? [];
      final isAvailable = slots.isNotEmpty;

      dayWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  '$day:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isAvailable ? darkBlue : Colors.grey[600],
                  ),
                ),
              ),
              Expanded(
                child: isAvailable
                    ? Wrap(
                  spacing: 6.0,
                  runSpacing: 3.0,
                  children: slots.map((slot) =>
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryBlue.withOpacity(0.3)),
                        ),
                        child: Text(
                          slot,
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 10,
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
                    color: Colors.red[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }


    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Schedule (Set on Dashboard)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          ...dayWidgets,
        ],
      ),
    );
  }

  Widget _buildQuickInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryBlue, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: primaryBlue, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}