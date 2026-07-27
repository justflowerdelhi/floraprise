import 'package:floraprise/models/expense_category.dart';
import 'package:floraprise/screens/expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Add Expense bottom sheet opens and amount field is tappable',
      (tester) async {
    final categories = [
      ExpenseCategory(
        id: 1,
        name: 'Flowers',
        emoji: '🌸',
        groupName: 'Inventory',
        active: true,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => AddExpenseBottomSheet(
                      categories: categories,
                      selectedDate: DateTime(2026, 7, 19),
                      onSave: () {},
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Save Expense'), findsOneWidget);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
