import 'money.dart';

/// Fixed 12-place decimal. Financial arithmetic never passes through double.
final class Decimal implements Comparable<Decimal> {
  Decimal(this.raw);
  static final scale = BigInt.from(10).pow(12);
  static final zero = Decimal(BigInt.zero);
  static final one = Decimal(scale);
  final BigInt raw;
  factory Decimal.parse(String value) {
    if (value.length > 65 ||
        !RegExp(r'^-?\d+(?:\.\d{1,12})?$').hasMatch(value)) {
      throw const FormatException(
        'Gunakan angka desimal titik, maksimal 12 desimal.',
      );
    }
    final parts = value.replaceAll('-', '').split('.');
    final n =
        BigInt.parse(parts[0]) * scale +
        BigInt.parse((parts.length == 1 ? '' : parts[1]).padRight(12, '0'));
    return Decimal(value.startsWith('-') ? -n : n);
  }
  factory Decimal.input(String value) =>
      Decimal.parse(value.trim().replaceAll(',', '.'));

  /// Only for API JSON numbers; canonicalizes scientific notation first.
  factory Decimal.api(Object? value) {
    if (value is! num && value is! String) {
      throw const FormatException('Harga tidak valid.');
    }
    var text = value.toString();
    if (text.contains(RegExp('[eE]'))) {
      final parts = text.toLowerCase().split('e');
      final exp = int.parse(parts[1]);
      if (exp.abs() > 30) {
        throw const FormatException('Angka API di luar batas.');
      }
      final mantissa = parts[0].split('.');
      final digits = mantissa.join();
      final point = mantissa[0].length + exp;
      text = point <= 0
          ? '0.${'0' * -point}$digits'
          : point >= digits.length
          ? digits.padRight(point, '0')
          : '${digits.substring(0, point)}.${digits.substring(point)}';
    }
    final parts = text.split('.');
    if (parts.length == 2 && parts[1].length > 12) {
      text = '${parts[0]}.${parts[1].substring(0, 12)}';
    }
    return Decimal.parse(text);
  }
  bool get positive => raw > BigInt.zero;
  bool get negative => raw.isNegative;
  bool get isZero => raw == BigInt.zero;
  Decimal operator +(Decimal other) => Decimal(raw + other.raw);
  Decimal operator -(Decimal other) => Decimal(raw - other.raw);
  Decimal operator *(Decimal other) =>
      Decimal(roundRatio(raw * other.raw, scale));
  Decimal operator /(Decimal other) =>
      Decimal(roundRatio(raw * scale, other.raw));
  Money money() => Money(roundRatio(raw * BigInt.from(100), scale));
  Money timesMoney(Money money) => Money(roundRatio(money.minor * raw, scale));
  String get text {
    final digits = raw.abs().toString().padLeft(13, '0');
    final fraction = digits
        .substring(digits.length - 12)
        .replaceFirst(RegExp(r'0+$'), '');
    return '${negative ? '-' : ''}${digits.substring(0, digits.length - 12)}${fraction.isEmpty ? '' : '.$fraction'}';
  }

  @override
  int compareTo(Decimal other) => raw.compareTo(other.raw);
  @override
  bool operator ==(Object other) => other is Decimal && raw == other.raw;
  @override
  int get hashCode => raw.hashCode;
}

BigInt roundRatio(BigInt numerator, BigInt denominator) {
  if (denominator == BigInt.zero) {
    throw const FormatException('Pembagi tidak boleh nol.');
  }
  final negative = numerator.isNegative != denominator.isNegative;
  final n = numerator.abs(), d = denominator.abs();
  final value = (n * BigInt.two + d) ~/ (d * BigInt.two);
  return negative ? -value : value;
}

const currencies = ['IDR', 'USD', 'USDT', 'SGD', 'EUR', 'MYR'];
String currencyMoney(Money value, String currency) => currency == 'IDR'
    ? value.formatted
    : '$currency ${value.formatted.replaceFirst('Rp ', '')}';
