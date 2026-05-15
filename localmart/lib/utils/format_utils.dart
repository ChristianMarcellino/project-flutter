import 'dart:math';

class FormatUtils {
  static String formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      result = priceStr[i] + result;
      count++;
      if (count % 3 == 0 && i > 0) {
        result = '.$result';
      }
    }
    return "Rp $result";
  }

  static String randomDistance() {
    final value = (Random().nextDouble() * 5 + 0.3);
    return "${value.toStringAsFixed(1)} km";
  }
}
