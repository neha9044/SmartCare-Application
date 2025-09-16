import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUserWithFirestore({
    required String email,
    required String password,
    required String userType,
    required String fullName,
    required String phoneNumber,
    String? specialty,
    String? licenseNumber,
  }) async {
    try {
      // 1. Authenticate the user with Firebase Authentication
      final authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = authResult.user!.uid;

      // 2. Determine the Firestore collection and user data based on user type
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
          'created_at': FieldValue.serverTimestamp(),
        };
      } else { // 'Pharmacy'
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
      }

      // 3. Save the user data to Firestore
      await _firestore.collection(collectionPath).doc(userId).set(userData);

    } on FirebaseAuthException {
      rethrow; // Rethrow the exception to be handled by the UI
    } catch (e) {
      rethrow; // Rethrow any other exceptions
    }
  }
}