// lib/screens/patient/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartcare_app/models/doctor.dart';
import 'package:smartcare_app/constants/colors.dart';
import 'package:smartcare_app/services/chat_service.dart';
import 'package:smartcare_app/utils/chat_status.dart';
import 'package:smartcare_app/services/auth_service.dart';

class PatientChatScreen extends StatefulWidget {
  final Doctor doctor;
  final String? chatId;

  const PatientChatScreen({Key? key, required this.doctor, this.chatId}) : super(key: key);

  @override
  _PatientChatScreenState createState() => _PatientChatScreenState();
}

class _PatientChatScreenState extends State<PatientChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  User? _currentUser;
  String? _chatId;
  String? _chatStatus;
  bool _isChatActive = false;

  final List<String> _initialButtons = [
    'I have a question about my medication.',
    'I need a follow-up appointment.',
    'I have a quick question about a recent test result.',
    'I have a new symptom to report.'
  ];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _chatId = widget.chatId;
    if (_chatId == null) {
      // Check for an existing chat if one is not passed
      _checkExistingChat();
    } else {
      _listenToChatUpdates();
    }
  }

  void _checkExistingChat() async {
    final existingChatId = await _chatService.getExistingChatId(
      patientId: _currentUser!.uid,
      doctorId: widget.doctor.id,
    );
    if (existingChatId != null) {
      setState(() {
        _chatId = existingChatId;
      });
      _listenToChatUpdates();
    }
  }

  void _listenToChatUpdates() {
    if (_chatId != null) {
      _chatService.getChatStream(_chatId!).listen((chatSnapshot) {
        if (chatSnapshot.exists) {
          final status = chatSnapshot.get('status');
          setState(() {
            _chatStatus = status;
            _isChatActive = status == ChatStatus.active.toShortString();
          });
          if (status == ChatStatus.closed.toShortString() || status == ChatStatus.declined.toShortString()) {
            _resetChatState();
          }
        }
      });
    }
  }

  void _resetChatState() {
    setState(() {
      _chatId = null;
      _isChatActive = false;
      _chatStatus = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This chat has ended and is now archived.')),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _chatId != null) {
      _chatService.sendMessage(
        chatId: _chatId!,
        senderId: _currentUser!.uid,
        text: _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _createChat(String initialMessage) async {
    if (_currentUser == null) return;
    setState(() {
      _chatId = 'creating';
    });
    try {
      // FETCHING PATIENT'S NAME
      final patientData = await _authService.getPatientData(_currentUser!.uid);
      final patientName = patientData['name'] ?? 'Unknown Patient';

      final newChatId = await _chatService.createChat(
        patientId: _currentUser!.uid,
        doctorId: widget.doctor.id,
        initialMessage: initialMessage,
        patientName: patientName, // ADDED: Passing the patient's name
      );
      setState(() {
        _chatId = newChatId;
      });
      _listenToChatUpdates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to doctor.')),
      );
    } catch (e) {
      setState(() {
        _chatId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start chat. Please try again.')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildInitialView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Start a conversation with Dr. ${widget.doctor.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        ..._initialButtons.map((text) => Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton(
            onPressed: () => _createChat(text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        _buildChatStatusHeader(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getMessages(_chatId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Start the conversation!'));
              }
              _scrollToBottom();
              final messages = snapshot.data!.docs;
              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final messageData = messages[index].data() as Map<String, dynamic>;
                  final isMe = messageData['senderId'] == _currentUser!.uid;
                  return _buildMessageBubble(messageData['text'], isMe);
                },
              );
            },
          ),
        ),
        if (_isChatActive)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildChatStatusHeader() {
    String statusText;
    Color statusColor;

    if (_chatStatus == ChatStatus.pending.toShortString()) {
      statusText = "Waiting for Dr. ${widget.doctor.name} to accept...";
      statusColor = Colors.orange;
    } else if (_chatStatus == ChatStatus.active.toShortString()) {
      statusText = "Chatting with Dr. ${widget.doctor.name}";
      statusColor = Colors.green;
    } else {
      statusText = "Chat is unavailable.";
      statusColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: statusColor.withOpacity(0.1),
      child: Center(
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primaryColor : AppColors.lightGrey.withOpacity(0.2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Dr. ${widget.doctor.name}'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _chatId == null || _chatId == 'creating'
          ? Center(
        child: _chatId == 'creating' ? const CircularProgressIndicator() : _buildInitialView(),
      )
          : _buildChatView(),
    );
  }
}