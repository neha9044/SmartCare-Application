enum AppointmentStatus {
  pending,
  inProgress,
  completed,
}

extension AppointmentStatusExtension on AppointmentStatus {
  String toShortString() {
    return toString().split('.').last;
  }
}