// lib/screens/doctor/prescription_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

  late TextEditingController _dateController;
  late TextEditingController _diagnosisController;
  late TextEditingController _followUpDateController;

  // A list of form fields for dynamic medicine entries
  List<Map<String, TextEditingController>> _medicineEntries = [];

  String? _currentCity; // Variable to store the fetched city name
  bool _isFetchingLocation = false; // Flag for loading state

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(
        text: "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}");
    _diagnosisController = TextEditingController();
    _followUpDateController = TextEditingController();

    // Add initial empty medicine entry
    _addMedicineEntry();
  }

  @override
  void dispose() {
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

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      // Check and request location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      // Get current position and convert to placemark
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentCity = place.locality;
        });
      } else {
        _currentCity = null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location error: $e")),
      );
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
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
        "patientName": widget.patientName,
        "date": _dateController.text,
        "diagnosis": _diagnosisController.text,
        "medicines": medicines,
        "followUpDate": _followUpDateController.text,
      });
    }
  }

  void _showPharmacySelectionDialog() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the prescription details first.')),
      );
      return;
    }

    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select a Pharmacy'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add the search bar to the dialog
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Pharmacies',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    // Force rebuild of the dialog content to filter the list
                    (context as Element).markNeedsBuild();
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('pharmacies').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading pharmacies.'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No pharmacies found.'));
                      }

                      final allPharmacies = snapshot.data!.docs;
                      final filteredPharmacies = allPharmacies.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final pharmacyName = data['name']?.toLowerCase() ?? '';
                        final query = searchController.text.toLowerCase();
                        return pharmacyName.contains(query);
                      }).toList();

                      if (filteredPharmacies.isEmpty) {
                        return const Center(child: Text('No matching pharmacies found.'));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredPharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacyDoc = filteredPharmacies[index];
                          final pharmacyData = pharmacyDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(pharmacyData['name'] ?? 'Unknown Pharmacy'),
                            subtitle: Text(pharmacyData['location'] ?? 'No address'),
                            onTap: () {
                              Navigator.of(context).pop();
                              _showConfirmationDialog(pharmacyDoc.id, pharmacyData['name'] ?? 'Unknown Pharmacy');
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String pharmacyId, String pharmacyName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Action'),
          content: Text('Do you confirm to send the prescription to $pharmacyName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendToPharmacy(pharmacyId);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _sendToPharmacy(String pharmacyId) async {
    if (!_formKey.currentState!.validate()) return;

    List<Map<String, String>> medicines = [];
    for (var entry in _medicineEntries) {
      medicines.add({
        'medicineName': entry['medicineName']!.text,
        'dosageAndFrequency': entry['dosageAndFrequency']!.text,
        'duration': entry['duration']!.text,
        'specialInstructions': entry['specialInstructions']!.text,
      });
    }

    try {
      await FirebaseFirestore.instance.collection('pharmacy_orders').add({
        'pharmacyId': pharmacyId,
        'patientId': widget.patientId,
        'patientName': widget.patientName,
        'doctorId': FirebaseAuth.instance.currentUser!.uid,
        'doctorName': widget.doctorDetails['name'] ?? "Dr. Alex Chen",
        'prescription': medicines,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // e.g., pending, completed, picked_up
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription sent to pharmacy successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send prescription. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Date & Diagnosis Row
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactTextField(
                        controller: _dateController,
                        label: "Date",
                        readOnly: true,
                        prefixIcon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildCompactTextField(
                        controller: _diagnosisController,
                        label: "Diagnosis / Clinical Notes",
                        prefixIcon: Icons.medical_services,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Medicines Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Medications",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E3A59),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addMedicineEntry,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text("Add", style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Medicines List - Scrollable
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _medicineEntries.isEmpty
                        ? const Center(
                      child: Text(
                        "No medications added",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _medicineEntries.length,
                      itemBuilder: (context, index) => _buildCompactMedicineForm(index),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Follow-up Date & Save Button Row
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactTextField(
                        controller: _followUpDateController,
                        label: "Next Visit",
                        readOnly: true,
                        prefixIcon: Icons.event,
                        onTap: () => _selectFollowUpDate(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Save Button - Inline
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _savePrescription,
                        icon: const Icon(Icons.save, size: 20),
                        label: const Text("Save Prescription"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // New button to send to pharmacy
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showPharmacySelectionDialog,
                    icon: const Icon(Icons.local_pharmacy_outlined, size: 20),
                    label: const Text("Send to Pharmacy"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: const Color(0xFF1E88E5))
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
      ),
    );
  }

  Widget _buildCompactMedicineForm(int index) {
    final controllers = _medicineEntries[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Medicine Name & Remove Button
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers['medicineName'],
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Medicine Name',
                    labelStyle: const TextStyle(fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Enter medicine" : null,
                ),
              ),
              if (_medicineEntries.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  onPressed: () => _removeMedicineEntry(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Dosage, Duration & Instructions in a grid layout
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controllers['dosageAndFrequency'],
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Dosage',
                    hintText: '500mg, 2x daily',
                    labelStyle: const TextStyle(fontSize: 10),
                    hintStyle: const TextStyle(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Enter dosage" : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: controllers['duration'],
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    hintText: '7 days',
                    labelStyle: const TextStyle(fontSize: 10),
                    hintStyle: const TextStyle(fontSize: 10),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "Enter duration" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Special Instructions
          TextFormField(
            controller: controllers['specialInstructions'],
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              labelText: 'Special Instructions',
              hintText: 'After meals, with water',
              labelStyle: const TextStyle(fontSize: 10),
              hintStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}