import 'package:flutter/material.dart';
import 'package:clearway/utils/tap_handler.dart';

class BlindPopupWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? content;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTripleTap;
  final VoidCallback? onQuadrupleTap;
  final Color? backgroundColor;
  final Color? overlayColor;
  final double? width;
  final double? height;

  const BlindPopupWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.content,
    this.onDoubleTap,
    this.onTripleTap,
    this.onQuadrupleTap,
    this.backgroundColor,
    this.overlayColor,
    this.width,
    this.height,
  });


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: TapHandlerWidget(
        onDoubleTap: onDoubleTap,
        onTripleTap: onTripleTap,
        onQuadrupleTap: onQuadrupleTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: overlayColor ?? Colors.black.withOpacity(0.5),
          child: Center(
            child: Container(
              width: width ?? MediaQuery.of(context).size.width * 0.9,
              height: height,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Subtitle
                    if (subtitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    // Content
                    if (content != null) ...[
                      const SizedBox(height: 20),
                      Flexible(child: content!),
                    ],
                    
                    // Instructions
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (onDoubleTap != null)
                            const Text(
                              '2 taps: Start the feature',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          if (onTripleTap != null)
                            const Text(
                              '3 taps: Exit the feature',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



  