import 'models.dart';

class ExpenseGroup {
  final List<String> _members = [];
  final List<Expense> _expenses = [];

  List<String> get members => List.unmodifiable(_members);

  bool _hasMember(String name) =>
      _members.any((m) => m.toLowerCase() == name.toLowerCase());

  String _canonical(String name) =>
      _members.firstWhere((m) => m.toLowerCase() == name.toLowerCase());

  void addMember(String name) {
    final n = name.trim();
    if (n.isEmpty) throw SplitSmartException('Member name cannot be empty.');
    if (_hasMember(n)) throw SplitSmartException('Member "$n" already exists.');
    _members.add(n);
  }

  void addExpense({
    required String title,
    required double amount,
    required String paidBy,
    required Category category,
    required List<String> splitBetween,
  }) {
    final t = title.trim();
    if (t.isEmpty) throw SplitSmartException('Title cannot be empty.');
    if (amount <= 0) throw SplitSmartException('Amount must be greater than zero.');
    if (!_hasMember(paidBy)) throw SplitSmartException('Payer "$paidBy" is not a member.');
    if (splitBetween.isEmpty) throw SplitSmartException('Participant list cannot be empty.');
    for (final p in splitBetween) {
      if (!_hasMember(p)) throw SplitSmartException('Participant "$p" is not a member.');
    }
    _expenses.add(Expense(
      title: t,
      amount: amount,
      paidBy: _canonical(paidBy),
      category: category,
      splitBetween: splitBetween.map(_canonical).toSet().toList(),
    ));
  }

  Map<String, double> _netBalances() {
    final b = <String, double>{for (final m in _members) m: 0.0};
    for (final e in _expenses) {
      b[e.paidBy] = b[e.paidBy]! + e.amount;
      for (final p in e.splitBetween) {
        b[p] = b[p]! - e.amountPerPerson;
      }
    }
    return b;
  }

  void printBalances() {
    if (_members.isEmpty) {
      print('No members in the group.');
      return;
    }

    final net = _netBalances();
    final paid = <String, double>{for (final m in _members) m: 0.0};
    final share = <String, double>{for (final m in _members) m: 0.0};

    for (final e in _expenses) {
      paid[e.paidBy] = paid[e.paidBy]! + e.amount;
      for (final p in e.splitBetween) {
        share[p] = share[p]! + e.amountPerPerson;
      }
    }

    _header('Balances');
    for (final m in _members) {
      final n = net[m]!;
      final status = n > 0.005
          ? 'should receive INR ${n.toStringAsFixed(2)}'
          : n < -0.005
              ? 'owes INR ${(-n).toStringAsFixed(2)}'
              : 'is settled up';
      print(
        '  $m'
        '  |  Paid: ${paid[m]!.toStringAsFixed(2)}'
        '  |  Share: ${share[m]!.toStringAsFixed(2)}'
        '  |  $status',
      );
    }

    _printSettlements(net);
  }

  void _printSettlements(Map<String, double> net) {
    _header('Suggested Settlements');

    final cred = <String, double>{};
    final debt = <String, double>{};
    for (final e in net.entries) {
      if (e.value > 0.005) cred[e.key] = e.value;
      if (e.value < -0.005) debt[e.key] = -e.value;
    }

    if (cred.isEmpty) {
      print('  Everyone is settled up!');
      return;
    }

    final cKeys = cred.keys.toList()
      ..sort((a, b) => cred[b]!.compareTo(cred[a]!));
    final dKeys = debt.keys.toList()
      ..sort((a, b) => debt[b]!.compareTo(debt[a]!));

    int ci = 0, di = 0;
    while (ci < cKeys.length && di < dKeys.length) {
      final c = cKeys[ci], d = dKeys[di];
      final t = cred[c]! < debt[d]! ? cred[c]! : debt[d]!;
      print('  $d  →  $c : INR ${t.toStringAsFixed(2)}');
      cred[c] = cred[c]! - t;
      debt[d] = debt[d]! - t;
      if (cred[c]! < 0.005) ci++;
      if (debt[d]! < 0.005) di++;
    }
  }

  void listExpenses() {
    if (_expenses.isEmpty) {
      print('No expenses recorded.');
      return;
    }
    _header('All Expenses  (${_expenses.length} total)');
    for (var i = 0; i < _expenses.length; i++) {
      _printExpense(i + 1, _expenses[i]);
    }
  }

  void filterByMember(String name) {
    if (!_hasMember(name)) throw SplitSmartException('"$name" is not a member.');
    final m = _canonical(name);
    final f = _expenses
        .where((e) => e.paidBy == m || e.splitBetween.contains(m))
        .toList();
    if (f.isEmpty) {
      print('No expenses found for "$m".');
      return;
    }
    _header('Expenses involving $m');
    for (var i = 0; i < f.length; i++) {
      _printExpense(i + 1, f[i]);
    }
  }

  void filterByCategory(Category cat) {
    final f = _expenses.where((e) => e.category == cat).toList();
    if (f.isEmpty) {
      print('No ${cat.label} expenses recorded.');
      return;
    }
    _header('${cat.label} Expenses');
    for (var i = 0; i < f.length; i++) {
      _printExpense(i + 1, f[i]);
    }
  }

  void listMembers() {
    if (_members.isEmpty) {
      print('No members yet.');
      return;
    }
    _header('Members  (${_members.length})');
    for (final m in _members) {
      print('  • $m');
    }
  }

  void _printExpense(int i, Expense e) {
    print(
      '  $i.  "${e.title}"'
      '  |  INR ${e.amount.toStringAsFixed(2)}'
      '  |  Paid by: ${e.paidBy}'
      '  |  ${e.category.label}\n'
      '       Split: ${e.splitBetween.join(', ')}'
      '  (INR ${e.amountPerPerson.toStringAsFixed(2)}/person)',
    );
  }

  void _header(String title) => print('\n─── $title ───');
}
