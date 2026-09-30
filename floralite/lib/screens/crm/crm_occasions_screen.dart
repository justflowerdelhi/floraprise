import 'package:flutter/material.dart';

import '../reminders_screen.dart';

class CrmOccasionsScreen extends StatelessWidget {
  const CrmOccasionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuses existing Occasions / Reminders Hub
    return const RemindersScreen();
  }
}
