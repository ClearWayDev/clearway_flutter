import 'package:flutter/material.dart';

enum TopSnackBarType { success, error, info }

void showTopSnackBar(
  BuildContext context,
  String message, {
  TopSnackBarType type = TopSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context);
  final color = _getSnackBarColor(type);
  final icon = _getSnackBarIcon(type);

  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).viewPadding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(duration, () {
    overlayEntry.remove();
  });
}

Color _getSnackBarColor(TopSnackBarType type) {
  switch (type) {
    case TopSnackBarType.success:
      return Colors.green;
    case TopSnackBarType.error:
      return Colors.red;
    case TopSnackBarType.info:
    default:
      return Colors.blue;
  }
}

IconData _getSnackBarIcon(TopSnackBarType type) {
  switch (type) {
    case TopSnackBarType.success:
      return Icons.check_circle_outline;
    case TopSnackBarType.error:
      return Icons.error_outline;
    case TopSnackBarType.info:
    default:
      return Icons.info_outline;
  }
}
