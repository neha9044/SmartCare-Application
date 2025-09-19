// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/utils/appointment_status.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// Register a new user (Patient, Doctor, or Pharmacy) with Firestore
  Future<void> registerUserWithFirestore({
    required String email,
    required String password,
    required String userType,
    required String fullName,
    required String phoneNumber,
    String? specialty,
    String? licenseNumber,
    String? experience,
    String? qualification,
    String? location,
    String? clinicName,
    String? clinicLocation,
    double? consultationFees,
  }) async {
    try {
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userId = authResult.user!.uid;

      String collectionPath;
      Map<String, dynamic> userData;

      if (userType == 'Patient') {
        collectionPath = 'patients';
        userData = {
          'id': userId,
          'userType': userType,
          'name': fullName,
          'email': email,
          'phone': phoneNumber,
          'created_at': FieldValue.serverTimestamp(),
        };
      } else if (userType == 'Doctor') {
        collectionPath = 'doctors';
        userData = {
          'id': userId,
          'userType': userType,
          'name': fullName,
          'email': email,
          'phone': phoneNumber,
          'specialty': specialty,
          'licenseNumber': licenseNumber,
          'experience': experience,
          'qualification': qualification,
          'location': location,
          'clinicName': clinicName,
          'clinicLocation': clinicLocation,
          'consultationFees': consultationFees,
          'created_at': FieldValue.serverTimestamp(),
        };
      } else if (userType == 'Pharmacy') {
        collectionPath = 'pharmacies';
        userData = {
          'id': userId,
          'userType': userType,
          'name': fullName,
          'email': email,
          'phone': phoneNumber,
          'licenseNumber': licenseNumber,
          'created_at': FieldValue.serverTimestamp(),
        };
      } else {
        throw Exception('Invalid user type');
      }

      userData.removeWhere((key, value) => value == null);

      await _firestore.collection(collectionPath).doc(userId).set(userData);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered.');
      } else if (e.code == 'weak-password') {
        throw Exception('The password is too weak.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is invalid.');
      } else {
        throw Exception(e.message ?? 'Authentication failed');
      }
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }
  }

  /// Sign in a user
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Invalid password.');
      } else {
        throw Exception(e.message ?? 'Login failed');
      }
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Check if a user exists in a specific collection (by type)
  Future<bool> checkUserType({
    required String userId,
    required String expectedUserType,
  }) async {
    final collectionPath = _getCollectionPathForUserType(expectedUserType);
    final userDoc = await _firestore.collection(collectionPath).doc(userId).get();
    return userDoc.exists;
  }

  String _getCollectionPathForUserType(String userType) {
    switch (userType) {
      case 'Patient':
        return 'patients';
      case 'Doctor':
        return 'doctors';
      case 'Pharmacy':
        return 'pharmacies';
      default:
        throw Exception('Invalid user type');
    }
  }

  /// Fetch patient data and return it as a map
  Future<Map<String, dynamic>> getPatientData(String patientId) async {
    final doc = await _firestore.collection('patients').doc(patientId).get();
    return doc.data() ?? {};
  }

  /// Fetch doctor data and return it as a map
  Future<Map<String, dynamic>> getDoctorData(String doctorId) async {
    final doc = await _firestore.collection('doctors').doc(doctorId).get();
    return doc.data() ?? {};
  }

  /// Save a new appointment
  Future<void> saveAppointment({
    required String doctorId,
    required String patientId,
    required String patientName,
    required DateTime date,
    required String time,
    required String status,
  }) async {
    await _firestore.collection('appointments').add({
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}