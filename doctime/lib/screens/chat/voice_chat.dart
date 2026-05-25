import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../patient/doctor_search_screen.dart';
import '../../utils/constants.dart';

class VoiceChat extends StatefulWidget {
  const VoiceChat({super.key});

  @override
  State<VoiceChat> createState() => _VoiceChatState();
}

class _VoiceChatState extends State<VoiceChat> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = context.read<ChatProvider>();
      _chatProvider.addListener(_onProviderChange);
      _chatProvider.initialize();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_onProviderChange);
    _pulseController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (_chatProvider.hasConnectionError && mounted) {
      _showConnectionError();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatProvider>().sendTextMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _showConnectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Connection error, check your connection and try again!'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        if (chat.messages.isNotEmpty) _scrollToBottom();
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildAppBar(chat),
                Expanded(child: _buildMessageList(chat)),
              ],
            ),
          ),
          bottomNavigationBar: chat.isTriageComplete
              ? _buildCompletionButton(chat)
              : _buildInputBar(chat),
        );
      },
    );
  }

  Widget _buildAppBar(ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF0F2F5),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF2C2C2C),
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 12),
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryBlue,
                ),
                child: Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Chat',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  chat.isListening
                      ? 'Recording...'
                      : chat.isSpeaking
                          ? 'Playing...'
                          : 'Online',
                  style: TextStyle(
                    color: chat.isListening
                        ? kPrimaryBlue
                        : chat.isSpeaking
                            ? kPrimaryBlue
                            : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chat) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        final message = chat.messages[index];
        return _ChatBubble(
          message: message,
          onSpeak: () => chat.speakMessage(message),
          isSpeaking: chat.isSpeaking,
        );
      },
    );
  }


  Widget _buildInputBar(ChatProvider chat) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 14.5,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 14.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (chat.isListening) {
                chat.stopListening();
              } else {
                chat.startListening();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: chat.isListening ? _pulseAnimation.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chat.isListening ? kPrimaryBlue : Color(0xFFF0F2F5),
                  boxShadow: chat.isListening
                      ? [
                          BoxShadow(
                            color: kPrimaryBlue.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  chat.isListening
                      ? Icons.stop_rounded
                      : Icons.mic_none_rounded,
                  color: chat.isListening ? Colors.white : kPrimaryBlue,
                  size: 22,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryBlue,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionButton(ChatProvider chat) {
    final Color backgroundColor;
    final IconData icon;
    final String label;
    final VoidCallback onPressed;

    switch (chat.triageUrgency) {
      case 'red':
        backgroundColor = Colors.red;
        icon = Icons.warning_amber_rounded;
        label = 'EMERGENCY: Call Ambulance';
        onPressed = () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Go to the Emergency Room immediately or call your local emergency number!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        };
        break;

      case 'yellow':
        backgroundColor = const Color(0xFF6C63FF);
        icon = Icons.search_rounded;
        label = 'Find ${chat.recommendedSpecialty} Doctors';
        onPressed = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorSearchScreen(
                initialSpecialty: chat.recommendedSpecialty,
              ),
            ),
          );
        };
        break;

      case 'green':
      default:
        backgroundColor = Colors.green;
        icon = Icons.home_rounded;
        label = 'Understood, Back to Home';
        onPressed = () => Navigator.pop(context);
        break;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white),
            label: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onSpeak;
  final bool isSpeaking;

  const _ChatBubble({
    required this.message,
    required this.onSpeak,
    required this.isSpeaking,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(
        top: 3,
        bottom: 3,
        left: isUser ? 52 : 0,
        right: isUser ? 0 : 52,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Container(
              width: 30,
              height: 30,
              margin: EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryBlue,
              ),
              child: Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Row(
              mainAxisAlignment:
                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isUser) ...[_buildVoiceBtn(), SizedBox(width: 5)],
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? kPrimaryBlue : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : Color(0xFF1A1A2E),
                            fontSize: 14.5,
                            height: 1.45,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.timestamp),
                              style: TextStyle(
                                color: isUser
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Color(0xFFAAAAAA),
                                fontSize: 10.5,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isUser) ...[SizedBox(width: 5), _buildVoiceBtn()],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBtn() {
    return GestureDetector(
      onTap: onSpeak,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.volume_up_outlined,
          size: 14,
          color: Color(0xFF6C63FF),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
