import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

// 🎨 Color setup
class AppColors {
  static const Color primaryColor = Color(0xFF42A5F5);
}

// ==========================================================
// 🌿 HEALTH ASSISTANT CHATBOT (Gemini API)
// ==========================================================
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  static const _apiKey =
      'AIzaSyBaHn01VDcZ2MU2XSKhoH1S5hKi5Yu6DQM'; // Replace with your Gemini API key

  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final GenerativeModel _model;
  bool _isLoading = false;

  // Supported Languages
  String _selectedLanguage = 'English';
  final List<String> _languages = [
    'English',
    'Hindi',
    'Marathi',
    'Gujarati',
    'Bengali',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Arabic',
    'Chinese',
    'Japanese',
    'Korean',
    'Russian',
  ];

  final _systemInstruction =
      'You are a friendly healthcare assistant. Provide safe, short answers with helpful home remedies '
      'and general advice. Never prescribe medication or diagnose a disease.';

  @override
  void initState() {
    super.initState();
    if (_apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY') {
      _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    }
    Future.microtask(() => _addInitialMessage());
  }

  void _addInitialMessage() {
    _addMessage(
      'Hello 👋 I’m your health assistant. I can share general info and home remedies — '
          'but not medical diagnoses. Use the button below to start a formal diagnosis check.',
      isUser: false,
    );
  }

  void _addMessage(String text, {required bool isUser}) {
    setState(() {
      _messages.add({'text': text, 'isUser': isUser});
    });

    Future.delayed(
      const Duration(milliseconds: 100),
          () => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY') {
      _addMessage('Error: Gemini API Key not configured.', isUser: false);
      return;
    }

    final userText = _textController.text.trim();
    _addMessage(userText, isUser: true);
    _textController.clear();
    setState(() => _isLoading = true);

    try {
      final language = _selectedLanguage;
      final prompt = '''
$_systemInstruction 
User prefers replies in "$language" — always write in that language’s native script (not English letters).
Include natural, cultural, and safe home remedies when appropriate.
User message: "$userText"
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final reply = response.text ?? 'No response generated.';
      _addMessage(reply, isUser: false);
    } catch (e) {
      _addMessage('Error: $e', isUser: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Assistant'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          // 🌍 Language Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Select Language',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
          ),

          // 💬 Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['isUser'] as bool;
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primaryColor.withOpacity(0.85)
                          : const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser
                            ? const Radius.circular(16)
                            : const Radius.circular(4),
                        bottomRight: isUser
                            ? const Radius.circular(4)
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🩺 Diagnosis Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DecisionChatbotScreen()),
                );
              },
              icon: const Icon(Icons.local_hospital, color: Colors.white),
              label: const Text(
                'Open Diagnosis Chatbot',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask a health question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primaryColor,
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// 🤖 DECISION CHATBOT (Flask-based Diagnosis)
// ==========================================================
class DecisionChatbotScreen extends StatefulWidget {
  const DecisionChatbotScreen({Key? key}) : super(key: key);

  @override
  State<DecisionChatbotScreen> createState() => _DecisionChatbotScreenState();
}

class _DecisionChatbotScreenState extends State<DecisionChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  String _currentInputType = 'waiting';
  List<String> _currentOptions = [];

  // ⚠️ Replace with your PC's IP Address
  final String flaskUrl = 'http://192.168.0.100:5000/chat';
  final String sessionId = 'user123';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _sendMessage("start", isUser: false));
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({'text': text, 'isUser': isUser});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(
        const Duration(milliseconds: 100),
            () => _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Future<void> _sendMessage(String text, {required bool isUser}) async {
    if (text.trim().isEmpty && text.toLowerCase() != 'start') return;
    if (isUser) _addMessage(text, true);

    _controller.clear();
    setState(() {
      _isLoading = true;
      _currentInputType = 'waiting';
    });

    try {
      final response = await http.post(
        Uri.parse(flaskUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId, 'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final replyText = data['reply']?.toString() ?? 'No response';
        setState(() {
          _currentInputType = data['type'] ?? 'text_input';
          _currentOptions = (data['options'] as List?)?.cast<String>() ?? [];
        });
        _addMessage(replyText, false);
      } else {
        _addMessage('Error: Server responded with status ${response.statusCode}', false);
        _addMessage('Check Flask URL ($flaskUrl) and firewall settings.', false);
        setState(() => _currentInputType = 'final_advice');
      }
    } catch (e) {
      _addMessage('Error: Could not connect to the server.', false);
      _addMessage('Ensure your Flutter device and PC are on the same Wi-Fi.', false);
      setState(() => _currentInputType = 'final_advice');
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis Chatbot'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primaryColor.withOpacity(0.9)
                          : const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      msg['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        height: 1.4,
                        fontWeight:
                        isUser ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    // 1️⃣ Selection Chips
    if (_currentInputType == 'selection' && _currentOptions.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 8.0,
          children: List.generate(_currentOptions.length, (index) {
            return ActionChip(
              label: Text(
                '${index + 1}) ${_currentOptions[index]}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: AppColors.primaryColor,
              onPressed: () => _sendMessage(index.toString(), isUser: true),
            );
          }),
        ),
      );
    }

    // 2️⃣ Yes/No Buttons
    if (_currentInputType == 'yes_no_question') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                onPressed: () => _sendMessage('yes', isUser: true),
                child:
                const Text('Yes', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.grey[400]),
                onPressed: () => _sendMessage('no', isUser: true),
                child:
                const Text('No', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      );
    }

    // 3️⃣ Text or Number Input
    if (_currentInputType == 'text_input' ||
        _currentInputType == 'number_input') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: _currentInputType == 'number_input'
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: _currentInputType == 'number_input'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [],
                decoration: InputDecoration(
                  hintText: _currentInputType == 'number_input'
                      ? 'Enter number of days...'
                      : 'Type your symptom...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
                onSubmitted: (text) => _sendMessage(text, isUser: true),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_controller.text, isUser: true),
              ),
            )
          ],
        ),
      );
    }

    // 4️⃣ Fallback / End State
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _currentInputType == 'final_advice'
            ? 'Conversation finished. Type "start" to begin a new check.'
            : 'Waiting for response...',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}