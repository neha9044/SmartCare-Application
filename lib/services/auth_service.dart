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

  // New method for user login
  Future<String> loginUser({
    required String email,
    required String password,
    required String userType,
  }) async {
    try {
      // Authenticate the user with Firebase Authentication
      final authResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = authResult.user!.uid;

      // Check if the user exists in the correct Firestore collection
      final userDoc = await _firestore.collection(userType.toLowerCase() + 's').doc(userId).get();

      if (userDoc.exists) {
        return userType; // Return the user type to trigger navigation
      } else {
        // If the document doesn't exist, it means the user's role is not what they selected
        await _auth.signOut(); // Sign out the user
        throw FirebaseAuthException(
          code: 'role-mismatch',
          message: 'The selected user type does not match your account.',
        );
      }
    } on FirebaseAuthException {
      rethrow; // Rethrow the exception to be handled by the UI
    } catch (e) {
      // Handle other potential errors
      throw Exception('An unexpected error occurred during login.');
    }
  }
}