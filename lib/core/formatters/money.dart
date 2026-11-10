import 'package:intl/intl.dart';

final _vndFormat = NumberFormat.decimalPattern('vi_VN');

/// Prices are whole Vietnamese đồng; no floating-point monetary values.
String formatVnd(int amount) => '${_vndFormat.format(amount)}đ';
