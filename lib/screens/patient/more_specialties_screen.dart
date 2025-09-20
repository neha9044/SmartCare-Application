// lib/screens/patient/more_specialties_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/widgets/doctor_card.dart';
import 'package:smartcare_app/screens/patient/doctor_profile_screen.dart';
import 'package:smartcare_app/screens/patient/book_appointment_screen.dart'; // Add this import

class MoreSpecialtiesScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> specialtyConfig;
  final List<String> specializations;

  const MoreSpecialtiesScreen({
    Key? key,
    required this.specialtyConfig,
    required this.specializations,
  }) : super(key: key);

  @override
  _MoreSpecialtiesScreenState createState() => _MoreSpecialtiesScreenState();
}

class _MoreSpecialtiesScreenState extends State<MoreSpecialtiesScreen> {
  String _selectedSpecialty = 'All';
  List<Doctor> _doctors = [];
  bool _isLoadingDoctors = false;

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _fetchDoctorsBySpecialty(_selectedSpecialty);
  }

  Future<void> _fetchDoctorsBySpecialty(String specialty) async {
    setState(() {
      _isLoadingDoctors = true;
      _doctors = [];
    });

    try {
      QuerySnapshot snapshot;
      if (specialty == 'All') {
        snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('doctors')
            .where('specialty', isEqualTo: specialty)
            .get();
      }

      final List<Doctor> fetchedDoctors = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        fetchedDoctors.add(Doctor(
          id: doc.id,
          name: data['name'] ?? 'N/A',
          specialization: data['specialty'] ?? 'N/A',
          hospital: data['clinicName'] ?? 'N/A',
          location: data['location'] ?? 'N/A',
          rating: (data['rating'] as num?)?.toDouble() ?? 4.0,
          reviewCount: data['reviewCount'] ?? 0,
          experience: data['experience'] ?? 'N/A',
          imageUrl: data['profileImage'] ?? '',
          availableSlots: (data['availableSlots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['9:00 AM', '10:00 AM', '11:00 AM'],
          consultationFee: (data['consultationFees'] as num?)?.toDouble() ?? 500.0,
          isAvailableToday: data['isAvailableToday'] ?? true,
          about: data['about'] ?? 'Experienced medical professional.',
          qualifications: (data['qualification'] as String?)?.split(',').map((q) => q.trim()).toList() ?? [],
        ));
      }

      setState(() {
        _doctors = fetchedDoctors;
      });
    } catch (e) {
      print('Error fetching doctors: $e');
    } finally {
      setState(() {
        _isLoadingDoctors = false;
      });
    }
  }

  void _onSpecialtySelected(String specialty) {
    setState(() {
      _selectedSpecialty = specialty;
    });
    _fetchDoctorsBySpecialty(specialty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Specialists', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Left side: Specialty categories
          Container(
            width: 100, // Made more compact
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: ListView.builder(
              itemCount: widget.specializations.length,
              itemBuilder: (context, index) {
                final specialty = widget.specializations[index];
                final isSelected = _selectedSpecialty == specialty;
                final config = widget.specialtyConfig[specialty];

                return GestureDetector(
                  onTap: () => _onSpecialtySelected(specialty),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? primaryBlue : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          config?['icon'] ?? Icons.local_hospital,
                          color: isSelected ? primaryBlue : Colors.grey[700],
                          size: 20, // Reduced icon size
                        ),
                        const SizedBox(height: 6), // Reduced space
                        Text(
                          specialty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10, // Reduced font size
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? primaryBlue : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Right side: Doctor list
          Expanded(
            child: _isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : _doctors.isEmpty
                ? const Center(
              child: Text(
                "No doctors found for this specialty.",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(left: 8, right: 16, top: 16),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return DoctorCard(
                  doctor: doctor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentScreen(doctor: doctor),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}