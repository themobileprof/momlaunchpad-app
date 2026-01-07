import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

/// Call screen - Voice-first interface with STT/TTS
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> with WidgetsBindingObserver {
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
  String _sentenceBuffer = '';
  String _lastSpokenContent = '';
  String _lastAIResponse = ''; // Store last complete AI response
  bool _wasInterrupted = false;
  
  // Call state
  bool _isConnected = false;
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _showTranscript = false;
  
  // VAD settings
  static const Duration _silenceThreshold = Duration(seconds: 2);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _initTts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _silenceTimer?.cancel();
    _interruptionTimer?.cancel();
    _speechToText.stop();
    _flutterTts.stop();
    
    if (_isCallActive) {
      _endCall();
    }
    if (_isConnected) {
      ref.read(chatProvider.notifier).disconnect();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() => _isListening = false);
        },
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      _speechEnabled = false;
    }
  }

  /// Request microphone permission with better UX
  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      // First time or user previously denied - request again
      final result = await Permission.microphone.request();
      if (result.isGranted) {
        // Re-initialize speech after permission granted
        await _initSpeech();
        return true;
      }
    }
    
    if (status.isPermanentlyDenied || await Permission.microphone.isPermanentlyDenied) {
      // Show dialog with option to open settings
      if (!mounted) return false;
      
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Microphone Access Required'),
          content: const Text(
            'Voice calling requires microphone access. Please enable it in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      
      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
      return false;
    }
    
    return false;
  }

  /// Initialize text-to-speech
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Natural pace
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Callbacks
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
      // Resume listening after speaking (unless already listening from interruption)
      if (_isCallActive && !_isMuted && !_isListening && !_wasInterrupted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_isCallActive && !_isMuted) {
            _startListening();
          }
        });
      }
      _wasInterrupted = false; // Reset interruption flag
    });
    
    _flutterTts.setErrorHandler((msg) {
      print('TTS error: $msg');
      setState(() => _isSpeaking = false);
    });
  }

  /// Connect to WebSocket
  Future<void> _connectWebSocket() async {
    await ref.read(chatProvider.notifier).connect();
    setState(() {
      _isConnected = ref.read(chatProvider).isConnected;
    });
  }

  /// Start voice call
  Future<void> _startCall() async {
    // Request permission proactively
    final hasPermission = await _requestMicrophonePermission();
    
    if (!hasPermission || !_speechEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone access is required for voice calls'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await _connectWebSocket();
    setState(() {
      _isCallActive = true;
      _lastSpokenContent = '';
    });

    // Start listening immediately
    await Future.delayed(const Duration(milliseconds: 500));
    _startListening();
  }

  /// End voice call
  void _endCall() {
    _stopListening();
    _interruptionTimer?.cancel();
    _flutterTts.stop();
    
    setState(() {
      _isCallActive = false;
      _isMuted = false;
      _isListening = false;
      _isSpeaking = false;
      _currentUtterance = '';
      _sentenceBuffer = '';
      _lastSpokenContent = '';
      _lastAIResponse = '';
    });

    // Disconnect WebSocket
    ref.read(chatProvider.notifier).disconnect();
    setState(() {
      _isConnected = false;
    });
  }

  /// Start listening with Voice Activity Detection
  Future<void> _startListening() async {
    if (!_speechEnabled || _isMuted || !_isCallActive) return;

    setState(() {
      _isListening = true;
      _currentUtterance = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _currentUtterance = result.recognizedWords;
        });

        // SMART INTERRUPTION: Wait 2 seconds before stopping AI (filter coughs/quick sounds)
        if (_isSpeaking && result.recognizedWords.trim().isNotEmpty) {
          _interruptionTimer?.cancel();
          _interruptionTimer = Timer(const Duration(seconds: 2), () {
            // User has been speaking for 2 seconds - genuine interruption
            _flutterTts.stop();
            _sentenceBuffer = ''; // Clear buffer
            _wasInterrupted = true;
            setState(() => _isSpeaking = false);
          });
        }

        // Voice Activity Detection: Reset silence timer on speech
        _silenceTimer?.cancel();
        if (!result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _silenceTimer = Timer(_silenceThreshold, () {
            // User stopped speaking for 2 seconds
            _stopListeningAndSend();
          });
        }
      },
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,
      listenFor: const Duration(seconds: 30), // Max listen duration
    );
  }

  /// Stop listening
  void _stopListening() {
    _silenceTimer?.cancel();
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  /// Stop listening and send message
  Future<void> _stopListeningAndSend() async {
    _stopListening();

    if (_currentUtterance.trim().isNotEmpty) {
      final utterance = _currentUtterance.trim().toLowerCase();
      
      // Check if user wants to continue previous response
      if (_isContinuePhrase(utterance) && _lastAIResponse.isNotEmpty) {
        // Replay last AI response with prefix
        _replayPreviousResponse();
      } else {
        // Send message via WebSocket
        ref.read(chatProvider.notifier).sendMessage(_currentUtterance.trim());
      }
      
      setState(() {
        _currentUtterance = '';
      });
    }
  }
  
  /// Check if utterance is a "continue" phrase
  bool _isContinuePhrase(String utterance) {
    final continuePatterns = [
      'please continue',
      'continue',
      'go on',
      'keep going',
      'carry on',
      'what were you saying',
      'finish that',
      'complete that',
    ];
    
    return continuePatterns.any((pattern) => utterance.contains(pattern));
  }
  
  /// Replay previous AI response with prefix
  void _replayPreviousResponse() {
    if (_lastAIResponse.isEmpty) return;
    
    final prefixedResponse = 'As I was saying, $_lastAIResponse';
    
    // Reset state and speak the prefixed response
    _lastSpokenContent = '';
    _sentenceBuffer = prefixedResponse;
    
    if (_isCompleteSentence(_sentenceBuffer)) {
      _speakSentence(_sentenceBuffer.trim());
      _sentenceBuffer = '';
    }
  }

  /// Toggle mute
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (_isMuted) {
      _stopListening();
      _interruptionTimer?.cancel();
      _flutterTts.stop();
    } else if (_isCallActive && !_isSpeaking) {
      _startListening();
    }
  }

  /// Toggle transcript
  void _toggleTranscript() {
    setState(() {
      _showTranscript = !_showTranscript;
    });
  }

  /// Handle incoming AI response chunks (sentence-level TTS)
  void _handleAIResponseChunk(String fullContent) {
    if (!_isCallActive || fullContent.isEmpty || _isMuted) return;

    // Only process new content
    if (fullContent == _lastSpokenContent) return;
    
    final newChunk = fullContent.substring(_lastSpokenContent.length);
    _sentenceBuffer += newChunk;

    // Check if we have a complete sentence
    if (_isCompleteSentence(_sentenceBuffer)) {
      _speakSentence(_sentenceBuffer.trim());
      _lastSpokenContent = fullContent;
      _sentenceBuffer = '';
    }
  }

  /// Flush remaining buffer when response is done
  void _flushBuffer() {
    if (_sentenceBuffer.trim().isNotEmpty && _isCallActive && !_isMuted) {
      _speakSentence(_sentenceBuffer.trim());
      _sentenceBuffer = '';
    }
  }
  
  /// Store complete AI response for potential replay
  void _storeAIResponse(String content) {
    _lastAIResponse = content;
  }

  /// Check if buffer contains complete sentence
  bool _isCompleteSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    
    // Check for sentence endings
    return trimmed.endsWith('.') || 
           trimmed.endsWith('!') || 
           trimmed.endsWith('?') ||
           trimmed.length > 200; // Avoid too long buffers
  }

  /// Speak complete sentence
  Future<void> _speakSentence(String sentence) async {
    if (sentence.isEmpty || _isMuted) return;

    // Start speaking
    await _flutterTts.speak(sentence);
    
    // Keep listening in background to detect interruptions
    // (STT will trigger interruption logic if user speaks)
    if (_isCallActive && !_isMuted && !_isListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isCallActive && !_isMuted && _isSpeaking) {
          _startListening(); // Monitor for interruptions
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Listen to message updates for TTS
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (!_isCallActive) return;

      // Check for new AI message
      if (next.messages.isNotEmpty && !next.messages.last.isUser) {
        final latestMessage = next.messages.last;
        
        // Process streaming chunks
        if (latestMessage.isStreaming) {
          _handleAIResponseChunk(latestMessage.content);
        } else {
          // Response done - flush remaining buffer
          _flushBuffer();
          // Store complete response for potential replay
          _storeAIResponse(latestMessage.content);
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF8F9FE),
                    AppColors.primaryPink.withOpacity(0.03),
                  ],
                ),
              ),
            ),
            
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.spaceLG),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi ${user?.name.isNotEmpty == true ? user!.name : (user?.email.split('@').first ?? "there")}! 👋',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spaceXS),
                            Text(
                              _isCallActive 
                                  ? (_isListening 
                                      ? 'Listening...' 
                                      : (_isSpeaking ? 'Speaking...' : 'Call in progress'))
                                  : 'I\'m here to listen and support you',
                              style: AppTypography.bodyText.copyWith(
                                color: AppColors.textLight,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Connection status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isConnected 
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isConnected 
                                ? const Color(0xFF10B981).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isConnected 
                                    ? const Color(0xFF10B981) 
                                    : Colors.grey,
                                boxShadow: _isConnected ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ] : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isConnected ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isConnected ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main call interface
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        
                        // Call button with visual feedback
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing animation when listening
                            if (_isListening)
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.9, end: 1.1),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, double value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Container(
                                      width: 280,
                                      height: 280,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF6366F1).withOpacity(0.1),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            
                            // Middle circle
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCallActive
                                    ? Colors.red.withOpacity(0.08)
                                    : const Color(0xFF6366F1).withOpacity(0.08),
                              ),
                            ),
                            
                            // Call button
                            GestureDetector(
                              onTap: _isCallActive ? _endCall : _startCall,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: _isCallActive
                                      ? const LinearGradient(
                                          colors: [Color(0xFFEF4444), Color(0xFFC81E1E)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isCallActive 
                                          ? const Color(0xFFEF4444).withOpacity(0.4)
                                          : const Color(0xFF6366F1).withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isCallActive ? Icons.call_end_rounded : Icons.mic_rounded,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.spaceXL),
                        
                        // Current utterance display
                        if (_isListening && _currentUtterance.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spaceLG,
                              vertical: AppSpacing.spaceMD,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spaceXL,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              _currentUtterance,
                              style: AppTypography.bodyText,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        const SizedBox(height: AppSpacing.spaceMD),
                        
                        // Call status text
                        Text(
                          _isCallActive 
                              ? (_isListening 
                                  ? 'Speak now...' 
                                  : (_isSpeaking ? 'AI is responding...' : 'Tap to end call'))
                              : 'Tap to start voice call',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceXL * 2),
                          child: Text(
                            _isCallActive 
                                ? 'Your conversation is private and secure'
                                : 'Just speak naturally - I\'ll understand',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Quick tips when not on call
                        if (!_isCallActive && _speechEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.spaceLG),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.mic_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.spaceMD),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Voice-first experience',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Speak naturally - I stop listening 2 seconds after you finish',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        // Microphone permission warning
                        if (!_speechEnabled)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.spaceLG),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.mic_off_rounded,
                                    color: AppColors.warning,
                                    size: 24,
                                  ),
                                  const SizedBox(width: AppSpacing.spaceMD),
                                  Expanded(
                                    child: Text(
                                      'Microphone permission required for voice calls',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.warning,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: AppSpacing.spaceLG),
                      ],
                    ),
                  ),
                ),

                // Control buttons (only shown during call)
                if (_isCallActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spaceXL,
                      vertical: AppSpacing.spaceLG,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute button
                        _buildModernControlButton(
                          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onTap: _toggleMute,
                          isActive: _isMuted,
                          activeColor: const Color(0xFFEF4444),
                        ),
                        
                        // Show transcript button
                        _buildModernControlButton(
                          icon: _showTranscript ? Icons.subtitles_off_rounded : Icons.subtitles_rounded,
                          label: 'Transcript',
                          onTap: _toggleTranscript,
                          isActive: _showTranscript,
                          activeColor: const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                  ),
                ],

                // Transcript overlay
                if (_showTranscript && _isCallActive) ...[
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
                          child: Row(
                            children: [
                              Icon(Icons.subtitles_rounded, color: Colors.grey[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Live Transcript',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppSpacing.spaceMD),
                        
                        // Transcript content
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG),
                            itemCount: chatState.messages.length,
                            itemBuilder: (context, index) {
                              final message = chatState.messages[index];
                              final isUser = message.isUser;
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUser ? 'You: ' : 'AI: ',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isUser 
                                            ? AppColors.primaryPink 
                                            : AppColors.primaryPurple,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        message.content,
                                        style: AppTypography.caption,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
