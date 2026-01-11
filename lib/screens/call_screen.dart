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
  Timer? _fillerTimer;
  
  // Text-to-speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String _lastAIResponse = ''; // Store last complete AI response
  bool _wasInterrupted = false;
  
  // Filler phrases for delayed responses
  static const List<String> _fillerPhrases = [
    'Uhm...',
    'Let me think...',
    'Okay...',
    'Interesting...',
    'I see...',
    'Hmm...',
  ];
  int _fillerIndex = 0;
  
  // Call state
  bool _isConnected = false;
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _showTranscript = false;
  
  // VAD settings - longer pause for natural conversation flow
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
    _fillerTimer?.cancel();
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
          // error_no_match is common when there's background noise or silence
          // Don't treat it as a permanent failure - just restart listening
          if (error.errorMsg == 'error_no_match' && !error.permanent) {
            print('No speech detected - will restart listening');
            if (mounted && _isCallActive && !_isMuted) {
              // Brief delay before restarting to avoid rapid cycling
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && _isCallActive && !_isMuted && !_isSpeaking) {
                  _startListening();
                }
              });
            }
            return;
          }
          // For other errors, stop listening
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() => _isListening = false);
              // Auto-restart if call is still active and we weren't speaking
              if (_isCallActive && !_isMuted && !_isSpeaking) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && _isCallActive && !_isMuted && !_isSpeaking && !_isListening) {
                    print('Auto-restarting speech recognition...');
                    _startListening();
                  }
                });
              }
            }
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
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
      print('TTS started - stopping microphone to prevent echo');
      // CRITICAL: Stop listening immediately to prevent audio feedback
      if (_isListening) {
        _speechToText.stop();
      }
      setState(() {
        _isSpeaking = true;
        _isListening = false;
      });
    });
    
    _flutterTts.setCompletionHandler(() {
      print('TTS completed');
      setState(() => _isSpeaking = false);
      // Resume listening after speaking - LONGER delay to prevent audio echo
      if (_isCallActive && !_isMuted && !_isListening && !_wasInterrupted) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_isCallActive && !_isMuted && !_isSpeaking) {
            print('Restarting listening after TTS completion');
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
      _currentUtterance = '';
      _lastAIResponse = '';
    });

    // Start listening immediately
    await Future.delayed(const Duration(milliseconds: 500));
    _startListening();
  }

  /// End voice call
  void _endCall() {
    _stopListening();
    _interruptionTimer?.cancel();
    _fillerTimer?.cancel();
    _flutterTts.stop();
    
    setState(() {
      _isCallActive = false;
      _isMuted = false;
      _isListening = false;
      _isSpeaking = false;
      _currentUtterance = '';
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
        print('Speech result - words: "${result.recognizedWords}", final: ${result.finalResult}');
        setState(() {
          _currentUtterance = result.recognizedWords;
        });

        // If we got a final result, send it immediately
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          print('Got final result - sending message');
          _stopListeningAndSend();
          return;
        }

        // SMART INTERRUPTION: Require substantial speech before stopping AI
        // This filters out echo, background noise, and accidental sounds
        if (_isSpeaking && result.recognizedWords.trim().isNotEmpty) {
          final wordCount = result.recognizedWords.trim().split(RegExp(r'\s+')).length;
          
          // Only interrupt if user speaks at least 5 words continuously
          if (wordCount >= 5) {
            _interruptionTimer?.cancel();
            _interruptionTimer = Timer(const Duration(milliseconds: 800), () {
              // User has spoken multiple words - genuine interruption
              _flutterTts.stop();
              _wasInterrupted = true;
              setState(() => _isSpeaking = false);
            });
          }
        }

        // Voice Activity Detection: Reset silence timer on speech
        _silenceTimer?.cancel();
        if (!result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _silenceTimer = Timer(_silenceThreshold, () {
            // User stopped speaking - send message
            _stopListeningAndSend();
          });
        }
      },
      listenMode: ListenMode.dictation, // Use dictation mode for continuous listening
      cancelOnError: false, // Handle errors ourselves to enable auto-restart
      partialResults: true,
      listenFor: const Duration(minutes: 2), // Max listen duration (extended for longer conversations)
      pauseFor: const Duration(seconds: 6), // Longer than silence threshold to let our VAD handle it
    );
  }

  /// Stop listening
  void _stopListening() {
    _silenceTimer?.cancel();
    _speechToText.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  /// Stop listening and send message
  Future<void> _stopListeningAndSend() async {
    print('=== _stopListeningAndSend called ===');
    print('Current utterance: "$_currentUtterance"');
    _stopListening();

    if (_currentUtterance.trim().isNotEmpty) {
      final utterance = _currentUtterance.trim().toLowerCase();
      print('Trimmed utterance: "$utterance"');
      
      // Check if user wants to continue previous response
      if (_isContinuePhrase(utterance) && _lastAIResponse.isNotEmpty) {
        print('Detected continue phrase - replaying previous response');
        // Replay last AI response with prefix
        _replayPreviousResponse();
      } else {
        print('Sending message to chat provider: "${_currentUtterance.trim()}"');
        // Send message via WebSocket
        ref.read(chatProvider.notifier).sendMessage(_currentUtterance.trim());
        
        // Start filler timer - speak a filler if response takes too long
        _startFillerTimer();
      }
      
      setState(() {
        _currentUtterance = '';
      });
    } else {
      print('No utterance to send (empty or whitespace only)');
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
    
    // Speak with "continuing" prefix
    final prefixedResponse = "Continuing where I left off: $_lastAIResponse";
    _speakCompleteResponse(prefixedResponse);
  }

  /// Interrupt AI when it's speaking
  void _interruptAI() {
    print('User interrupted AI');
    _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
      _wasInterrupted = true;
    });
    // Start listening immediately for user input
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isCallActive && !_isMuted && !_isSpeaking) {
        _startListening();
      }
    });
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

  /// Start filler timer for delayed responses
  void _startFillerTimer() {
    _fillerTimer?.cancel();
    _fillerTimer = Timer(const Duration(seconds: 3), () {
      // Response is taking time, speak a filler
      if (_isCallActive && !_isSpeaking && !_isMuted) {
        print('Response delayed - speaking filler');
        _speakFiller();
      }
    });
  }
  
  /// Speak a filler phrase
  Future<void> _speakFiller() async {
    final filler = _fillerPhrases[_fillerIndex];
    _fillerIndex = (_fillerIndex + 1) % _fillerPhrases.length; // Rotate through phrases
    
    await _flutterTts.speak(filler);
  }

  /// Speak complete AI response
  Future<void> _speakCompleteResponse(String content) async {
    if (content.isEmpty || _isMuted || !_isCallActive) return;

    print('=== Speaking complete response ===');
    print('Content length: ${content.length}');
    
    // CRITICAL: Ensure listening is stopped before speaking
    if (_isListening) {
      print('Stopping listening before TTS to prevent echo');
      _speechToText.stop();
      setState(() => _isListening = false);
      // Brief delay to ensure microphone is fully stopped
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Speak the complete response
    await _flutterTts.speak(content);
    
    print('TTS speak() call completed');
    
    // Start listening for next user input after a brief delay
    if (_isCallActive && !_isMuted && !_isListening) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isCallActive && !_isMuted && !_isListening) {
          _startListening();
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
      print('=== ChatState changed ===');
      print('Is call active: $_isCallActive');
      print('Messages count: ${next.messages.length}');
      
      if (!_isCallActive) {
        print('Call not active - skipping TTS');
        return;
      }

      // Cancel filler timer when any response arrives
      _fillerTimer?.cancel();

      // Check for new AI message that is COMPLETE (not streaming)
      if (next.messages.isNotEmpty && !next.messages.last.isUser) {
        final latestMessage = next.messages.last;
        print('Latest AI message - streaming: ${latestMessage.isStreaming}, content length: ${latestMessage.content.length}');
        
        // Only speak complete responses, not streaming chunks
        if (!latestMessage.isStreaming && latestMessage.content.isNotEmpty) {
          print('Complete response received - speaking');
          // Check if this is new content we haven't spoken yet
          if (latestMessage.content != _lastAIResponse) {
            _lastAIResponse = latestMessage.content;
            _speakCompleteResponse(latestMessage.content);
          }
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
                  child: SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const SizedBox(height: 40),
                        
                        // Call button with visual feedback
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Multiple pulsing rings when listening (NOT when AI is speaking)
                            if (_isListening && !_isSpeaking) ...[
                              _PulsingRing(size: 320, delay: 0.0, color: const Color(0xFF6366F1)),
                              _PulsingRing(size: 290, delay: 0.3, color: const Color(0xFF8B5CF6)),
                              _PulsingRing(size: 260, delay: 0.6, color: const Color(0xFF6366F1)),
                            ],
                            
                            // Pulsing effect when AI is speaking
                            if (_isSpeaking) ...[
                              _PulsingRing(size: 300, delay: 0.0, color: const Color(0xFF10B981)),
                              _PulsingRing(size: 270, delay: 0.4, color: const Color(0xFF10B981)),
                            ],
                            
                            // Middle circle
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCallActive
                                    ? (_isSpeaking
                                        ? const Color(0xFF10B981).withOpacity(0.08) // Green when AI speaks
                                        : (_isListening
                                            ? const Color(0xFF6366F1).withOpacity(0.08) // Blue when listening
                                            : Colors.grey.withOpacity(0.08))) // Gray when idle
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
                        
                        const SizedBox(height: AppSpacing.spaceMD),
                        
                        // Call status text with listening indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated sound wave bars when listening (NOT when AI is speaking)
                            if (_isListening && !_isSpeaking) ...[
                              _SoundWaveBar(delay: 0.0),
                              const SizedBox(width: 4),
                              _SoundWaveBar(delay: 0.1),
                              const SizedBox(width: 4),
                              _SoundWaveBar(delay: 0.2),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              _isCallActive 
                                  ? (_isSpeaking
                                      ? 'AI is speaking...'
                                      : (_isListening 
                                          ? 'Listening...' 
                                          : 'Tap to end call'))
                                  : 'Tap to start voice call',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: _isSpeaking 
                                    ? const Color(0xFF10B981) // Green when AI speaks
                                    : (_isListening 
                                        ? const Color(0xFF6366F1) // Blue when listening
                                        : const Color(0xFF1F2937)), // Dark when idle
                                letterSpacing: -0.5,
                              ),
                            ),
                            // Animated sound wave bars when listening (NOT when AI is speaking)
                            if (_isListening && !_isSpeaking) ...[
                              const SizedBox(width: 12),
                              _SoundWaveBar(delay: 0.0),
                              const SizedBox(width: 4),
                              _SoundWaveBar(delay: 0.1),
                              const SizedBox(width: 4),
                              _SoundWaveBar(delay: 0.2),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        
                        // Interrupt button (only shown when AI is speaking)
                        if (_isCallActive && _isSpeaking)
                          GestureDetector(
                            onTap: _interruptAI,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFC81E1E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.stop_circle_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Interrupt AI',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
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
                        
                        const SizedBox(height: 40),
                        
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

/// Sound wave bar animation for listening indicator
class _SoundWaveBar extends StatefulWidget {
  final double delay;

  const _SoundWaveBar({required this.delay});

  @override
  State<_SoundWaveBar> createState() => _SoundWaveBarState();
}

class _SoundWaveBarState extends State<_SoundWaveBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Delay the start based on the widget's delay parameter
    Future.delayed(Duration(milliseconds: (widget.delay * 200).toInt()), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3,
          height: _animation.value,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}

/// Pulsing ring animation widget for voice listening indicator
class _PulsingRing extends StatefulWidget {
  final double size;
  final double delay;
  final Color color;

  const _PulsingRing({
    required this.size,
    required this.delay,
    required this.color,
  });

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Delay start based on widget delay parameter
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity(_opacityAnimation.value * 0.5),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}
