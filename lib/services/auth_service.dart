import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

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
      final authResult = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final userId = authResult.user!.uid;

      String collectionPath;
      Map<String, dynamic> userData;

      if (userType == 'Patient') {
        collectionPath = 'patients';
        userData = {'id': userId, 'userType': userType, 'name': fullName, 'email': email, 'phone': phoneNumber, 'created_at': FieldValue.serverTimestamp()};
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
      } else {
        collectionPath = 'pharmacies';
        userData = {'id': userId, 'userType': userType, 'name': fullName, 'email': email, 'phone': phoneNumber, 'licenseNumber': licenseNumber, 'created_at': FieldValue.serverTimestamp()};
      }

      await _firestore.collection(collectionPath).doc(userId).set(userData);

    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<bool> checkUserType({required String userId, required String expectedUserType}) async {
    final collectionPath = _getCollectionPathForUserType(expectedUserType);
    final userDoc = await _firestore.collection(collectionPath).doc(userId).get();
    return userDoc.exists;
  }

  String _getCollectionPathForUserType(String userType) {
    switch (userType) {
      case 'Patient': return 'patients';
      case 'Doctor': return 'doctors';
      case 'Pharmacy': return 'pharmacies';
      default: throw Exception('Invalid user type');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
