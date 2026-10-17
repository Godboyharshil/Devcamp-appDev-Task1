import 'dart:io';
import 'package:splitsmart/models.dart';
import 'package:splitsmart/expense_group.dart';

void main() {
  final group = ExpenseGroup();

  while (true) {
    _printMenu();
    final choice = stdin.readLineSync()?.trim() ?? '';

    if (choice == '1') {
      _addMember(group);
    } else if (choice == '2') {
      _addExpense(group);
    } else if (choice == '3') {
      group.listExpenses();
    } else if (choice == '4') {
      _filterByMember(group);
    } else if (choice == '5') {
      _filterByCategory(group);
    } else if (choice == '6') {
      group.printBalances();
    } else if (choice == '7') {
      group.listMembers();
    } else if (choice == '0') {
      print('\n  Goodbye!\n');
      return;
    } else {
      print('\n  Invalid choice — enter a number from 0 to 7.');
    }
  }
}

void _printMenu() {
  print('\n            SplitSmart            ');
  print('     1 · Add member               ');
  print('     2 · Add expense              ');
  print('     3 · List all expenses        ');
  print('     4 · Filter by member         ');
  print('     5 · Filter by category       ');
  print('     6 · Show balances            ');
  print('     7 · List members             ');
  print('     0 · Exit                     ');
  stdout.write('  Choice → ');
}

String _ask(String prompt) {
  stdout.write('  $prompt: ');
  return stdin.readLineSync()?.trim() ?? '';
}

void _addMember(ExpenseGroup group) {
  try {
    final name = _ask('Member name');
    group.addMember(name);
    print('  ✓ Added "$name".');
  } on SplitSmartException catch (e) {
    print('  $e');
  }
}

void _addExpense(ExpenseGroup group) {
  if (group.members.isEmpty) {
    print('\n  Add at least one member before recording an expense.');
    return;
  }

  try {
    final title = _ask('Expense title');

    stdout.write('  Amount (INR): ');
    final amtStr = stdin.readLineSync()?.trim() ?? '';
    final amount = double.tryParse(amtStr);
    if (amount == null) throw SplitSmartException('Enter a valid number for the amount.');

    print('  Members: ${group.members.join(', ')}');
    final paidBy = _ask('Paid by');

    _showCategories();
    final catStr = _ask('Category number');
    final catIdx = (int.tryParse(catStr) ?? 0) - 1;
    if (catIdx < 0 || catIdx >= Category.values.length) {
      throw SplitSmartException('Invalid category number.');
    }
    final category = Category.values[catIdx];

    print('  Members: ${group.members.join(', ')}');
    stdout.write('  Split between (comma-separated names, or "all"): ');
    final raw = stdin.readLineSync()?.trim() ?? '';

    final splitBetween = raw.toLowerCase() == 'all'
        ? List<String>.from(group.members)
        : raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    group.addExpense(
      title: title,
      amount: amount,
      paidBy: paidBy,
      category: category,
      splitBetween: splitBetween,
    );
    print('  ✓ Expense "$title" added.');
  } on SplitSmartException catch (e) {
    print('  $e');
  }
}

void _filterByMember(ExpenseGroup group) {
  try {
    if (group.members.isNotEmpty) {
      print('  Members: ${group.members.join(', ')}');
    }
    final name = _ask('Member name');
    group.filterByMember(name);
  } on SplitSmartException catch (e) {
    print('  $e');
  }
}

void _filterByCategory(ExpenseGroup group) {
  _showCategories();
  final catStr = _ask('Category number');
  final catIdx = (int.tryParse(catStr) ?? 0) - 1;
  if (catIdx < 0 || catIdx >= Category.values.length) {
    print('  Error: Invalid category number.');
    return;
  }
  group.filterByCategory(Category.values[catIdx]);
}

void _showCategories() {
  final line = Category.values
      .map((c) => '${c.index + 1}. ${c.label}')
      .join('   ');
  print('  Categories: $line');
}
