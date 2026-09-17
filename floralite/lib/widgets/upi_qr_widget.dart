import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clean UPI QR Code Preview and Interactive Dialog for Floraprise
class UpiQrWidget extends StatelessWidget {
  const UpiQrWidget({
    super.key,
    required this.upiId,
    required this.merchantName,
    this.size = 200,
  });

  final String upiId;
  final String merchantName;
  final double size;

  String get upiString {
    final cleanId = upiId.trim();
    if (cleanId.isEmpty) return '';
    final name = merchantName.trim().isNotEmpty
        ? Uri.encodeComponent(merchantName.trim())
        : 'Florist';
    return 'upi://pay?pa=$cleanId&pn=$name&cu=INR';
  }

  @override
  Widget build(BuildContext context) {
    if (upiId.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Enter UPI ID to generate QR',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=${size.toInt()}x${size.toInt()}&data=${Uri.encodeComponent(upiString)}&margin=1';

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          qrUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: Size(size, size),
              painter: _UpiQrFallbackPainter(upiString),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Fallback custom painter for offline rendering of stylized QR pattern
class _UpiQrFallbackPainter extends CustomPainter {
  final String data;
  _UpiQrFallbackPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Draw finder patterns at corners
    final moduleSize = size.width / 21;

    void drawFinder(double x, double y) {
      // Outer 7x7 square
      canvas.drawRect(
        Rect.fromLTWH(x, y, 7 * moduleSize, 7 * moduleSize),
        paint,
      );
      // Inner white 5x5 square
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
            x + moduleSize, y + moduleSize, 5 * moduleSize, 5 * moduleSize),
        whitePaint,
      );
      // Center black 3x3 square
      canvas.drawRect(
        Rect.fromLTWH(x + 2 * moduleSize, y + 2 * moduleSize, 3 * moduleSize,
            3 * moduleSize),
        paint,
      );
    }

    drawFinder(0, 0); // Top-left
    drawFinder(size.width - 7 * moduleSize, 0); // Top-right
    drawFinder(0, size.height - 7 * moduleSize); // Bottom-left

    // Draw stylized data dots based on hash of data
    final hash = data.hashCode;
    for (int r = 0; r < 21; r++) {
      for (int c = 0; c < 21; c++) {
        // Skip finder areas
        if ((r < 8 && c < 8) ||
            (r < 8 && c > 13) ||
            (r > 13 && c < 8)) {
          continue;
        }
        if (((hash ^ (r * 31 + c * 17)) % 3) == 0) {
          canvas.drawRect(
            Rect.fromLTWH(
                c * moduleSize + 0.5, r * moduleSize + 0.5, moduleSize - 1, moduleSize - 1),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _UpiQrFallbackPainter oldDelegate) =>
      oldDelegate.data != data;
}

/// Show modal bottom sheet with complete UPI QR preview
Future<void> showUpiQrPreviewSheet({
  required BuildContext context,
  required String upiId,
  required String merchantName,
}) {
  final cleanId = upiId.trim();
  final name = merchantName.trim().isNotEmpty ? merchantName.trim() : 'Floraprise Merchant';
  final upiString = 'upi://pay?pa=$cleanId&pn=${Uri.encodeComponent(name)}&cu=INR';

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'UPI Payment QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Customers scan with GPay, PhonePe, Paytm, or BHIM',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            UpiQrWidget(
              upiId: cleanId,
              merchantName: name,
              size: 200,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.green.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          cleanId,
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy UPI ID',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: cleanId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI ID copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link),
                    label: const Text('Copy UPI Link'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: upiString));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI payment link copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
