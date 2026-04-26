class PaymentCardUtils {
  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _holderPattern = RegExp(r"^[A-Za-zА-Яа-яЁё\s'-]{2,}$");

  static String normalizeNumber(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String? detectScheme(String number) {
    if (number.startsWith('4') && (number.length == 16 || number.length == 19)) {
      return 'Visa';
    }

    final firstTwo = number.length >= 2 ? int.tryParse(number.substring(0, 2)) : null;
    final firstFour = number.length >= 4 ? int.tryParse(number.substring(0, 4)) : null;
    final firstSix = number.length >= 6 ? int.tryParse(number.substring(0, 6)) : null;

    final isMastercard = ((firstTwo != null && firstTwo >= 51 && firstTwo <= 55) ||
            (firstFour != null && firstFour >= 2221 && firstFour <= 2720)) &&
        number.length == 16;
    if (isMastercard) {
      return 'Mastercard';
    }

    final isMaestro = (number.startsWith('50') ||
            number.startsWith('56') ||
            number.startsWith('57') ||
            number.startsWith('58') ||
            (firstSix != null && firstSix >= 600000 && firstSix <= 699999)) &&
        number.length >= 12 &&
        number.length <= 19;
    if (isMaestro) {
      return 'Maestro';
    }

    return null;
  }

  static bool isValidNumber(String rawNumber) {
    final number = normalizeNumber(rawNumber);
    if (!_digitsOnly.hasMatch(number)) return false;
    if (detectScheme(number) == null) return false;
    return _passesLuhn(number);
  }

  static bool isValidHolder(String holder) {
    return _holderPattern.hasMatch(holder.trim());
  }

  static bool isValidExpiry(String expiry) {
    final cleaned = expiry.replaceAll(' ', '');
    final parts = cleaned.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);
    if (month == null || year == null || month < 1 || month > 12) return false;

    final fullYear = year >= 100 ? year : 2000 + year;
    final now = DateTime.now();
    final expiresAt = DateTime(fullYear, month + 1);
    return expiresAt.isAfter(DateTime(now.year, now.month));
  }

  static bool isValidCvv(String cvv) {
    final trimmed = cvv.trim();
    return RegExp(r'^\d{3,4}$').hasMatch(trimmed);
  }

  static String formatNumber(String value) {
    final digits = normalizeNumber(value);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static String formatExpiry(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 2) return digits;
    return '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(2, 4))}';
  }

  static bool _passesLuhn(String number) {
    var sum = 0;
    var alternate = false;

    for (var i = number.length - 1; i >= 0; i--) {
      var digit = int.parse(number[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}
