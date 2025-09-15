class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String hospital;
  final String location;
  final double rating;
  final int reviewCount;
  final String experience;
  final String imageUrl;
  final List<String> availableSlots;
  final double consultationFee;
  final bool isAvailableToday;
  final String about;
  final List<String> qualifications;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.imageUrl,
    required this.availableSlots,
    required this.consultationFee,
    required this.isAvailableToday,
    required this.about,
    required this.qualifications,
  });
}