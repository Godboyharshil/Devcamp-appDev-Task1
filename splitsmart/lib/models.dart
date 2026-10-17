enum Category {
  food,
  transport,
  entertainment,
  accommodation,
  shopping,
  utilities,
  other;

  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

class SplitSmartException implements Exception {
  final String message;
  const SplitSmartException(this.message);

  @override
  String toString() => 'Error: $message';
}

class Expense {
  final String title;
  final double amount;
  final String paidBy;
  final Category category;
  final List<String> splitBetween;

  Expense({
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.category,
    required List<String> splitBetween,
  }) : splitBetween = List.unmodifiable(splitBetween);

  double get amountPerPerson => amount / splitBetween.length;
}
