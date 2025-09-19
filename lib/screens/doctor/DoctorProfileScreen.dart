// doctor_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/services/auth_service.dart'; // Import AuthService

class DoctorProfileScreen extends StatelessWidget {
  final String doctorId;
  final AuthService _authService = AuthService();

  DoctorProfileScreen({Key? key, required this.doctorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('doctors').doc(doctorId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
          final String license = data['license'] ?? 'N/A';
          final String experience = data['experience'] ?? 'N/A';
          final String qualification = data['qualification'] ?? 'N/A';
          final String location = data['location'] ?? 'N/A';
          final String clinicName = data['clinicName'] ?? 'N/A';
          final String consultationFees = data['consultationFees']?.toString() ?? 'N/A';
          final String profileImageUrl = data['profileImageUrl'] ?? '';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF2196F3),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: const Color(0xFF2196F3)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? Icon(Icons.person, size: 50, color: const Color(0xFF2196F3))
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Dr. $name",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialty,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Contact Information"),
                      _buildInfoCard(icon: Icons.email, label: "Email", value: email),
                      _buildInfoCard(icon: Icons.phone, label: "Phone", value: phone),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Professional Details"),
                      _buildInfoCard(icon: Icons.badge, label: "License Number", value: license),
                      _buildInfoCard(icon: Icons.school, label: "Qualification", value: qualification),
                      _buildInfoCard(icon: Icons.work, label: "Experience", value: experience),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Clinic & Fees"),
                      _buildInfoCard(icon: Icons.local_hospital, label: "Clinic Name", value: clinicName),
                      _buildInfoCard(icon: Icons.location_on, label: "Location", value: location),
                      _buildInfoCard(icon: Icons.attach_money, label: "Consultation Fees", value: consultationFees),
                      const SizedBox(height: 30),
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _authService.signOut();
                            // Explicitly navigate to the login page and clear the stack
                            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2196F3)),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
      ),
    );
  }
}