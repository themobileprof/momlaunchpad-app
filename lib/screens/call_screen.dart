import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

/// Call screen - Primary feature (voice-first interface)
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _isConnected = false;
  bool _isCallActive = false;
  bool _isMuted = false;
  bool _showTranscript = false;

  @override
  void initState() {
    super.initState();
    // Don't connect WebSocket on init - only when user starts a call
  }

  Future<void> _connectWebSocket() async {
    await ref.read(chatProvider.notifier).connect();
    setState(() {
      _isConnected = ref.read(chatProvider).isConnected;
    });
  }

  @override
  void dispose() {
    if (_isCallActive) {
      _endCall();
    }
    // Only disconnect if we were connected
    if (_isConnected) {
      ref.read(chatProvider.notifier).disconnect();
    }
    super.dispose();
  }

  Future<void> _startCall() async {
    // Connect to backend when user initiates call
    await _connectWebSocket();
    setState(() {
      _isCallActive = true;
    });
    // TODO: Initialize audio recording/streaming
  }

  void _endCall() {
    setState(() {
      _isCallActive = false;
      _isMuted = false;
    });
    // Disconnect WebSocket when call ends
    ref.read(chatProvider.notifier).disconnect();
    setState(() {
      _isConnected = false;
    });
    // TODO: Stop audio recording/streaming
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // TODO: Mute/unmute microphone
  }

  void _toggleTranscript() {
    setState(() {
      _showTranscript = !_showTranscript;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.spaceLG),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi ${user?.name ?? "there"}! 👋',
                        style: AppTypography.headingLarge.copyWith(
                          color: AppColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.spaceXS),
                      Text(
                        _isCallActive 
                            ? 'Call in progress...' 
                            : 'Tap below to start a call',
                        style: AppTypography.bodyText.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                  // Connection status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.spaceSM,
                      vertical: AppSpacing.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: _isConnected 
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _isConnected ? AppColors.success : AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.spaceXS),
                        Text(
                          _isConnected ? 'Connected' : 'Offline',
                          style: AppTypography.caption.copyWith(
                            color: _isConnected ? AppColors.success : AppColors.error,
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
                    // Large circular call button
                    GestureDetector(
                      onTap: _isCallActive ? _endCall : _startCall,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isCallActive
                                ? [Colors.red, Colors.redAccent]
                                : [AppColors.primaryPink, AppColors.primaryPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isCallActive ? Colors.red : AppColors.primaryPink)
                                  .withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isCallActive ? Icons.call_end : Icons.phone,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spaceXL),
                    
                    // Call status text
                    Text(
                      _isCallActive ? 'Tap to end call' : 'Tap to start call',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spaceSM),
                    Text(
                      _isCallActive 
                          ? 'Your conversation is being recorded for your reference'
                          : 'I\'m here to support you through your pregnancy journey',
                      style: AppTypography.bodyText.copyWith(
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Control buttons (only shown during call)
            if (_isCallActive) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceXL,
                  vertical: AppSpacing.spaceLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute button
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      onTap: _toggleMute,
                      color: _isMuted ? Colors.red : AppColors.primaryPurple,
                    ),
                    
                    // Show transcript button
                    _buildControlButton(
                      icon: _showTranscript ? Icons.visibility_off : Icons.visibility,
                      label: 'Transcript',
                      onTap: _toggleTranscript,
                      color: AppColors.primaryPink,
                    ),
                  ],
                ),
              ),
            ],

            // Transcript overlay (shown when active)
            if (_showTranscript && _isCallActive) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.spaceLG),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.spaceSM),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    // Transcript content
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.spaceMD),
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

            // Bottom hint text (only when call is not active)
            if (!_isCallActive) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceLG),
                child: GestureDetector(
                  onTap: () {
                    // Navigate to chat screen (tab index 1)
                    final scaffold = Scaffold.of(context);
                    // Use findAncestorStateOfType to access parent state
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.spaceMD),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.spaceSM),
                        Text(
                          'Prefer to chat? Tap here to view chat history',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
