/// Mock data riêng cho Sprint 1 — KHÔNG import model của bạn khác.
/// Mục đích: Analytics & Admin Review chạy được trước khi dữ liệu thật
/// (FundTransactionModel của Lê Anh Tuấn, ProofModel của Kiên) sẵn sàng.
/// Sprint 4: xóa file này, đưa List thật vào AnalyticsService thay thế.
/// Ngày trong mock dùng DateTime.now() trừ đi số ngày, nên biểu đồ
/// luôn có dữ liệu dù chạy vào ngày nào.

/// Một giao dịch quỹ (bản mock của FundTransactionModel).
class MockFundTx {
  const MockFundTx({
    required this.date,
    required this.isIncome,
    required this.amount,
    required this.challenge,
    required this.description,
  });

  final DateTime date;
  final bool isIncome; // true = thu, false = chi
  final double amount;
  final String challenge; // loại thử thách, vd 'Dậy sớm'
  final String description;
}

/// Một minh chứng chờ duyệt (bản mock của ProofModel).
class MockProof {
  MockProof({
    required this.id,
    required this.memberName,
    required this.challengeName,
    required this.submittedAt,
    required this.sponsorAmount,
    required this.note,
    required this.ocrText,
    required this.detectedTime,
  });

  final String id;
  final String memberName;
  final String challengeName;
  final DateTime submittedAt;
  final double sponsorAmount;
  final String note;
  final String ocrText; // chữ OCR đọc được (gợi ý cho Admin)
  final String detectedTime; // giờ OCR đọc được
}

DateTime _daysAgo(int days, {int hour = 7, int minute = 10}) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, hour, minute);
}

/// Giao dịch 3 tháng gần nhất: đủ dữ liệu cho biểu đồ cột thu/chi
/// theo tháng + 7 ngày gần nhất cho biểu đồ đường số dư.
final List<MockFundTx> mockTransactions = [
  // Tháng -2 (mock: 2 tháng trước).
  MockFundTx(
    date: _daysAgo(60, hour: 7),
    isIncome: true,
    amount: 50000,
    challenge: 'Dậy sớm',
    description: 'Tài trợ dậy sớm 6h00',
  ),
  MockFundTx(
    date: _daysAgo(55, hour: 8),
    isIncome: true,
    amount: 30000,
    challenge: 'Gia sư trẻ em',
    description: 'Tài trợ dạy học miễn phí',
  ),
  // Tháng -1.
  MockFundTx(
    date: _daysAgo(32, hour: 7),
    isIncome: true,
    amount: 50000,
    challenge: 'Dậy sớm',
    description: 'Tài trợ dậy sớm 6h00',
  ),
  MockFundTx(
    date: _daysAgo(28, hour: 9),
    isIncome: true,
    amount: 40000,
    challenge: 'Giải toán tư duy',
    description: 'Tài trợ giải toán hằng ngày',
  ),
  MockFundTx(
    date: _daysAgo(25, hour: 10),
    isIncome: false,
    amount: 100000,
    challenge: '',
    description: 'Giải ngân: mua sách cho trẻ em vùng cao',
  ),
  // 7 ngày gần nhất (cho biểu đồ đường).
  MockFundTx(
    date: _daysAgo(6, hour: 7),
    isIncome: true,
    amount: 50000,
    challenge: 'Dậy sớm',
    description: 'Tài trợ dậy sớm 6h00',
  ),
  MockFundTx(
    date: _daysAgo(5, hour: 8),
    isIncome: true,
    amount: 30000,
    challenge: 'Chạy bộ 3km',
    description: 'Tài trợ chạy bộ buổi sáng',
  ),
  MockFundTx(
    date: _daysAgo(4, hour: 7),
    isIncome: true,
    amount: 50000,
    challenge: 'Dậy sớm',
    description: 'Tài trợ dậy sớm 6h00',
  ),
  MockFundTx(
    date: _daysAgo(3, hour: 8),
    isIncome: true,
    amount: 30000,
    challenge: 'Gia sư trẻ em',
    description: 'Tài trợ dạy học miễn phí',
  ),
  MockFundTx(
    date: _daysAgo(2, hour: 10),
    isIncome: false,
    amount: 80000,
    challenge: '',
    description: 'Giải ngân: hỗ trợ bệnh nhi',
  ),
  MockFundTx(
    date: _daysAgo(1, hour: 7),
    isIncome: true,
    amount: 40000,
    challenge: 'Giải toán tư duy',
    description: 'Tài trợ giải toán hằng ngày',
  ),
  MockFundTx(
    date: _daysAgo(0, hour: 7),
    isIncome: true,
    amount: 50000,
    challenge: 'Dậy sớm',
    description: 'Tài trợ dậy sớm 6h00',
  ),
];

/// 4 minh chứng đang chờ duyệt.
/// Danh sách đã xếp cũ nhất trước.
final List<MockProof> mockProofs = [
  MockProof(
    id: 'proof-001',
    memberName: 'Nguyễn Trung Kiên',
    challengeName: 'Dậy sớm học bài',
    submittedAt: _daysAgo(1, hour: 6, minute: 5),
    sponsorAmount: 50000,
    note: 'Dậy lúc 5h55, học bài tới 7h00.',
    ocrText: '05:55 — Học bài',
    detectedTime: '05:55',
  ),
  MockProof(
    id: 'proof-002',
    memberName: 'Lê Anh Tuấn',
    challengeName: 'Gia sư trẻ em',
    submittedAt: _daysAgo(0, hour: 8, minute: 30),
    sponsorAmount: 30000,
    note: 'Dạy toán cho 2 em nhỏ buổi sáng.',
    ocrText: '08:30 — Lớp học',
    detectedTime: '08:30',
  ),
  MockProof(
    id: 'proof-003',
    memberName: 'Nguyễn Văn Huỳnh',
    challengeName: 'Chạy bộ 3km',
    submittedAt: _daysAgo(0, hour: 9, minute: 15),
    sponsorAmount: 30000,
    note: 'Chạy 3km quanh hồ, có ảnh đồng hồ.',
    ocrText: '09:15 — 3.0 km',
    detectedTime: '09:15',
  ),
  MockProof(
    id: 'proof-004',
    memberName: 'Trần Anh Tuấn',
    challengeName: 'Giải toán tư duy',
    submittedAt: _daysAgo(0, hour: 10, minute: 20),
    sponsorAmount: 40000,
    note: 'Giải xong 10 bài toán tư duy buổi sáng.',
    ocrText: '10:20 — Giải toán',
    detectedTime: '10:20',
  ),
];
