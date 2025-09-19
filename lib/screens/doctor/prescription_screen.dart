// lib/screens/doctor/prescription_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import to get current user ID

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({
    Key? key,
    required this.onSave,
    required this.patientId,
    required this.patientName,
    required this.doctorDetails,
  }) : super(key: key);

  final Function(Map<String, String>) onSave;
  final String patientId;
  final String patientName;
  final Map<String, String> doctorDetails;

  @override
  _PrescriptionScreenState createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _patientNameController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _dateController;
  late TextEditingController _prescriptionController;

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController(text: widget.patientName);
    _ageController = TextEditingController();
    _addressController = TextEditingController();
    _dateController = TextEditingController(text: "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}");
    _prescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doctorDetails['specialty'] ?? "APOLLO DOCTOR",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50)),
                    ),
                    Text(widget.doctorDetails['name'] ?? "Dr. Alex Chen", style: const TextStyle(color: Color(0xFF34495E))),
                    const SizedBox(height: 8),
                    Text(
                      widget.doctorDetails['address'] ?? "123 Anywhere St., Any City",
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 30, thickness: 1.5, color: Color(0xFFBDC3C7)),
                TextFormField(
                  controller: _patientNameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: "Patient's Name",
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                      labelText: "Age", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? "Enter age" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                      labelText: "Address", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  validator: (v) => v!.isEmpty ? "Enter address" : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                      labelText: "Date", border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))),
                  validator: (v) => v!.isEmpty ? "Enter date" : null,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
                    controller: _prescriptionController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: "Enter full prescription details here...",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (v) => v!.isEmpty ? "Enter prescription details" : null,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave({
                        "doctorName": widget.doctorDetails['name'] ?? "Dr. Alex Chen",
                        "doctorSpecialty": widget.doctorDetails['specialty'] ?? "APOLLO DOCTOR",
                        "clinicAddress": widget.doctorDetails['address'] ?? "123 Anywhere St., Any City",
                        "name": _patientNameController.text,
                        "age": _ageController.text,
                        "address": _addressController.text,
                        "date": _dateController.text,
                        "prescription": _prescriptionController.text,
                        "doctorId": FirebaseAuth.instance.currentUser!.uid, // FIX: Added the doctorId here
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Prescription", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}