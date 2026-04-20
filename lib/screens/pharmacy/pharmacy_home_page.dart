// lib/screens/pharmacy/pharmacy_home_page.dart
// This file is now used for data models to be shared across pharmacy screens.

import 'package:flutter/material.dart';

// A StatefulWidget to manage the pharmacy orders UI and state.
class PharmacyHomePage extends StatelessWidget {
  const PharmacyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // This file is now just a placeholder. The main logic has been moved.
    return const Scaffold(
      body: Center(
        child: Text('Pharmacy Home Page is now served from a different file.'),
      ),
    );
  }
}

// A simple class to represent a Patient.
class Patient {
  final String id;
  final String name;
  final String doctorName;
  final List<Order> orders;

  Patient({
    required this.id,
    required this.name,
    required this.doctorName,
    required this.orders,
  });
}

// A simple class to represent an Order.
class Order {
  final String id;
  final List<String> prescription;
  String paymentStatus;
  bool isCanceled;
  bool isCompleted;
  bool isPickedUp;

  Order({
    required this.id,
    required this.prescription,
    required this.paymentStatus,
    this.isCanceled = false,
    this.isCompleted = false,
    this.isPickedUp = false,
  });
}

// A helper class to combine Order and Patient data.
class OrderWithPatient {
  final Order order;
  final Patient patient;

  OrderWithPatient({required this.order, required this.patient});
}