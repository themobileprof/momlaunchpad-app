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
      backgroundColor: const Color(0xFFF8F9FE), // Softer, modern background
      body: SafeArea(
        child: Stack(
          children: [
            // Subtle gradient background
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
                              'Hi ${user?.name ?? "there"}! 👋',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spaceXS),
                            Text(
                              _isCallActive 
                                  ? 'Call in progress...' 
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
                        
                        // Decorative circles behind the call button
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse circle (simple static version)
                            if (_isCallActive)
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withValues(alpha: 0.05),
                                ),
                              ),
                            
                            // Middle circle
                            Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCallActive
                                    ? Colors.red.withValues(alpha: 0.08)
                                    : const Color(0xFF6366F1).withValues(alpha: 0.08),
                              ),
                            ),
                            
                            // Large circular call button with modern design
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
                                  _isCallActive ? Icons.call_end_rounded : Icons.phone_rounded,
                                  size: 70,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.spaceXXL),
                        
                        // Call status text with better typography
                        Text(
                          _isCallActive ? 'Tap to end call' : 'Tap to start call',
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
                                : 'Share how you\'re feeling, ask questions, or just chat',
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
                        if (!_isCallActive)
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
                                      Icons.lightbulb_outline_rounded,
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
                                          'Try asking about',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Symptoms, nutrition, exercises, or baby development',
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

                // Transcript overlay (shown when active)
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
