import 'package:flutter/material.dart';

class NonCloudReportBanner extends StatelessWidget {
  const NonCloudReportBanner({super.key, required this.reportTitle});

  final String reportTitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              '$reportTitle is Primary Device Only',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This report is available on Primary Device (Local Storage) mode. Switch to Primary Device mode in Settings to view local report data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
