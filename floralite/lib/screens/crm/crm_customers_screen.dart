import 'package:flutter/material.dart';

import '../customers_screen.dart';

class CrmCustomersScreen extends StatelessWidget {
  const CrmCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuses existing Customer Master screen
    return const CustomersScreen();
  }
}
