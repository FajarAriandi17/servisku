import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final _num = NumberFormat.decimalPattern('id_ID');

String rupiah(int v) => _rupiah.format(v);
String km(int v) => '${_num.format(v)} km';
String numFmt(int v) => _num.format(v);
String dateFmt(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
String dateShort(DateTime d) => DateFormat('d MMM', 'id_ID').format(d);

String daysLabel(int d) {
  if (d == 0) return 'Hari ini';
  if (d == 1) return 'Besok';
  if (d < 0) return '${-d} hari lewat';
  if (d < 31) return '$d hari lagi';
  final m = (d / 30).floor();
  return '± $m bulan lagi';
}

String kmLeftLabel(int k) {
  if (k < 0) return 'Lewat ${km(-k)}';
  return 'Sisa ${km(k)}';
}

int parseInt(String s) =>
    int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}
