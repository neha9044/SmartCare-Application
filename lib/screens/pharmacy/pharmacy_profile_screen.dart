import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/services/auth_service.dart';

class PharmacyProfileScreen extends StatelessWidget {
  const PharmacyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentPharmacyId = FirebaseAuth.instance.currentUser?.uid;
    final AuthService _authService = AuthService();

    Future<void> _handleLogout() async {
      try {
        await _authService.signOut();
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log out. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }

    if (currentPharmacyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Please log in to view your profile.')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('pharmacies').doc(currentPharmacyId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data."));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Pharmacy profile not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'N/A';
          final String email = data['email'] ?? 'N/A';
          final String phone = data['phone'] ?? 'N/A';
          final String licenseNumber = data['licenseNumber'] ?? 'N/A';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryColor,
                    child: const Icon(
                      Icons.local_pharmacy,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  // Removed the Text widget that displays the pharmacy ID as requested.
                  const SizedBox(height: 24),
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'Email',
                    subtitle: email,
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Phone Number',
                    subtitle: phone,
                  ),
                  _buildInfoCard(
                    icon: Icons.verified,
                    title: 'License Number',
                    subtitle: licenseNumber,
                  ),
                  _buildLogoutCard(_handleLogout),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
