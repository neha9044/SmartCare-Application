import 'package:flutter/material.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorCard({Key? key, required this.doctor, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String initials = '';
    // A safe way to get initials from the name
    if (doctor.name.isNotEmpty) {
      List<String> nameParts = doctor.name.split(' ');
      if (nameParts.isNotEmpty) {
        initials += nameParts.first[0];
        if (nameParts.length > 1) {
          initials += nameParts[1][0];
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    doctor.specialization,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor.rating}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${doctor.reviewCount} reviews)',
                        style: TextStyle(color: AppColors.darkGrey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.darkGrey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          doctor.location,
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (doctor.isAvailableToday)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text('Book Now'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}