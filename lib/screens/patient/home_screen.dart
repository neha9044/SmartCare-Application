import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/patient/doctor_profile_screen.dart';
import 'package:smartcare_app/screens/patient/profile_screen.dart';
import 'package:smartcare_app/widgets/doctor_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Mumbai, Maharashtra';
  List<Doctor> _filteredDoctors = [];
  String _typewriterText = '';
  int _currentTypewriterIndex = 0;
  int _currentTextIndex = 0;
  Timer? _typewriterTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _typewriterTexts = [
    'Specialists...',
    'Clinics...',
    'Pharmacies...',
  ];

  final List<String> _locations = [
    'Mumbai, Maharashtra',
    'Delhi, NCR',
    'Bangalore, Karnataka',
    'Chennai, Tamil Nadu',
    'Kolkata, West Bengal',
    'Pune, Maharashtra',
    'Hyderabad, Telangana',
    'Ahmedabad, Gujarat',
  ];

  final List<Map<String, dynamic>> _specialistCategories = [
    {'name': 'Cardiologist', 'icon': '❤️', 'color': Colors.red.shade100},
    {'name': 'Dentist', 'icon': '🦷', 'color': Colors.blue.shade100},
    {'name': 'Dermatologist', 'icon': '✨', 'color': Colors.purple.shade100},
    {'name': 'Pediatrician', 'icon': '👶', 'color': Colors.green.shade100},
    {'name': 'Orthopedic', 'icon': '🦴', 'color': Colors.orange.shade100},
    {'name': 'Neurologist', 'icon': '🧠', 'color': Colors.indigo.shade100},
  ];

  final List<Doctor> _allDoctors = [
    Doctor(
      id: '1',
      name: 'Dr. Sarah Johnson',
      specialization: 'Cardiologist',
      hospital: 'Mumbai Heart Institute',
      location: 'Mumbai, Maharashtra',
      rating: 4.8,
      reviewCount: 156,
      experience: '15 years',
      imageUrl: '',
      availableSlots: ['9:00 AM', '11:00 AM', '3:00 PM', '5:00 PM'],
      consultationFee: 800,
      isAvailableToday: true,
      about: 'Specialist in cardiac surgeries and interventional cardiology.',
      qualifications: ['MBBS', 'MD Cardiology'],
    ),
    Doctor(
      id: '2',
      name: 'Dr. Michael Brown',
      specialization: 'Dermatologist',
      hospital: 'Skin Care Clinic',
      location: 'Mumbai, Maharashtra',
      rating: 4.6,
      reviewCount: 89,
      experience: '12 years',
      imageUrl: '',
      availableSlots: ['10:00 AM', '2:00 PM', '4:00 PM'],
      consultationFee: 600,
      isAvailableToday: false,
      about: 'Expert in treating skin conditions and cosmetic dermatology.',
      qualifications: ['MBBS', 'MD Dermatology'],
    ),
    Doctor(
      id: '3',
      name: 'Dr. Emily Davis',
      specialization: 'General Physician',
      hospital: 'City General Hospital',
      location: 'Mumbai, Maharashtra',
      rating: 4.7,
      reviewCount: 234,
      experience: '10 years',
      imageUrl: '',
      availableSlots: ['8:00 AM', '10:00 AM', '1:00 PM', '6:00 PM'],
      consultationFee: 400,
      isAvailableToday: true,
      about: 'Experienced in preventive care and chronic disease management.',
      qualifications: ['MBBS', 'MD General Medicine'],
    ),
    Doctor(
      id: '4',
      name: 'Dr. James Wilson',
      specialization: 'Pediatrician',
      hospital: 'Children\'s Hospital',
      location: 'Mumbai, Maharashtra',
      rating: 4.9,
      reviewCount: 178,
      experience: '18 years',
      imageUrl: '',
      availableSlots: ['9:00 AM', '12:00 PM', '4:00 PM'],
      consultationFee: 500,
      isAvailableToday: true,
      about: 'Specialized in child healthcare and development.',
      qualifications: ['MBBS', 'MD Pediatrics'],
    ),
    Doctor(
      id: '5',
      name: 'Dr. Lisa Anderson',
      specialization: 'Orthopedic',
      hospital: 'Bone & Joint Center',
      location: 'Mumbai, Maharashtra',
      rating: 4.5,
      reviewCount: 142,
      experience: '14 years',
      imageUrl: '',
      availableSlots: ['11:00 AM', '2:00 PM', '5:00 PM'],
      consultationFee: 700,
      isAvailableToday: true,
      about: 'Specialized in joint replacements and sports injuries.',
      qualifications: ['MBBS', 'MS Orthopedics'],
    ),
  ];

  String _patientName = 'John Doe'; // This should come from user profile

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _filterDoctors();
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
        timer.cancel(); // Stop the current timer
        Timer(const Duration(seconds: 2), () {
          setState(() {
            _currentTextIndex = (_currentTextIndex + 1) % _typewriterTexts.length;
            _currentTypewriterIndex = 0;
            _typewriterText = '';
          });
          _startTypewriterEffect(); // Start a new timer for the next text
        });
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        bool matchesLocation = doctor.location == _selectedLocation;
        return matchesLocation;
      }).toList();
    });
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
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        _buildHeader(context),
                        _buildGreeting(),
                        _buildLocationSelector(),
                        _buildSpecialistGrid(),
                        _buildDoctorsList(),
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  );
                },
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGlassIconButton(
                icon: Icons.person_outline_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ),
              ),
              _buildTypewriterSearchBar(),
              _buildGlassIconButton(
                icon: Icons.smart_toy_outlined,
                onTap: () {
                  // TODO: Navigate to AI chatbot
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTypewriterSearchBar() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.primaryColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _typewriterText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              width: 2,
              height: 16,
              color: AppColors.primaryColor.withOpacity(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            AppColors.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.2),
                  AppColors.gradientMid1.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              '👋',
              style: TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $_patientName,',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.red.shade400, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                    });
                    _filterDoctors();
                  },
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  dropdownColor: Colors.white,
                  style: TextStyle(color: Colors.grey.shade700),
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistGrid() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppColors.glassmorphismGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Find Specialists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _specialistCategories.length,
            itemBuilder: (context, index) {
              final specialist = _specialistCategories[index];
              return _buildSpecialistCard(specialist);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistCard(Map<String, dynamic> specialist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: specialist['color'],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              specialist['icon'],
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            specialist['name'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppColors.glassmorphismGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Available Doctors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredDoctors.length,
            itemBuilder: (context, index) {
              return _buildDoctorCard(_filteredDoctors[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.2),
                    AppColors.gradientMid1.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doctor.specialization,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor.rating} (${doctor.reviewCount} reviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorProfileScreen(doctor: doctor),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Book',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
