// lib/screens/pharmacy/pharmacy_orders_list.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/pharmacy/pharmacy_home_page.dart';
import 'package:smartcare_app/screens/pharmacy/prescription_details_screen.dart';

class PharmacyOrdersListScreen extends StatefulWidget {
  final String title;
  final List<OrderWithPatient> orders;

  const PharmacyOrdersListScreen({
    super.key,
    required this.title,
    required this.orders,
  });

  @override
  State<PharmacyOrdersListScreen> createState() => _PharmacyOrdersListScreenState();
}

class _PharmacyOrdersListScreenState extends State<PharmacyOrdersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<OrderWithPatient> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _filteredOrders = widget.orders;
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredOrders = widget.orders.where((order) {
        // Updated logic to search by both patient name and doctor name
        return order.patient.doctorName.toLowerCase().contains(query) ||
            order.patient.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Doctor or Patient Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          Expanded(
            child: _buildOrderList(_filteredOrders),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderWithPatient> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found for this search.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final orderWithPatient = orders[index];
        return _buildOrderCardItem(orderWithPatient);
      },
    );
  }

  Widget _buildOrderCardItem(OrderWithPatient orderWithPatient) {
    final order = orderWithPatient.order;
    final patient = orderWithPatient.patient;
    Color cardColor = order.isCanceled ? Colors.red.shade50 : (order.isCompleted && order.isPickedUp ? Colors.green.shade50 : Colors.blue.shade50);
    IconData icon = order.isCanceled ? Icons.cancel : (order.isCompleted ? Icons.check_circle : Icons.access_time);
    Color iconColor = order.isCanceled ? AppColors.red : (order.isCompleted ? AppColors.green : AppColors.orange);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionDetailsScreen(
              order: order,
              patient: patient,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: iconColor,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            'Patient: ${patient.name}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ID: ${order.id}'),
              Text('Doctor: ${patient.doctorName}'),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}