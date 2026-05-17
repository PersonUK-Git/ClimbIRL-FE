import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class NoConnectionScreen extends StatefulWidget {
  final VoidCallback onRetry;

  const NoConnectionScreen({super.key, required this.onRetry});

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying) return;
    
    setState(() {
      _isRetrying = true;
    });

    // Trigger the parent's retry callback (which runs AuthCubit's checkAuthStatus)
    widget.onRetry();

    // After 2 seconds, reset the retrying spinner
    // so the button is clickable again (if connection succeeds, the widget is unmounted).
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        cs.surface,
                        cs.surfaceContainerLowest,
                      ]
                    : [
                        cs.primary.withValues(alpha: 0.05),
                        cs.surface,
                      ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    
                    // Animated glowing wifi-off icon inside overlapping circular rings
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glowing circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.05),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2000.ms, curve: Curves.easeInOut)
                        .fadeIn(duration: 1000.ms),
                        
                        // Middle circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1500.ms, curve: Curves.easeInOut),
                        
                        // Inner circle with icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                            boxShadow: [
                              BoxShadow(
                                color: cs.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.wifi_off_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), curve: Curves.elasticOut),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Title with Gamified RPG Vibe
                    Text(
                      'Adventure Paused',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: 0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle explaining the connection issue
                    Text(
                      "We can't seem to connect to the ClimbIRL servers. Please check your internet connection or try again shortly.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    
                    const Spacer(),
                    
                    // Retry Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isRetrying ? null : _handleRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: cs.primary.withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _isRetrying
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Retry Connection',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
