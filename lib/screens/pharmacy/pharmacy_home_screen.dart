// lib/screens/pharmacy/pharmacy_home_screen.dart

import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_home_page.dart' as pharmacy_models;
import 'package:smartcare_app/screens/pharmacy/pharmacy_orders_list.dart';
import 'package:smartcare_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_profile_screen.dart';

class PharmacyHomeScreen extends StatefulWidget {
  const PharmacyHomeScreen({super.key});

  @override
  _PharmacyHomeScreenState createState() => _PharmacyHomeScreenState();
}

class _PharmacyHomeScreenState extends State<PharmacyHomeScreen> {
  String _pharmacyName = 'Fetching Name...';
  String _currentLocation = 'Fetching location...';
  final LocationService _locationService = LocationService();
  final String? _currentPharmacyId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchPharmacyData();
    _fetchLocation();
  }

  Future<void> _fetchPharmacyData() async {
    if (_currentPharmacyId != null) {
      FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(_currentPharmacyId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data.containsKey('name')) {
            setState(() {
              _pharmacyName = data['name'];
            });
          }
        }
      });
    }
  }

  Future<void> _fetchLocation() async {
    try {
      final hasPermission = await _locationService.handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          _currentLocation = 'Permission Denied';
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String? locality = place.locality;
        setState(() {
          _currentLocation = locality ?? 'Location not found';
        });
      } else {
        setState(() {
          _currentLocation = 'Location not found';
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Location error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPharmacyId == null) {
      return Scaffold(
        body: Center(
          child: Text('Please log in as a pharmacy to view this page.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('pharmacy_orders')
                        .where('pharmacyId', isEqualTo: _currentPharmacyId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final orders = snapshot.data?.docs ?? [];

                      final pendingOrders = orders.where((order) => order['status'] == 'pending').toList();
                      final completedOrders = orders.where((order) => order['status'] == 'completed').toList();
                      final pickedUpOrders = orders.where((order) => order['status'] == 'picked_up').toList();
                      final canceledOrders = orders.where((order) => order['status'] == 'canceled').toList();

                      return _buildOrderBlocks(
                          pendingOrders.length,
                          completedOrders.length,
                          pickedUpOrders.length,
                          canceledOrders.length,
                          {
                            'pending': pendingOrders,
                            'completed': completedOrders,
                            'picked_up': pickedUpOrders,
                            'canceled': canceledOrders,
                          }
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
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
                          text: 'Hello, ',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: Colors.grey[700]),
                        ),
                        TextSpan(
                          text: _pharmacyName,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkGrey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLocationSection(),
                ],
              ),
            ),
            _buildHeaderIconButton(
              Icons.person_outline_rounded,
              AppColors.primaryColor,
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PharmacyProfileScreen()),
                );
              },
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
            color: AppColors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.location_on_rounded, color: AppColors.red, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Location',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              Text(
                _currentLocation,
                style: TextStyle(fontSize: 14, color: AppColors.darkGrey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderBlocks(
      int pendingCount,
      int completedCount,
      int pickedUpCount,
      int canceledCount,
      Map<String, List<DocumentSnapshot>> orders,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildOrderBlock(context, 'Pending Orders', pendingCount, AppColors.orange, Icons.access_time_filled, orders['pending']!),
          _buildOrderBlock(context, 'Completed Orders', completedCount, AppColors.green, Icons.check_circle, orders['completed']!),
          _buildOrderBlock(context, 'Picked Up Orders', pickedUpCount, AppColors.primaryColor, Icons.shopping_bag, orders['picked_up']!),
          _buildOrderBlock(context, 'Canceled Orders', canceledCount, AppColors.red, Icons.cancel, orders['canceled']!),
        ],
      ),
    );
  }

  Widget _buildOrderBlock(
      BuildContext context,
      String title,
      int count,
      Color color,
      IconData icon,
      List<DocumentSnapshot> orders,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyOrdersListScreen(
              title: title,
              orders: orders,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.darkGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count orders',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}