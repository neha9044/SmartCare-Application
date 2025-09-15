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

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecialization = 'All';
  String _selectedLocation = 'Andheri West';
  List<Doctor> _filteredDoctors = [];

  final List<String> _specializations = [
    'All',
    'Cardiologist',
    'Dermatologist',
    'General Physician',
    'Pediatrician',
    'Orthopedic',
    'Neurologist',
    'Gynecologist',
    'ENT Specialist',
    'Psychiatrist'
  ];

  final List<String> _locations = [
    'Andheri West',
    'Bandra East',
    'Powai',
    'Worli',
    'Lower Parel',
    'Colaba',
    'Churchgate',
    'Dadar',
    'Thane'
  ];

  final List<Doctor> _allDoctors = [
    Doctor(
      id: '1',
      name: 'Dr. Sarah Johnson',
      specialization: 'Cardiologist',
      hospital: 'Mumbai Heart Institute',
      location: 'Andheri West',
      rating: 4.8,
      reviewCount: 156,
      experience: '15 years',
      imageUrl: '',
      availableSlots: ['9:00 AM', '11:00 AM', '3:00 PM', '5:00 PM'],
      consultationFee: 800,
      isAvailableToday: true,
      about: 'Specialist in cardiac surgeries and interventional cardiology with over 15 years of experience.',
      qualifications: ['MBBS', 'MD Cardiology', 'Fellowship in Interventional Cardiology'],
    ),
    Doctor(
      id: '2',
      name: 'Dr. Michael Brown',
      specialization: 'Dermatologist',
      hospital: 'Skin Care Clinic',
      location: 'Bandra East',
      rating: 4.6,
      reviewCount: 89,
      experience: '12 years',
      imageUrl: '',
      availableSlots: ['10:00 AM', '2:00 PM', '4:00 PM'],
      consultationFee: 600,
      isAvailableToday: false,
      about: 'Expert in treating skin conditions, cosmetic dermatology, and dermatological surgeries.',
      qualifications: ['MBBS', 'MD Dermatology', 'Diploma in Dermatology'],
    ),
    Doctor(
      id: '3',
      name: 'Dr. Emily Davis',
      specialization: 'General Physician',
      hospital: 'City General Hospital',
      location: 'Powai',
      rating: 4.7,
      reviewCount: 234,
      experience: '10 years',
      imageUrl: '',
      availableSlots: ['8:00 AM', '10:00 AM', '1:00 PM', '6:00 PM'],
      consultationFee: 400,
      isAvailableToday: true,
      about: 'Experienced general physician specializing in preventive care and chronic disease management.',
      qualifications: ['MBBS', 'MD General Medicine'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filterDoctors();
    _searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDoctors() {
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        bool matchesSearch = doctor.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            doctor.specialization.toLowerCase().contains(_searchController.text.toLowerCase());
        bool matchesSpecialization = _selectedSpecialization == 'All' || doctor.specialization == _selectedSpecialization;
        bool matchesLocation = doctor.location == _selectedLocation;
        return matchesSearch && matchesSpecialization && matchesLocation;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          },
        ),
        title: const Text(
          'SmartCare',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              // TODO: Navigate to AI chatbot
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: AppColors.primaryColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                                  child: Text(location),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSpecialization,
                              isExpanded: true,
                              onChanged: (value) {
                                setState(() {
                                  _selectedSpecialization = value!;
                                });
                                _filterDoctors();
                              },
                              items: _specializations.map((specialization) {
                                return DropdownMenuItem(
                                  value: specialization,
                                  child: Text(specialization),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterDoctors(),
                    decoration: InputDecoration(
                      hintText: 'Search for doctors...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_filteredDoctors.length} doctors found in $_selectedLocation',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_filteredDoctors.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Text(
                          'No doctors found. Try a different location or specialization.',
                          style: TextStyle(color: AppColors.lightGrey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._filteredDoctors.map((doctor) {
                      return DoctorCard(
                        doctor: doctor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorProfileScreen(doctor: doctor),
                            ),
                          );
                        },
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}