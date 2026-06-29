import 'dart:async';
import 'package:flutter/material.dart';
import 'idle_screen.dart';

class IdleDetector extends StatefulWidget {
  final Widget child;
  final Duration idleTimeout;

  const IdleDetector({
    super.key,
    required this.child,
    this.idleTimeout = const Duration(minutes: 1),
  });

  @override
  State<IdleDetector> createState() => _IdleDetectorState();
}

class _IdleDetectorState extends State<IdleDetector> {
  Timer? _idleTimer;
  bool _isIdle = false;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    if (_isIdle) {
      setState(() {
        _isIdle = false;
      });
    }
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleTimeout, () {
      if (mounted) {
        setState(() {
          _isIdle = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isIdle) {
      return IdleScreen(onDismiss: _resetIdleTimer);
    }
    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerUp: (_) => _resetIdleTimer(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
