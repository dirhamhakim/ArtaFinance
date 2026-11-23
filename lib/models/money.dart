/// IDR disimpan sebagai sen dalam BigInt; tidak ada perhitungan floating point.
final class Money implements Comparable<Money> {
  Money(this.minor);
  factory Money.stored(String value) {
    if (!RegExp(r'^-?(0|[1-9]\d*)$').hasMatch(value) || value == '-0') {
      throw const FormatException('Nominal tersimpan tidak valid.');
    }
    return Money(BigInt.parse(value));
  }

  /// Form Indonesia: 10000, 10.000, atau 10.000,50. Maksimal dua desimal.
  factory Money.input(String value) {
    final text = value.trim();
    if (!RegExp(r'^-?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,2})?$')
        .hasMatch(text)) {
      throw const FormatException(
        'Gunakan nominal seperti 10.000 atau 10.000,50.',
      );
    }
    final parts = text.replaceAll('.', '').replaceAll('-', '').split(',');
    final cents = parts.length == 2 ? parts[1].padRight(2, '0') : '00';
    final result =
        BigInt.parse(parts[0]) * BigInt.from(100) + BigInt.parse(cents);
    return Money(text.startsWith('-') ? -result : result);
  }
  static Money get zero => Money(BigInt.zero);
  final BigInt minor;
  bool get isNegative => minor.isNegative;
  bool get isPositive => minor > BigInt.zero;
  bool get isZero => minor == BigInt.zero;
  Money operator +(Money other) => Money(minor + other.minor);
  Money operator -(Money other) => Money(minor - other.minor);
  Money operator -() => Money(-minor);
  String get stored => minor.toString();
  String get input {
    final digits = minor.abs().toString().padLeft(3, '0');
    final whole = digits.substring(0, digits.length - 2);
    final fraction = digits.substring(digits.length - 2);
    return '${isNegative ? '-' : ''}$whole${fraction == '00' ? '' : ',$fraction'}';
  }

  String get formatted {
    final parts = input.split(',');
    final negative = parts[0].startsWith('-');
    final digits = parts[0].replaceAll('-', '');
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return '${negative ? '-' : ''}Rp $out${parts.length == 2 ? ',${parts[1]}' : ''}';
  }

  @override
  int compareTo(Money other) => minor.compareTo(other.minor);
  @override
  bool operator ==(Object other) => other is Money && minor == other.minor;
  @override
  int get hashCode => minor.hashCode;
}
