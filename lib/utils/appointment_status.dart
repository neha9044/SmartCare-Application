// lib/utils/appointment_status.dart
enum AppointmentStatus {
  pending,
  inProgress,
  completed,
  canceled,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String toShortString() {
    return toString().split('.').last;
  }
}