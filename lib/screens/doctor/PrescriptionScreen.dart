import 'package:flutter/material.dart';

class PrescriptionScreen extends StatelessWidget {
  const PrescriptionScreen({Key? key, required this.onSave}) : super(key: key);

  final Function(Map<String, String>) onSave;

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    final TextEditingController _patientNameController = TextEditingController();
    final TextEditingController _ageController = TextEditingController();
    final TextEditingController _addressController = TextEditingController();
    final TextEditingController _dateController = TextEditingController();
    final TextEditingController _prescriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Prescription Template")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "APOLLO DOCTOR",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text("Dr. Alex Chen"),
                          SizedBox(height: 8),
                          Text(
                            "123 Anywhere St., Any City",
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      const Divider(height: 30, thickness: 1.5),
                      TextFormField(
                        controller: _patientNameController,
                        decoration: const InputDecoration(
                            labelText: "Patient's Name",
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Enter name" : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                            labelText: "Age", border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? "Enter age" : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                            labelText: "Address", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Enter address" : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                            labelText: "Date", border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? "Enter date" : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _prescriptionController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Enter full prescription details here...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (v) =>
                        v!.isEmpty ? "Enter prescription details" : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            onSave({
                              "doctorName": "APOLLO DOCTOR",
                              "doctorSpecialty": "Dr. Alex Chen",
                              "clinicAddress": "123 Anywhere St., Any City",
                              "name": _patientNameController.text,
                              "age": _ageController.text,
                              "address": _addressController.text,
                              "date": _dateController.text,
                              "prescription": _prescriptionController.text,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Prescription Saved!")));
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Save Prescription"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
