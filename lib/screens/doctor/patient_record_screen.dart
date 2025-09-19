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

  Future<void> _savePrescription(Map<String, String> prescriptionData) async {
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
      appBar: AppBar(
        title: Text('Patient Record: ${widget.patientName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.note_add), text: 'New Prescription'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
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
    );
  }
}