// lib/screens/pharmacy/pharmacy_orders_list.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/pharmacy/prescription_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyOrdersListScreen extends StatefulWidget {
  final String title;
  final List<DocumentSnapshot> orders;

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
  List<DocumentSnapshot> _filteredOrders = [];

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
        final data = order.data() as Map<String, dynamic>;
        final patientName = data['patientName']?.toLowerCase() ?? '';
        final doctorName = data['doctorName']?.toLowerCase() ?? '';
        return patientName.contains(query) || doctorName.contains(query);
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

  Widget _buildOrderList(List<DocumentSnapshot> orders) {
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
        final orderDoc = orders[index];
        return _buildOrderCardItem(orderDoc);
      },
    );
  }

  Widget _buildOrderCardItem(DocumentSnapshot orderDoc) {
    final order = orderDoc.data() as Map<String, dynamic>;
    final patientName = order['patientName'] ?? 'N/A';
    final doctorName = order['doctorName'] ?? 'N/A';
    final status = order['status'] ?? 'pending';

    Color cardColor;
    IconData icon;
    Color iconColor;

    switch (status) {
      case 'canceled':
        cardColor = Colors.red.shade50;
        icon = Icons.cancel;
        iconColor = AppColors.red;
        break;
      case 'completed':
        cardColor = Colors.green.shade50;
        icon = Icons.check_circle;
        iconColor = AppColors.green;
        break;
      case 'picked_up':
        cardColor = Colors.grey.shade200;
        icon = Icons.shopping_bag;
        iconColor = AppColors.darkGrey;
        break;
      default:
        cardColor = Colors.blue.shade50;
        icon = Icons.access_time;
        iconColor = AppColors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionDetailsScreen(
              orderDoc: orderDoc,
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
            'Patient: $patientName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Doctor: $doctorName'),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}