import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/patient/doctor_profile_screen.dart';
import 'package:smartcare_app/screens/patient/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  String _patientName = 'John Doe'; // Replace with actual user data
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = true;

  String? _selectedLocation;
  String? _selectedSpecialization;
  List<String> _locations = ['All'];
  List<String> _specializations = ['All'];

  // Typewriter effect
  String _typewriterText = '';
  int _currentTypewriterIndex = 0;
  int _currentTextIndex = 0;
  Timer? _typewriterTimer;
  final List<String> _typewriterTexts = ['Specialists...', 'Clinics...', 'Pharmacies...'];

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchAndSetDoctors();
    _searchController.addListener(_filterDoctors);
    _startTypewriterEffect();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  void _startTypewriterEffect() {
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      String currentText = _typewriterTexts[_currentTextIndex];
      if (_currentTypewriterIndex < currentText.length) {
        setState(() {
          _typewriterText = currentText.substring(0, _currentTypewriterIndex + 1);
          _currentTypewriterIndex++;
        });
      } else {
        timer.cancel();
        Timer(const Duration(seconds: 2), () {
          setState(() {
            _currentTextIndex = (_currentTextIndex + 1) % _typewriterTexts.length;
            _currentTypewriterIndex = 0;
            _typewriterText = '';
          });
          _startTypewriterEffect();
        });
      }
    });
  }

  Future<void> _fetchAndSetDoctors() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('doctors').get();
      final List<Doctor> fetchedDoctors = [];
      final Set<String> uniqueSpecializations = {'All'};
      final Set<String> uniqueLocations = {'All'};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final doctor = Doctor(
          id: doc.id,
          name: data['name'] ?? 'N/A',
          specialization: data['specialty'] ?? 'General Physician',
          hospital: data['clinicName'] ?? 'N/A',
          location: data['location'] ?? 'N/A',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          reviewCount: data['reviewCount'] ?? 0,
          experience: data['experience'] ?? 'N/A',
          imageUrl: '',
          availableSlots: (data['availableSlots'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['9:00 AM'],
          consultationFee: (data['consultationFees'] as num?)?.toDouble() ?? 0.0,
          isAvailableToday: true,
          about: data['about'] ?? '',
          qualifications: (data['qualification'] as String?)?.split(',').map((q) => q.trim()).toList() ?? [],
        );
        fetchedDoctors.add(doctor);
        uniqueSpecializations.add(doctor.specialization);
        uniqueLocations.add(doctor.location);
      }

      setState(() {
        _allDoctors = fetchedDoctors;
        _specializations = uniqueSpecializations.toList();
        _locations = uniqueLocations.toList();
        _selectedSpecialization = _specializations.first;
        _selectedLocation = _locations.first;
        _isLoading = false;
      });

      _filterDoctors();
    } catch (e) {
      print('Error fetching doctors: $e');
      setState(() {
        _allDoctors = [];
        _filteredDoctors = [];
        _isLoading = false;
        _selectedSpecialization = 'All';
        _selectedLocation = 'All';
      });
    }
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        bool matchesSearch = doctor.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            doctor.specialization.toLowerCase().contains(_searchController.text.toLowerCase());
        bool matchesSpecialization = _selectedSpecialization == 'All' || doctor.specialization == _selectedSpecialization;
        bool matchesLocation = _selectedLocation == 'All' || doctor.location == _selectedLocation;
        return matchesSearch && matchesSpecialization && matchesLocation;
      }).toList();
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      _buildGreeting(),
                      _buildFilters(),
                      _buildDoctorsList(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart.withOpacity(0.1),
            AppColors.gradientMid1.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconButton(Icons.person_outline_rounded, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _typewriterText,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ),
                  Container(width: 2, height: 16, color: AppColors.primaryColor),
                ],
              ),
            ),
          ),
          _buildIconButton(Icons.smart_toy_outlined, () {
            // TODO: AI Chatbot
          }),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: Icon(icon, color: AppColors.primaryColor),
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.9), AppColors.primaryColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Text('👋', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello $_patientName,', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('How are you feeling today?', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedLocation = value);
                    _filterDoctors();
                  },
                  items: _locations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedSpecialization,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() => _selectedSpecialization = value);
                    _filterDoctors();
                  },
                  items: _specializations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Search doctors...', prefixIcon: Icon(Icons.search)),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_filteredDoctors.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('No doctors found.', textAlign: TextAlign.center),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredDoctors.length,
      itemBuilder: (context, index) => _doctorCard(_filteredDoctors[index]),
    );
  }

  Widget _doctorCard(Doctor doctor) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(doctor.name),
        subtitle: Text('${doctor.specialization} • ${doctor.location}'),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)),
            );
          },
          child: const Text('Book'),
        ),
      ),
    );
  }
}
