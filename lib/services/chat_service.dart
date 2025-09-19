// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartcare_app/utils/chat_status.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new chat
  Future<String> createChat({
    required String patientId,
    required String doctorId,
    required String initialMessage,
    required String patientName,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').add({
        'patientId': patientId,
        'doctorId': doctorId,
        'patientName': patientName,
        'initialMessage': initialMessage,
        'status': ChatStatus.pending.toShortString(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return chatDoc.id;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Get chats for a doctor
  Stream<QuerySnapshot> getDoctorChats(String doctorId) {
    return _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Alternative method without ordering (if index creation fails)
  Stream<QuerySnapshot> getDoctorChatsNoOrder(String doctorId) {
    return _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots();
  }

  // Get chats for a patient
  Stream<QuerySnapshot> getPatientChats(String patientId) {
    return _firestore
        .collection('chats')
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get a specific chat stream
  Stream<DocumentSnapshot> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots();
  }

  // Get messages for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      // Add message to messages subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat's last activity
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': text,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Update chat status
  Future<void> updateChatStatus(String chatId, ChatStatus status) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({
        'status': status.toShortString(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating chat status: $e');
      rethrow;
    }
  }

  // Check if there's an existing active chat between patient and doctor
  Future<String?> getExistingChatId({
    required String patientId,
    required String doctorId,
  }) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('patientId', isEqualTo: patientId)
          .where('doctorId', isEqualTo: doctorId)
          .where('status', whereIn: [
        ChatStatus.pending.toShortString(),
        ChatStatus.active.toShortString()
      ])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error checking existing chat: $e');
      return null;
    }
  }

  // Get chat by ID
  Future<DocumentSnapshot?> getChatById(String chatId) async {
    try {
      return await _firestore
          .collection('chats')
          .doc(chatId)
          .get();
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  // Delete a chat and its messages
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messages.docs) {
        await doc.reference.delete();
      }

      // Delete the chat document
      await _firestore
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  // Get chat statistics for a doctor
  Future<Map<String, int>> getDoctorChatStats(String doctorId) async {
    try {
      final chats = await _firestore
          .collection('chats')
          .where('doctorId', isEqualTo: doctorId)
          .get();

      int pending = 0;
      int active = 0;
      int closed = 0;
      int declined = 0;

      for (var doc in chats.docs) {
        final status = doc.data()['status'] as String;
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'active':
            active++;
            break;
          case 'closed':
            closed++;
            break;
          case 'declined':
            declined++;
            break;
        }
      }

      return {
        'total': chats.docs.length,
        'pending': pending,
        'active': active,
        'closed': closed,
        'declined': declined,
      };
    } catch (e) {
      print('Error getting chat stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'active': 0,
        'closed': 0,
        'declined': 0,
      };
    }
  }

  // Search chats by patient name
  Stream<QuerySnapshot> searchDoctorChatsByPatientName(String doctorId, String searchTerm) {
    return _firestore
        .collection('chats')
        .where('doctorId', isEqualTo: doctorId)
        .where('patientName', isGreaterThanOrEqualTo: searchTerm)
        .where('patientName', isLessThan: searchTerm + 'z')
        .orderBy('patientName')
        .snapshots();
  }
}