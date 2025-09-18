// File: patient/more_specialties_screen.dart

import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';

class MoreSpecialtiesScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> specialtyConfig;
  final Map<String, int> specializationCounts;
  final List<String> specializations;

  const MoreSpecialtiesScreen({
    Key? key,
    required this.specialtyConfig,
    required this.specializationCounts,
    required this.specializations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Healthcare theme colors
    final Color primaryBlue = const Color(0xFF2196F3);
    final Color darkBlue = const Color(0xFF1976D2);
    final Color backgroundColor = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('All Specialists', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: specializations.isEmpty
          ? Center(
        child: Text(
          'No specialists found.',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: specializations.length,
          itemBuilder: (context, index) {
            final specialty = specializations[index];
            final config = specialtyConfig[specialty];
            final count = specializationCounts[specialty] ?? 0;

            // We'll simulate a tap here to navigate back and filter
            return GestureDetector(
              onTap: () {
                Navigator.pop(context, specialty);
              },
              // Pass the darkBlue color to the card widget
              child: _buildSpecialtyCard(
                specialty,
                config?['icon'] ?? Icons.local_hospital,
                config?['color'] ?? primaryBlue,
                config?['lightColor'] ?? primaryBlue.withOpacity(0.1),
                count,
                darkBlue, // Pass darkBlue here
              ),
            );
          },
        ),
      ),
    );
  }

  // Reuse the specialty card widget from home_screen.dart
  Widget _buildSpecialtyCard(
      String specialty,
      IconData icon,
      Color color,
      Color lightColor,
      int doctorCount,
      Color darkBlue, // Accept darkBlue as a parameter
      ) {
    final bool isSelected = false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
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
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                specialty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: darkBlue,
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
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$doctorCount+',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}