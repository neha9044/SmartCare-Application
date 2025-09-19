// lib/screens/doctor/prescription_history_screen.dart
import 'package:flutter/material.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/screens/doctor/prescription_screen.dart';
import 'package:smartcare_app/screens/doctor/history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({
    Key? key,
    required this.doctorDetails,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  final Map<String, String> doctorDetails;
  final String patientId;
  final String patientName;

  @override
  _PrescriptionHistoryScreenState createState() => _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState extends State<PrescriptionHistoryScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void _onSavePrescription(Map<String, String> prescriptionData) {
    // Save the prescription directly to Firestore
    FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patientId)
        .collection('prescriptions')
        .add({
      ...prescriptionData,
      'timestamp': FieldValue.serverTimestamp(),
    })
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription Saved to Firestore!")),
      );
      // After saving, switch to the history tab
      setState(() {
        _selectedIndex = 1;
      });
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save prescription: $error")),
      );
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _widgetOptions = <Widget>[
      PrescriptionScreen(
        onSave: _onSavePrescription,
        patientId: widget.patientId,
        patientName: widget.patientName,
        doctorDetails: widget.doctorDetails,
      ),
      HistoryScreen(patientId: widget.patientId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions & Records'),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.note_add),
            label: 'New Prescription',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}