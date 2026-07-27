import 'package:flutter/material.dart';

import '../controllers/voice_dictation_controller.dart';

class VoiceDictationFieldHeader extends StatelessWidget {
  const VoiceDictationFieldHeader({
    super.key,
    required this.label,
    required this.controller,
    this.subtitle,
    this.compact = false,
  });

  final String label;
  final VoiceDictationController controller;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final listening = controller.isListening;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final micColor = listening ? Colors.red : Colors.green;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: micColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () async {
                      if (listening) {
                        await controller.stop();
                      } else {
                        await controller.start();
                      }
                    },
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    icon: Icon(
                      listening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if ((subtitle != null && subtitle!.trim().isNotEmpty) ||
                controller.liveTranscript.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle?.trim().isNotEmpty == true
                    ? subtitle!
                    : controller.liveTranscript,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: listening ? colorScheme.primary : colorScheme.outline,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
