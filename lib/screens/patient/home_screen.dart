// File: patient/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/patient/doctor_profile_screen.dart';
import 'package:smartcare_app/screens/patient/profile_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:smartcare_app/services/location_service.dart';
import 'book_appointment_screen.dart';
import 'more_specialties_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _searchOptions = const [
    'doctors...',
    'clinics...',
    'pharmacies...',
  ];
  String _currentSearchOption = 'doctors...';
  Timer? _typewriterTimer;

  String _patientName = 'Patient';
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;

  String? _selectedLocation;
  String _selectedSpecialization = 'All';
  List<String> _locations = ['All'];
  List<String> _specializations = ['All'];
  Map<String, int> _specializationCounts = {};

  String _currentLocation = 'Fetching location...';
  Position? _currentPosition;
  final LocationService _locationService = LocationService();

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

  // Comprehensive specialty configuration with healthcare colors and icons
  final Map<String, Map<String, dynamic>> _specialtyConfig = {
    'Cardiologist': {
      'icon': Icons.favorite,
      'color': const Color(0xFFE57373),
      'lightColor': const Color(0xFFFFEBEE),
    },
    'Pediatrician': {
      'icon': Icons.child_care,
      'color': const Color(0xFF64B5F6),
      'lightColor': const Color(0xFFE3F2FD),
    },
    'Dermatologist': {
      'icon': Icons.face,
      'color': const Color(0xFFBA68C8),
      'lightColor': const Color(0xFFF3E5F5),
    },
    'Neurologist': {
      'icon': Icons.psychology,
      'color': const Color(0xFF4DB6AC),
      'lightColor': const Color(0xFFE0F2F1),
    },
    'Orthopedist': {
      'icon': Icons.accessibility_new,
      'color': const Color(0xFFFFB74D),
      'lightColor': const Color(0xFFFFF3E0),
    },
    'Dentist': {
      'icon': Icons.medical_services,
      'color': const Color(0xFF81C784),
      'lightColor': const Color(0xFFE8F5E8),
    },
    'Gynecologist': {
      'icon': Icons.female,
      'color': const Color(0xFFF06292),
      'lightColor': const Color(0xFFFCE4EC),
    },
    'Psychiatrist': {
      'icon': Icons.psychology_alt,
      'color': const Color(0xFF9575CD),
      'lightColor': const Color(0xFFEDE7F6),
    },
    'Ophthalmologist': {
      'icon': Icons.visibility,
      'color': const Color(0xFF4FC3F7),
      'lightColor': const Color(0xFFE1F5FE),
    },
    'General Physician': {
      'icon': Icons.local_hospital,
      'color': const Color(0xFF66BB6A),
      'lightColor': const Color(0xFFE8F5E8),
    },
    'Endocrinologist': {
      'icon': Icons.science,
      'color': const Color(0xFF7CB342),
      'lightColor': const Color(0xFFF1F8E9),
    },
    'Urologist': {
      'icon': Icons.medical_information,
      'color': const Color(0xFF673AB7),
      'lightColor': const Color(0xFFEDE7F6),
    },
    'Gastroenterologist': {
      'icon': Icons.healing,
      'color': const Color(0xFFFF8A65),
      'lightColor': const Color(0xFFFFF3E0),
    },
    'Oncologist': {
      'icon': Icons.biotech,
      'color': const Color(0xFFAD1457),
      'lightColor': const Color(0xFFFCE4EC),
    },
    'Rheumatologist': {
      'icon': Icons.accessibility,
      'color': const Color(0xFF8D6E63),
      'lightColor': const Color(0xFFEFEBE9),
    },
    'Pulmonologist': {
      'icon': Icons.air,
      'color': const Color(0xFF26C6DA),
      'lightColor': const Color(0xFFE0F7FA),
    },
    'Nephrologist': {
      'icon': Icons.water_drop,
      'color': const Color(0xFF42A5F5),
      'lightColor': const Color(0xFFE3F2FD),
    },
    'Radiologist': {
      'icon': Icons.radio_button_checked,
      'color': const Color(0xFF8E24AA),
      'lightColor': const Color(0xFFF3E5F5),
    },
    'Anesthesiologist': {
      'icon': Icons.local_hospital,
      'color': const Color(0xFF5C6BC0),
      'lightColor': const Color(0xFFE8EAF6),
    },
    'Pathologist': {
      'icon': Icons.biotech,
      'color': const Color(0xFF26A69A),
      'lightColor': const Color(0xFFE0F2F1),
    },
    'Surgeon': {
      'icon': Icons.content_cut,
      'color': const Color(0xFFEF5350),
      'lightColor': const Color(0xFFFFEBEE),
    },
    'ENT Specialist': {
      'icon': Icons.hearing,
      'color': const Color(0xFFAB47BC),
      'lightColor': const Color(0xFFF3E5F5),
    },
    'Allergist': {
      'icon': Icons.local_florist,
      'color': const Color(0xFF66BB6A),
      'lightColor': const Color(0xFFE8F5E8),
    },
    'Hematologist': {
      'icon': Icons.opacity,
      'color': const Color(0xFFEC407A),
      'lightColor': const Color(0xFFFCE4EC),
    },
    'Infectious Disease': {
      'icon': Icons.coronavirus,
      'color': const Color(0xFFFF7043),
      'lightColor': const Color(0xFFFFF3E0),
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchAndSetData();
    _startTypewriterEffect();
    _searchController.addListener(_filterDoctors);
    _listenToDoctorUpdates();
  }

  Future<void> _fetchAndSetData() async {
    setState(() => _isLoading = true);
    await _fetchPatientName();
    await _fetchLocation(); // Wait for location to be fetched first
    await _fetchAndSetDoctors();
    _filterDoctors(); // Then filter and sort after all data is ready
    setState(() => _isLoading = false);
  }

  Future<void> _fetchLocation() async {
    try {
      final hasPermission = await _locationService.handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          _currentLocation = 'Permission Denied';
          _currentPosition = null; // Set position to null if permission is denied
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String? locality = place.locality;
        String? administrativeArea = place.administrativeArea;

        setState(() {
          _currentLocation = '${locality ?? ''}';
        });
      } else {
        setState(() {
          _currentLocation = 'Location not found';
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
      setState(() {
        _currentLocation = 'Location error';
        _currentPosition = null; // Set position to null on error
      });
    }
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

  void _listenToDoctorUpdates() {
    FirebaseFirestore.instance
        .collection('doctors')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _processDoctorData(snapshot.docs);
        _filterDoctors();
      }
    });
  }

  Future<void> _fetchPatientName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final String? fullName = doc.data()!['name'];
        if (fullName != null && fullName.isNotEmpty) {
          final List<String> nameParts = fullName.split(' ');
          setState(() {
            _patientName = nameParts.first;
          });
        }
      }
    }
  }

  Future<void> _fetchAndSetDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      _processDoctorData(snapshot.docs);
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() {
        _allDoctors = [];
        _filteredDoctors = [];
        _selectedSpecialization = 'All';
        _selectedLocation = 'All';
        _specializationCounts = {};
      });
    }
  }

  void _processDoctorData(List<QueryDocumentSnapshot> docs) {
    final List<Doctor> fetchedDoctors = [];
    final Set<String> uniqueSpecializations = {'All'};
    final Set<String> uniqueLocations = {'All'};
    final Map<String, int> specializationCounts = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      if (data['specialty'] == null || data['specialty'].toString().trim().isEmpty) {
        continue;
      }

      final specialization = data['specialty'].toString().trim();

      final doctor = Doctor(
        id: doc.id,
        name: data['name'] ?? 'N/A',
        specialization: specialization,
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
            ['MBBS'],
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
      );

      fetchedDoctors.add(doctor);
      uniqueSpecializations.add(specialization);
      uniqueLocations.add(doctor.location);

      specializationCounts[specialization] = (specializationCounts[specialization] ?? 0) + 1;
    }

    final sortedSpecializations = uniqueSpecializations.toList();
    sortedSpecializations.sort((a, b) {
      final countA = specializationCounts[a] ?? 0;
      final countB = specializationCounts[b] ?? 0;
      return countB.compareTo(countA);
    });

    setState(() {
      _allDoctors = fetchedDoctors;
      _specializations = sortedSpecializations;
      _locations = uniqueLocations.toList();
      _specializationCounts = specializationCounts;
      if (!_locations.contains(_selectedLocation)) {
        _selectedLocation = _locations.first;
      }
    });
  }

  void _filterDoctors() {
    setState(() {
      final List<Doctor> tempFilteredList = _allDoctors.where((doctor) {
        bool matchesSearch = _searchController.text.isEmpty ||
            doctor.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            doctor.specialization.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            doctor.hospital.toLowerCase().contains(_searchController.text.toLowerCase());
        bool matchesSpecialization = _selectedSpecialization == 'All' || doctor.specialization == _selectedSpecialization;
        bool matchesLocation = _selectedLocation == 'All' || doctor.location == _selectedLocation;
        return matchesSearch && matchesSpecialization && matchesLocation;
      }).toList();

      final List<Doctor> sameCityDoctors = [];
      final List<Doctor> nearbyCityDoctors = [];
      final List<Doctor> otherDoctors = [];

      final patientCity = _currentLocation.toLowerCase();

      for (var doctor in tempFilteredList) {
        if (doctor.location.toLowerCase() == patientCity) {
          sameCityDoctors.add(doctor);
        } else if (_currentPosition != null && doctor.latitude != null && doctor.longitude != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            doctor.latitude!,
            doctor.longitude!,
          );
          if (distanceInMeters <= 50000) { // 50 km radius
            nearbyCityDoctors.add(doctor);
          } else {
            otherDoctors.add(doctor);
          }
        } else {
          otherDoctors.add(doctor);
        }
      }

      // Sort nearby doctors by distance
      nearbyCityDoctors.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.latitude!,
          a.longitude!,
        );
        final distanceB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.latitude!,
          b.longitude!,
        );
        return distanceA.compareTo(distanceB);
      });

      // Combine the lists in the desired order
      _filteredDoctors = [...sameCityDoctors, ...nearbyCityDoctors, ...otherDoctors];
    });
  }

  void _onSpecialtyTapped(String specialty) {
    setState(() {
      _selectedSpecialization = specialty;
      _searchController.clear();
    });
    _filterDoctors();
  }

  void _startTypewriterEffect() {
    int optionIndex = 0;
    _typewriterTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        optionIndex = (optionIndex + 1) % _searchOptions.length;
        _currentSearchOption = _searchOptions[optionIndex];
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _typewriterTimer?.cancel();
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
                        _buildSearchSection(),
                        const SizedBox(height: 32),
                        _buildSpecialtiesSection(),
                        const SizedBox(height: 32),
                        _buildDoctorsSection(),
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
                              text: _patientName,
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
                        'How are you feeling today?',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
                    _currentLocation,
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

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryBlue.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search for $_currentSearchOption',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                Icons.search_rounded,
                color: primaryBlue,
                size: 22,
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () {
                _searchController.clear();
                _filterDoctors();
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
          onChanged: (query) => _filterDoctors(),
        ),
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
    final displaySpecialties = _specializations.take(5).toList();
    final hasMore = _specializations.length > 5;
    final displayCount = displaySpecialties.length + (hasMore ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Find Specialists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_specializations.length} specialties',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: displayCount,
            itemBuilder: (context, index) {
              if (index < displaySpecialties.length) {
                final specialty = displaySpecialties[index];
                final config = _specialtyConfig[specialty];
                final count = _specializationCounts[specialty] ?? 0;
                return _buildSpecialtyCard(
                  specialty,
                  config?['icon'] ?? Icons.local_hospital,
                  config?['color'] ?? primaryBlue,
                  config?['lightColor'] ?? lightBlue,
                  count,
                );
              } else {
                return _buildMoreCard();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyCard(
      String specialty,
      IconData icon,
      Color color,
      Color lightColor,
      int doctorCount,
      ) {
    final bool isSelected = _selectedSpecialization == specialty;

    return GestureDetector(
      onTap: () => _onSpecialtyTapped(specialty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  specialty,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? darkBlue : Colors.grey[800],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.25)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$doctorCount+',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoreSpecialtiesScreen(
              specialtyConfig: _specialtyConfig,
              specializations: _specializations,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: primaryBlue.withOpacity(0.15),
              child: Icon(
                Icons.more_horiz_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: darkBlue,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorsSection() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: primaryBlue,
          ),
        ),
      );
    }

    if (_filteredDoctors.isEmpty) {
      return _buildEmptyDoctors();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Doctors',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              Text(
                '${_filteredDoctors.length} found',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: _filteredDoctors.length,
          itemBuilder: (context, index) => _buildDoctorCard(_filteredDoctors[index], index),
        ),
      ],
    );
  }

  Widget _buildEmptyDoctors() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No doctors found',
            style: TextStyle(
              fontSize: 16,
              color: darkBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor, int index) {
    final specialtyConfig = _specialtyConfig[doctor.specialization];
    final specialtyColor = specialtyConfig?['color'] ?? primaryBlue;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DoctorProfileScreen(doctor: doctor),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: specialtyColor.withOpacity(0.2), width: 1.5),
                ),
                child: doctor.imageUrl.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    doctor.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDoctorInitial(doctor.name, specialtyColor),
                  ),
                )
                    : _buildDoctorInitial(doctor.name, specialtyColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Dr. ${doctor.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization,
                      style: TextStyle(
                        fontSize: 14,
                        color: specialtyColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.grey[400], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doctor.hospital,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRatingChip(doctor.rating),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookAppointmentScreen(doctor: doctor),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInitial(String name, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'D',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFFA726),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              fontSize: 11,
              color: isAvailable ? Colors.green : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
