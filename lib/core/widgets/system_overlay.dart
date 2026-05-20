import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// System overlay widget that displays when app is in background
class SystemOverlayWidget extends StatefulWidget {
  const SystemOverlayWidget({super.key});

  @override
  State<SystemOverlayWidget> createState() => _SystemOverlayWidgetState();
}

class _SystemOverlayWidgetState extends State<SystemOverlayWidget> {
  String _bankName = '';
  double _amount = 0;
  bool _isCredit = true;
  String _description = '';

  @override
  void initState() {
    super.initState();
    _listenForData();
  }

  void _listenForData() {
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          _bankName = data['bankName'] ?? '';
          _amount = (data['amount'] ?? 0).toDouble();
          _isCredit = data['isCredit'] ?? true;
          _description = data['description'] ?? '';
        });

        // Auto close after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          FlutterOverlayWindow.closeOverlay();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _isCredit 
        ? const Color(0xFF22C55E) 
        : const Color(0xFFEF4444);
    final iconBgColor = amountColor.withValues(alpha: 0.2);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => FlutterOverlayWindow.closeOverlay(),
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            FlutterOverlayWindow.closeOverlay();
          }
        },
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: amountColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                  color: amountColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCredit ? 'Money Received' : 'Money Sent',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_isCredit ? '+' : '-'}ETB ${_amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    if (_description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _bankName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry point for overlay - must be a top-level function
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SystemOverlayWidget(),
  ));
}
