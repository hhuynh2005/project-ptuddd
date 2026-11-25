import 'package:intl/intl.dart';

import '../../data/models/fund_transaction_model.dart';
import 'analytics_service.dart';

/// Dựng nội dung các file báo cáo xuất ra từ màn Thống kê (Giai đoạn 4).
class ReportExporter {
  const ReportExporter();

  /// Nội dung CSV của Sổ Quỹ (C8): dòng tiêu đề cột + mỗi giao dịch
  /// một dòng (cũ nhất trước) + 3 dòng tổng hợp Tổng thu / Tổng chi /
  /// Số dư ở cuối. Dấu tách cột là chấm phẩy ";" vì Excel theo cài
  /// đặt vùng tiếng Việt dùng ";" (dấu phẩy là dấu thập phân) — dùng
  /// dấu phẩy thì file mở ra bị dồn thành một cột. (Không dùng dòng
  /// lệnh "sep=," vì khi có dòng đó Excel bỏ qua BOM UTF-8 và đọc
  /// theo bảng mã ANSI, làm vỡ dấu tiếng Việt.) Mọi ô đều bọc trong
  /// dấu nháy kép và nháy kép bên trong được gấp đôi, nên nội dung
  /// chứa dấu chấm phẩy không làm vỡ cột. Số tiền ghi dạng số thô
  /// để Excel tính được.
  String buildCsv(List<FundTransactionModel> txs) {
    String cell(Object? value) =>
        '"${(value?.toString() ?? '').replaceAll('"', '""')}"';
    String amount(double v) =>
        v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(2);

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final sorted = [...txs]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    const service = AnalyticsService();

    final rows = <String>[
      'Ngày;Loại;Danh mục;Nội dung;Số tiền (đ);Người / Nhà tài trợ;Ghi chú',
      for (final tx in sorted)
        [
          cell(dateFormat.format(tx.createdAt)),
          cell(tx.isIncome ? 'Thu' : 'Chi'),
          cell(tx.category),
          cell(tx.title),
          cell(amount(tx.amount)),
          cell(tx.recipientOrSponsor),
          cell(tx.note),
        ].join(';'),
      '',
      [
        '',
        '',
        '',
        cell('Tổng thu'),
        cell(amount(service.totalIncome(txs))),
        '',
        '',
      ].join(';'),
      [
        '',
        '',
        '',
        cell('Tổng chi'),
        cell(amount(service.totalExpense(txs))),
        '',
        '',
      ].join(';'),
      [
        '',
        '',
        '',
        cell('Số dư'),
        cell(amount(service.balance(txs))),
        '',
        '',
      ].join(';'),
    ];
    return '${rows.join('\r\n')}\r\n';
  }
}
