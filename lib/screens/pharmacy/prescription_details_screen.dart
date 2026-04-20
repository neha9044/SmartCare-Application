// lib/screens/pharmacy/prescription_details_screen.dart

import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final DocumentSnapshot orderDoc;

  const PrescriptionDetailsScreen({
    Key? key,
    required this.orderDoc,
  }) : super(key: key);

  @override
  _PrescriptionDetailsScreenState createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  late Map<String, dynamic> _orderData;
  late String _orderId;

  @override
  void initState() {
    super.initState();
    _orderData = widget.orderDoc.data() as Map<String, dynamic>;
    _orderId = widget.orderDoc.id;
  }

  void _updateOrderStatus(String newStatus) async {
    await FirebaseFirestore.instance.collection('pharmacy_orders').doc(_orderId).update({
      'status': newStatus,
    });
    setState(() {
      _orderData['status'] = newStatus;
    });

    // Add a new document to the notifications collection when the status is completed
    if (newStatus == 'completed') {
      try {
        // Fetch pharmacy name
        final pharmacyId = FirebaseAuth.instance.currentUser!.uid;
        final pharmacyDoc = await FirebaseFirestore.instance.collection('pharmacies').doc(pharmacyId).get();
        final pharmacyName = pharmacyDoc.data()?['name'] ?? 'The Pharmacy';

        await FirebaseFirestore.instance.collection('notifications').add({
          'patientId': _orderData['patientId'],
          'message': 'Your medicines are ready at $pharmacyName! Get them',
          'type': 'prescription_ready',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'orderId': _orderId,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus and patient notified.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = _orderData['status'] ?? 'pending';
    final List<dynamic> medicines = _orderData['prescription'] ?? [];

    String statusText;
    Color statusColor;

    switch (status) {
      case 'canceled':
        statusText = 'Canceled';
        statusColor = AppColors.red;
        break;
      case 'completed':
        statusText = 'Completed';
        statusColor = AppColors.green;
        break;
      case 'picked_up':
        statusText = 'Picked Up';
        statusColor = AppColors.darkGrey;
        break;
      default:
        statusText = 'Pending';
        statusColor = AppColors.orange;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: 'Prescribed by',
              subtitle: 'Dr. ${_orderData['doctorName'] ?? 'N/A'}',
              icon: Icons.local_hospital,
              iconColor: AppColors.primaryColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Patient Name',
              subtitle: _orderData['patientName'] ?? 'N/A',
              icon: Icons.person,
              iconColor: AppColors.green,
            ),
            const SizedBox(height: 16),
            _buildMedicinesSection(medicines),
            const SizedBox(height: 16),
            _buildStatusSection(status, statusText, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
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
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesSection(List<dynamic> medicines) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medicines',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const Divider(height: 24, thickness: 1),
          if (medicines.isEmpty)
            const Text('No medicines prescribed.')
          else
            ...medicines.map((med) {
              final medData = med as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.medication, color: AppColors.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${medData['medicineName']} - ${medData['dosageAndFrequency']}',
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusSection(String status, String statusText, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Status: $statusText',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (status == 'pending')
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _updateOrderStatus('canceled'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _updateOrderStatus('completed'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                ),
              ],
            ),
          if (status == 'completed')
            GestureDetector(
              onTap: () => _updateOrderStatus('picked_up'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, color: Colors.white),
              ),
            ),
          if (status == 'picked_up')
            Icon(Icons.shopping_bag, color: AppColors.darkGrey),
          if (status == 'canceled')
            Icon(Icons.cancel, color: AppColors.red),
        ],
      ),
    );
  }
}