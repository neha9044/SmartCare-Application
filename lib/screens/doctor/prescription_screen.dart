// lib/screens/doctor/prescription_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({
    Key? key,
    required this.onSave,
    required this.patientId,
    required this.patientName,
    required this.doctorDetails,
  }) : super(key: key);

  final Function(Map<String, dynamic>) onSave;
  final String patientId;
  final String patientName;
  final Map<String, String> doctorDetails;

  @override
  _PrescriptionScreenState createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _patientNameController;
  late TextEditingController _dateController;
  late TextEditingController _diagnosisController;
  late TextEditingController _followUpDateController;

  // A list of form fields for dynamic medicine entries
  List<Map<String, TextEditingController>> _medicineEntries = [];

  // Dummy list of medicines for Autocomplete
  static const List<String> _medicineList = [
    'Paracetamol', 'Ibuprofen', 'Amoxicillin', 'Aspirin', 'Metformin',
    'Lisinopril', 'Levothyroxine', 'Atorvastatin', 'Amlodipine', 'Omeprazole',
    'Azithromycin', 'Ciprofloxacin', 'Doxycycline', 'Cetirizine', 'Loratadine',
  ];

  @override
  void initState() {
    super.initState();
    _patientNameController = TextEditingController(text: widget.patientName);
    _dateController = TextEditingController(
        text: "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}");
    _diagnosisController = TextEditingController();
    _followUpDateController = TextEditingController();

    // Add initial empty medicine entry
    _addMedicineEntry();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _dateController.dispose();
    _diagnosisController.dispose();
    _followUpDateController.dispose();
    for (var entry in _medicineEntries) {
      entry['medicineName']?.dispose();
      entry['dosageAndFrequency']?.dispose();
      entry['duration']?.dispose();
      entry['specialInstructions']?.dispose();
    }
    super.dispose();
  }

  void _addMedicineEntry() {
    setState(() {
      _medicineEntries.add({
        'medicineName': TextEditingController(),
        'dosageAndFrequency': TextEditingController(),
        'duration': TextEditingController(),
        'specialInstructions': TextEditingController(),
      });
    });
  }

  void _removeMedicineEntry(int index) {
    setState(() {
      final entry = _medicineEntries.removeAt(index);
      entry['medicineName']?.dispose();
      entry['dosageAndFrequency']?.dispose();
      entry['duration']?.dispose();
      entry['specialInstructions']?.dispose();
    });
  }

  Future<void> _selectFollowUpDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _followUpDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _savePrescription() {
    if (_formKey.currentState!.validate()) {
      List<Map<String, String>> medicines = [];
      for (var entry in _medicineEntries) {
        medicines.add({
          'medicineName': entry['medicineName']!.text,
          'dosageAndFrequency': entry['dosageAndFrequency']!.text,
          'duration': entry['duration']!.text,
          'specialInstructions': entry['specialInstructions']!.text,
        });
      }

      widget.onSave({
        "doctorId": FirebaseAuth.instance.currentUser!.uid,
        "doctorName": widget.doctorDetails['name'] ?? "Dr. Alex Chen",
        "doctorSpecialty": widget.doctorDetails['specialty'] ?? "APOLLO DOCTOR",
        "clinicAddress": widget.doctorDetails['address'] ?? "123 Anywhere St., Any City",
        "patientId": widget.patientId,
        "patientName": _patientNameController.text,
        "date": _dateController.text,
        "diagnosis": _diagnosisController.text,
        "medicines": medicines,
        "followUpDate": _followUpDateController.text,
      });
    }
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
                // Doctor's details section
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

                // Patient and date details
                TextFormField(
                  controller: _patientNameController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Patient's Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
                const SizedBox(height: 20),

                // Diagnosis field
                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: "Diagnosis / Clinical Notes",
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 20),

                // Dynamic Medicine fields
                const Text("Medication", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._medicineEntries.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, TextEditingController> controllers = entry.value;
                  return _buildMedicineForm(index, controllers);
                }).toList(),

                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _addMedicineEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Medicine'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue,
                  ),
                ),
                const Divider(height: 30, thickness: 1.5, color: Color(0xFFBDC3C7)),

                // Follow-up Date field
                TextFormField(
                  controller: _followUpDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Follow-up Date / Next Visit",
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  onTap: () => _selectFollowUpDate(context),
                ),
                const SizedBox(height: 20),

                // Save button
                ElevatedButton(
                  onPressed: _savePrescription,
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

  Widget _buildMedicineForm(int index, Map<String, TextEditingController> controllers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    controllers['medicineName'] = textEditingController; // Assign controller
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      // The fix: calling onFieldSubmitted() without arguments
                      onFieldSubmitted: (String value) {
                        onFieldSubmitted();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      ),
                      validator: (v) => v!.isEmpty ? "Enter medicine" : null,
                    );
                  },
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _medicineList.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                ),
              ),
              if (_medicineEntries.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _removeMedicineEntry(index),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controllers['dosageAndFrequency'],
            decoration: const InputDecoration(
              labelText: "Dosage & Frequency (e.g., 500mg, twice daily)",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
            validator: (v) => v!.isEmpty ? "Enter dosage" : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controllers['duration'],
            decoration: const InputDecoration(
              labelText: "Duration (e.g., 7 days)",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
            validator: (v) => v!.isEmpty ? "Enter duration" : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controllers['specialInstructions'],
            decoration: const InputDecoration(
              labelText: "Special Instructions",
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
            ),
            maxLines: null,
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}
