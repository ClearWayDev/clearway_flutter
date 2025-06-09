import 'package:flutter/material.dart';

class TapHandlerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTripleTap;
  final VoidCallback? onQuadrupleTap;
  final Duration tapTimeWindow;
  final Duration processingDelay;

  const TapHandlerWidget({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.onTripleTap,
    this.onQuadrupleTap,
    this.tapTimeWindow = const Duration(milliseconds: 500),
    this.processingDelay = const Duration(milliseconds: 1000),
  });

  @override
  State<TapHandlerWidget> createState() => _TapHandlerWidgetState();
}

class _TapHandlerWidgetState extends State<TapHandlerWidget> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _handleTap() {
    final now = DateTime.now();
    
    // Reset tap count if too much time has passed since last tap
    if (_lastTapTime != null && now.difference(_lastTapTime!) > widget.tapTimeWindow) {
      _tapCount = 0;
    }
    
    _tapCount++;
    _lastTapTime = now;
    
    // Cancel any existing timer and start a new one
    Future.delayed(widget.processingDelay, () {
      // Only process if this is still the latest tap sequence
      if (_lastTapTime != null && now.difference(_lastTapTime!) <= widget.processingDelay) {
        _processTaps();
      }
    });
  }

  void _processTaps() {
    switch (_tapCount) {
      case 2:
        if (widget.onDoubleTap != null) {
          widget.onDoubleTap!();
        }
        break;
      case 3:
        if (widget.onTripleTap != null) {
          widget.onTripleTap!();
        }
        break;
      case 4:
        if (widget.onQuadrupleTap != null) {
          widget.onQuadrupleTap!();
        } 
        break;
      default:
        break;
    }
    
    // Reset tap count after processing
    _tapCount = 0;
    _lastTapTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}