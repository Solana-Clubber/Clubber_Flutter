String formatWon(num amount) {
  final digits = amount.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '₩${buffer.toString()}';
}

String formatCompactWon(int amountWon) {
  if (amountWon >= 1000000) {
    return '₩${(amountWon / 1000000).toStringAsFixed(1)}M';
  }
  if (amountWon >= 1000) {
    return '₩${(amountWon / 1000).toStringAsFixed(0)}k';
  }
  return formatWon(amountWon);
}

String formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}
