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
  final String about;
  final List<String> qualifications;
  final double? latitude;
  final double? longitude;
  final Map<String, List<String>> availableSchedule; // UPDATED to Map<String, List<String>>
  final double consultationFee;
  final bool isAvailableToday;

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
    required this.availableSchedule,
    required this.consultationFee,
    required this.isAvailableToday,
    required this.about,
    required this.qualifications,
    this.latitude,
    this.longitude,

  });
}