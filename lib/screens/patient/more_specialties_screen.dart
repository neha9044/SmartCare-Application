// lib/screens/patient/more_specialties_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/widgets/doctor_card.dart';
import 'package:smartcare_app/screens/patient/doctor_profile_screen.dart';
import 'package:smartcare_app/screens/patient/book_appointment_screen.dart';

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

class _MoreSpecialtiesScreenState extends State<MoreSpecialtiesScreen>
    with SingleTickerProviderStateMixin {
  String _selectedSpecialty = 'All';
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoadingDoctors = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();

  final Color primaryBlue = const Color(0xFF2196F3);
  final Color darkBlue = const Color(0xFF1565C0);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color accentColor = const Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fetchDoctorsBySpecialty(_selectedSpecialty);
    _animationController.forward();

    _searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = List.from(_doctors);
      } else {
        _filteredDoctors = _doctors.where((doctor) {
          return doctor.name.toLowerCase().contains(query) ||
              doctor.specialization.toLowerCase().contains(query) ||
              doctor.hospital.toLowerCase().contains(query) ||
              doctor.location.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchDoctorsBySpecialty(String specialty) async {
    setState(() {
      _isLoadingDoctors = true;
      _doctors = [];
      _filteredDoctors = [];
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
          availableSlots: (data['availableSlots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              ['9:00 AM', '10:00 AM', '11:00 AM'],
          consultationFee: (data['consultationFees'] as num?)?.toDouble() ?? 500.0,
          isAvailableToday: data['isAvailableToday'] ?? true,
          about: data['about'] ?? 'Experienced medical professional.',
          qualifications: (data['qualification'] as String?)
              ?.split(',')
              .map((q) => q.trim())
              .toList() ??
              [],
        ));
      }

      setState(() {
        _doctors = fetchedDoctors;
        _filteredDoctors = fetchedDoctors;
      });
    } catch (e) {
      print('Error fetching doctors: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading doctors'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
    _searchController.clear(); // Clear search when specialty changes
    _fetchDoctorsBySpecialty(specialty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Find Doctor For Your Problem',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Specialty Filter Chips
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: primaryBlue,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.specializations.length,
              itemBuilder: (context, index) {
                final specialty = widget.specializations[index];
                final isSelected = _selectedSpecialty == specialty;
                final config = widget.specialtyConfig[specialty];

                return GestureDetector(
                  onTap: () => _onSpecialtySelected(specialty),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 16),
                    width: 70,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.white.withOpacity(0.9)],
                      )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryBlue.withOpacity(0.1)
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            config?['icon'] ?? Icons.local_hospital,
                            color: isSelected ? primaryBlue : Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          specialty,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? primaryBlue : Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterDoctors(),
              decoration: InputDecoration(
                hintText: 'Search doctors, specialties...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: primaryBlue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterDoctors();
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Doctor List
          Expanded(
            child: _isLoadingDoctors
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Finding the best doctors for you...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : _filteredDoctors.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.search_off,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No doctors found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching with different keywords',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index];
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 1.0),
                      ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  )),
                  child: SimpleDoctorCard(
                    doctor: doctor,
                    onBookPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BookAppointmentScreen(doctor: doctor),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleDoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onBookPressed;

  const SimpleDoctorCard({
    Key? key,
    required this.doctor,
    required this.onBookPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryBlue = const Color(0xFF2196F3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primaryBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: doctor.imageUrl.isNotEmpty
                  ? Image.network(
                doctor.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildGradientAvatar(),
              )
                  : _buildGradientAvatar(),
            ),
          ),
          const SizedBox(width: 12),
          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.specialization,
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${doctor.rating}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      ' (${doctor.reviewCount})',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Book Now Button
          ElevatedButton(
            onPressed: doctor.isAvailableToday ? onBookPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: doctor.isAvailableToday
                  ? primaryBlue
                  : Colors.grey[400],
              foregroundColor: Colors.white,
              elevation: doctor.isAvailableToday ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2196F3),
            const Color(0xFF00BCD4),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}