// lib/screens/doctor/patient_record_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/screens/doctor/prescription_screen.dart';
import 'package:smartcare_app/screens/doctor/history_screen.dart';

class PatientRecordScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final Map<String, String> doctorDetails;
  final ScrollController? scrollController; // FIX: Made the parameter optional

  const PatientRecordScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    required this.doctorDetails,
    this.scrollController, // FIX: Made the parameter optional
  }) : super(key: key);

  @override
  _PatientRecordScreenState createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends State<PatientRecordScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Updated method signature to accept Map<String, dynamic>
  Future<void> _savePrescription(Map<String, dynamic> prescriptionData) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('prescriptions')
          .add({
        ...prescriptionData,
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescription Saved!")));
      _tabController.animateTo(1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save prescription.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Patient Name and Navigation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2E3A59)),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.person, color: Color(0xFF1E88E5), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E3A59),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF1E88E5),
                labelColor: const Color(0xFF1E88E5),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(icon: Icon(Icons.note_add), text: 'New Prescription'),
                  Tab(icon: Icon(Icons.history), text: 'History'),
                ],
              ),
            ),

            // Tab Content - Full Screen
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PrescriptionScreen(
                    onSave: _savePrescription,
                    patientId: widget.patientId,
                    patientName: widget.patientName,
                    doctorDetails: widget.doctorDetails,
                  ),
                  HistoryScreen(
                    patientId: widget.patientId,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}