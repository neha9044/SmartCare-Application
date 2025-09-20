class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String time;
  String status;
  final int queueNumber;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.time,
    required this.status,
    required this.queueNumber,
  });

  factory Appointment.fromMap(String id, Map<dynamic, dynamic> map) {
    return Appointment(
      id: id,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      doctorId: map['doctorId'] as String,
      time: map['time'] as String,
      status: map['status'] as String,
      queueNumber: map['queueNumber'] as int,
    );
  }
}