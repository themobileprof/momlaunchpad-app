import 'package:intl/intl.dart';
import '../models/hospital_bag_item.dart';

/// Formats a hospital bag checklist for sharing via the system share sheet.
String formatHospitalBagShareText(HospitalBagList list) {
  final buffer = StringBuffer('Hospital bag checklist\n');
  buffer.writeln('${list.packedCount} of ${list.totalCount} packed');

  if (list.totalPrice > 0) {
    buffer.writeln(
      'Estimated total: ${_formatMoney(list.totalPrice, list.currency)}',
    );
  }
  buffer.writeln();

  final grouped = <String, List<HospitalBagItem>>{};
  for (final item in list.items) {
    grouped.putIfAbsent(item.category, () => []).add(item);
  }

  for (final category in HospitalBagCategory.order) {
    final items = grouped[category];
    if (items == null || items.isEmpty) continue;

    buffer.writeln(HospitalBagCategory.label(category));
    for (final item in items) {
      final check = item.isPacked ? '✓' : '○';
      final price = item.price != null
          ? ' — ${_formatMoney(item.price!, list.currency)}'
          : '';
      buffer.writeln('  $check ${item.label}$price');
    }
    buffer.writeln();
  }

  buffer.writeln('Shared from MomLaunchpad');
  return buffer.toString().trim();
}

String _formatMoney(double amount, String currency) {
  final symbol = _currencySymbol(currency);
  return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(amount);
}

String _currencySymbol(String currencyCode) {
  switch (currencyCode) {
    case 'NGN':
      return '₦';
    case 'USD':
      return '\$';
    default:
      return currencyCode;
  }
}
