// lib/screens/pharmacy/prescription_details_screen.dart

import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_home_page.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final Order order;
  final Patient patient;

  const PrescriptionDetailsScreen({
    Key? key,
    required this.order,
    required this.patient,
  }) : super(key: key);

  @override
  _PrescriptionDetailsScreenState createState() => _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  late Order _order;
  late Patient _patient;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _patient = widget.patient;
  }

  void _updateOrderState() {
    setState(() {
      _order = _order;
      _patient = _patient;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              subtitle: 'Dr. ${_patient.doctorName}',
              icon: Icons.local_hospital,
              iconColor: AppColors.primaryColor,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Patient Name',
              subtitle: _patient.name,
              icon: Icons.person,
              iconColor: AppColors.green,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: 'Order ID',
              subtitle: _order.id,
              icon: Icons.receipt_long,
              iconColor: AppColors.orange,
            ),
            const SizedBox(height: 16),
            _buildMedicinesSection(_order.prescription),
            const SizedBox(height: 16),
            _buildStatusSection(),
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

  Widget _buildMedicinesSection(List<String> medicines) {
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
            ...medicines.map((med) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medication, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      med,
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    String statusText = _order.isCanceled ? 'Canceled' : (_order.isPickedUp ? 'Picked Up' : (_order.isCompleted ? 'Completed' : 'Pending'));
    Color statusColor = _order.isCanceled ? AppColors.red : (_order.isPickedUp ? AppColors.darkGrey : (_order.isCompleted ? AppColors.green : AppColors.orange));

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
          if (!_order.isCompleted && !_order.isCanceled)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _order.isCanceled = true;
                      _updateOrderState();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order marked as canceled.')),
                    );
                  },
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
                  onTap: () {
                    setState(() {
                      _order.isCompleted = true;
                      _updateOrderState();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order marked as completed!')),
                    );
                  },
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
          // Check if the order is completed but NOT picked up and show icon
          if (_order.isCompleted && !_order.isPickedUp)
            GestureDetector(
              onTap: () {
                setState(() {
                  _order.isPickedUp = true;
                  _updateOrderState();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order marked as picked up.')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, color: Colors.white),
              ),
            ),
          // Display icons for completed or canceled status
          if (_order.isPickedUp)
            Icon(Icons.shopping_bag, color: AppColors.darkGrey),
          if (_order.isCanceled)
            Icon(Icons.cancel, color: AppColors.red),
        ],
      ),
    );
  }
}