import 'package:flutter/material.dart';
import '../../widgets/dot_climb.dart';

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
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const DotClimb(progress: 0.5, height: 120),
              const SizedBox(height: 28),
              Text('Adventure paused.', style: tt.displaySmall),
              const SizedBox(height: 10),
              Text(
                "We can't reach the ClimbIRL servers. Check your internet connection or try again shortly.",
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isRetrying ? null : _handleRetry,
                  child: _isRetrying
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: cs.onSurfaceVariant,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Try again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
