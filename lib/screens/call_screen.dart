import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../widgets/widgets.dart';

/// Call screen - Voice-first interface with Phone Call aesthetic
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with TickerProviderStateMixin {
  // Speech recognition
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _currentUtterance = '';
  Timer? _silenceTimer;
  Timer? _interruptionTimer;
  
  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String _lastAIResponse = '';

  // Call state
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true; // Default to speaker for voice assistance
  Timer? _callTimer;
  int _callDurationSeconds = 0;

  // UI Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cleanupCall();
    _pulseController.dispose();
    super.dispose();
  }

  void _cleanupCall() {
    _silenceTimer?.cancel();
    _interruptionTimer?.cancel();
    _callTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    
    if (_isCallActive && mounted) {
      ref.read(chatProvider.notifier).disconnect();
    }
  }

  // --- Initialization ---

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          if (error.errorMsg == 'error_no_match' && _isCallActive && !_isMuted && !_isSpeaking) {
            _startListening();
          } else if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          if (status != 'done' && status != 'notListening') return;
          if (mounted) setState(() => _isListening = false);
          if (_isCallActive && !_isMuted && !_isSpeaking) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _isCallActive && !_isMuted && !_isSpeaking && !_isListening) {
                _startListening();
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    
    _flutterTts.setStartHandler(() {
      if (_isListening) _speechToText.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = true;
          _isListening = false;
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
      if (_isCallActive && !_isMuted) {
        Future.delayed(const Duration(milliseconds: 500), _startListening);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
      debugPrint('DEBUG: TTS Error: $msg');
    });
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      debugPrint('DEBUG: TTS speaking: "$text"');
      await _flutterTts.speak(text);
    }
  }

  // --- Call Logic ---

  Future<void> _startCall() async {
    debugPrint('DEBUG: _startCall initiated');

    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      debugPrint('DEBUG: Microphone permission denied');
      return;
    }

    setState(() => _isCallActive = true);

    // 1. Create Conversation
    try {
      debugPrint('DEBUG: Creating conversation for voice call...');
      final title = 'Voice Call ${DateFormat('MMM d, h:mm a').format(DateTime.now())}';
      final conversation = await ref.read(conversationProvider.notifier).createConversation(title);

      if (conversation == null) {
        debugPrint('DEBUG: Failed to create conversation object');
        throw Exception('Failed to create conversation');
      }
      debugPrint('DEBUG: Conversation created with ID: ${conversation.id}');

      // 2. Connect WebSocket via Provider
      debugPrint('DEBUG: Connecting via ChatProvider...');
      await ref.read(chatProvider.notifier).connect(conversationId: conversation.id);
      debugPrint('DEBUG: ChatProvider connected');

      // 3. Start Timer & Listening
      _startTimer();
      _speak("Hello, I am Mom Launchpad AI. How can I help you today?");
      // _startListening() will be triggered by _flutterTts.setCompletionHandler
    } catch (e) {
      debugPrint('DEBUG: Failed to start call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
        _endCall();
      }
    }
  }

  void _endCall() {
    debugPrint('DEBUG: _endCall initiated');
    _cleanupCall();
    setState(() {
      _isCallActive = false;
      _isListening = false;
      _isSpeaking = false;
      _callDurationSeconds = 0;
      _lastAIResponse = '';
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDurationSeconds++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _callActivityLabel() {
    if (_isSpeaking) return 'Speaking...';
    if (_isListening) return 'Listening...';
    return '...';
  }

  Future<void> _startListening() async {
    if (!_speechEnabled || _isMuted || !_isCallActive || _isSpeaking) return;
    
    setState(() => _isListening = true);
    await _speechToText.listen(
      onResult: (result) {
        setState(() => _currentUtterance = result.recognizedWords);

        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          _sendMessage(result.recognizedWords);
        }

        // VAD logic (timers) would go here similar to previous implementation
        _silenceTimer?.cancel();
        if (!result.finalResult && result.recognizedWords.isNotEmpty) {
          _silenceTimer = Timer(const Duration(seconds: 2), () {
            if (_isListening) {
              _speechToText.stop();
              if (_currentUtterance.isNotEmpty) _sendMessage(_currentUtterance);
            }
          });
        }
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 5),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text.trim());
    setState(() => _currentUtterance = '');
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Listen for AI responses
    ref.listen(chatProvider, (_, next) {
      if (!_isCallActive) return;
      if (next.messages.isNotEmpty && !next.messages.last.isUser) {
        final msg = next.messages.last;
        if (!msg.isStreaming && msg.content.isNotEmpty && msg.content != _lastAIResponse) {
          _lastAIResponse = msg.content;
          _flutterTts.speak(msg.content);
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937), // Dark grey background
      body: SafeArea(
        child: Stack(
          children: [
            if (!_isCallActive) _buildStartCallScreen() else _buildActiveCallScreen(chatState),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCallScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk_rounded, size: 64, color: AppColors.primaryPink),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start Voice Call',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Talk to your AI assistant naturally',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: 200,
            child: AppButton(
              label: 'Start Call',
              onPressed: _startCall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCallScreen(ChatState chatState) {
    return Column(
      children: [
        // Top Status
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 14, color: Colors.white54),
              const SizedBox(width: 8),
              Text(
                'End-to-end Encrypted',
                style: AppTypography.caption.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
        
        const Spacer(),

        // Avatar & Timer
        ScaleTransition(
          scale: _isSpeaking || _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              image: DecorationImage(
                image: const AssetImage('assets/images/ai_avatar_placeholder.png'), // Need to ensure asset exists or use icon
                fit: BoxFit.cover,
                onError: (Object? error, StackTrace? stackTrace) {},
              ),
              boxShadow: [
                if (_isSpeaking)
                  BoxShadow(color: AppColors.primaryPink.withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
                if (_isListening)
                  BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: const Icon(Icons.person, size: 80, color: Colors.white24),
          ),
        ),
        const SizedBox(height: 32),
        
        Text(
          'MomLaunchpad AI',
          style: AppTypography.headingLarge.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_callDurationSeconds),
          style: AppTypography.bodyText.copyWith(color: Colors.white70),
        ),
        
        // Status Text (Listening/Speaking)
        const SizedBox(height: 16),
        Text(
          _callActivityLabel(),
          style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.w600),
        ),

        // Live Transcript Overlay (Subtle)
        if (_currentUtterance.isNotEmpty || _lastAIResponse.isNotEmpty)
          Container(
             margin: const EdgeInsets.all(24),
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: Colors.black45,
               borderRadius: BorderRadius.circular(12),
             ),
             child: Text(
               _isSpeaking ? _lastAIResponse : _currentUtterance,
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
               textAlign: TextAlign.center,
               style: const TextStyle(color: Colors.white70, fontSize: 14),
             ),
          ),

        const Spacer(),

        // Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          decoration: const BoxDecoration(
            color: Color(0xFF2D3748),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                label: 'Mute',
                isActive: _isMuted,
                onTap: () => setState(() => _isMuted = !_isMuted),
              ),
              _buildEndCallButton(),
              _buildControlButton(
                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                label: 'Speaker',
                isActive: _isSpeakerOn,
                onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
              ),
            ],
          ),
        ),
        // Debug input for emulator
        if (true) // In a real app check kDebugMode
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextButton(
              onPressed: () => _showDebugInputDialog(),
              child: const Text('Debug: Type Message (Emulator)', style: TextStyle(color: Colors.white24)),
            ),
          ),
      ],
    );
  }

  void _showDebugInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Voice Input'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Type what you want to say...'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                 // Simulate recognition
                 setState(() => _currentUtterance = controller.text);
                 Future.delayed(const Duration(milliseconds: 500), () {
                   _sendMessage(controller.text);
                 });
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: _endCall,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [
             BoxShadow(color: AppColors.error, blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
      ),
    );
  }
}
