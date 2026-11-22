import 'package:flutter_test/flutter_test.dart';
import 'package:gooddeeds_fund/data/models/challenge_model.dart';
import 'package:gooddeeds_fund/data/models/fund_transaction_model.dart';
import 'package:gooddeeds_fund/data/models/proof_model.dart';
import 'package:gooddeeds_fund/data/repositories/challenge_repository.dart';
import 'package:gooddeeds_fund/data/repositories/fund_repository.dart';
import 'package:gooddeeds_fund/data/repositories/fund_transaction_repository.dart';
import 'package:gooddeeds_fund/data/repositories/proof_repository.dart';

/// Mock Challenge Repository phục vụ unit test độc lập
class MockChallengeRepository implements IChallengeRepository {
  final List<ChallengeModel> _challenges = [];

  @override
  Future<List<ChallengeModel>> getChallenges() async {
    return List.unmodifiable(_challenges);
  }

  @override
  Future<ChallengeModel?> getChallengeById(String id) async {
    try {
      return _challenges.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> addChallenge(ChallengeModel challenge) async {
    _challenges.add(challenge);
    return 1;
  }
}

/// Mock Proof Repository phục vụ unit test độc lập
class MockProofRepository implements IProofRepository {
  final List<ProofModel> _proofs = [];

  @override
  Future<List<ProofModel>> getProofs() async {
    return List.unmodifiable(_proofs);
  }

  @override
  Future<List<ProofModel>> getPendingProofs() async {
    return _proofs.where((p) => p.isPending).toList();
  }

  @override
  Future<int> submitProof(ProofModel proof) async {
    _proofs.insert(0, proof);
    return 1;
  }

  @override
  Future<bool> approveProof(String proofId, {String? feedback}) async {
    final index = _proofs.indexWhere((p) => p.id == proofId);
    if (index == -1) return false;
    _proofs[index] = _proofs[index].copyWith(
      status: ProofStatus.approved,
      adminFeedback: feedback ?? 'Đã duyệt',
    );
    return true;
  }

  @override
  Future<bool> rejectProof(String proofId, {required String reason}) async {
    final index = _proofs.indexWhere((p) => p.id == proofId);
    if (index == -1) return false;
    _proofs[index] = _proofs[index].copyWith(
      status: ProofStatus.rejected,
      adminFeedback: reason,
    );
    return true;
  }
}

/// Mock Fund Transaction Repository phục vụ unit test độc lập
class MockFundTransactionRepository implements IFundTransactionRepository {
  final List<FundTransactionModel> _transactions = [];

  @override
  Future<List<FundTransactionModel>> getTransactions() async {
    final sorted = List<FundTransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<int> recordTransaction(FundTransactionModel tx) async {
    _transactions.insert(0, tx);
    return 1;
  }

  @override
  Future<double> getTotalIncome() async {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getTotalExpense() async {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getBalance() async {
    final income = await getTotalIncome();
    final expense = await getTotalExpense();
    return income - expense;
  }

  @override
  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return _transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (category != null && category.isNotEmpty && t.category != category) {
        return false;
      }
      if (fromDate != null && t.createdAt.isBefore(fromDate)) return false;
      if (toDate != null && t.createdAt.isAfter(toDate)) return false;
      return true;
    }).toList();
  }
}

void main() {
  group('FundRepository Architecture & Financial Logic Unit Tests', () {
    late MockChallengeRepository mockChallengeRepo;
    late MockProofRepository mockProofRepo;
    late MockFundTransactionRepository mockTxRepo;
    late FundRepository fundRepository;

    setUp(() {
      mockChallengeRepo = MockChallengeRepository();
      mockProofRepo = MockProofRepository();
      mockTxRepo = MockFundTransactionRepository();

      // Tiêm các Mock Repositories vào Facade FundRepository
      fundRepository = FundRepository(
        challengeRepository: mockChallengeRepo,
        proofRepository: mockProofRepo,
        transactionRepository: mockTxRepo,
      );
    });

    test('1. Thử thách: Thêm và truy xuất danh sách thử thách', () async {
      const challenge = ChallengeModel(
        id: 'ch_unit_01',
        title: 'Chạy bộ 5km',
        description: 'Chụp ảnh strava hoàn thành 5km',
        rewardAmount: 30000.0,
        category: 'Sức khỏe',
        icon: 'directions_run',
      );

      await fundRepository.addChallenge(challenge);

      final list = await fundRepository.getChallenges();
      expect(list.length, 1);
      expect(list.first.title, 'Chạy bộ 5km');

      final item = await fundRepository.getChallengeById('ch_unit_01');
      expect(item, isNotNull);
      expect(item!.rewardAmount, 30000.0);
    });

    test('2. Minh chứng: Nộp và duyệt/từ chối minh chứng', () async {
      final proof = ProofModel(
        id: 'p_01',
        challengeId: 'ch_unit_01',
        challengeTitle: 'Chạy bộ 5km',
        memberName: 'Lê Anh Tuấn',
        imagePath: '/images/proof.jpg',
        ocrExtractedText: '5.02 km - Pace 6:15',
        submittedAt: DateTime.now(),
        rewardAmount: 30000.0,
      );

      await fundRepository.submitProof(proof);

      // Ban đầu là pending
      var pendingList = await fundRepository.getPendingProofs();
      expect(pendingList.length, 1);
      expect(pendingList.first.isPending, isTrue);

      // Duyệt minh chứng
      final approved = await fundRepository.approveProof('p_01', feedback: 'Tốt lắm!');
      expect(approved, isTrue);

      pendingList = await fundRepository.getPendingProofs();
      expect(pendingList.isEmpty, isTrue);

      final allProofs = await fundRepository.getProofs();
      expect(allProofs.first.isApproved, isTrue);
      expect(allProofs.first.adminFeedback, 'Tốt lắm!');
    });

    test('3. Sổ Quỹ: Tính toán chính xác Tổng Thu, Tổng Chi và Số Dư', () async {
      final now = DateTime.now();

      // Ghi nhận 2 khoản THU (tài trợ)
      await fundRepository.recordTransaction(FundTransactionModel(
        id: 'tx_in_1',
        type: TransactionType.thu,
        amount: 1000000.0,
        title: 'Mở quỹ từ cựu sinh viên',
        category: 'Tài trợ',
        recipientOrSponsor: 'Cựu sinh viên',
        createdAt: now.subtract(const Duration(days: 2)),
      ));

      await fundRepository.recordTransaction(FundTransactionModel(
        id: 'tx_in_2',
        type: TransactionType.thu,
        amount: 500000.0,
        title: 'Tài trợ thử thách việc tốt',
        category: 'Thử thách',
        recipientOrSponsor: 'Doanh nghiệp',
        createdAt: now.subtract(const Duration(days: 1)),
      ));

      // Ghi nhận 1 khoản CHI (giải ngân từ thiện)
      await fundRepository.recordTransaction(FundTransactionModel(
        id: 'tx_out_1',
        type: TransactionType.chi,
        amount: 300000.0,
        title: 'Mua bánh kẹo và sữa cho mái ấm',
        category: 'Từ thiện',
        recipientOrSponsor: 'Mái ấm Hoa Sen',
        createdAt: now,
      ));

      final totalIncome = await fundRepository.getTotalIncome();
      final totalExpense = await fundRepository.getTotalExpense();
      final balance = await fundRepository.getBalance();

      // Kiểm tra công thức cân đối quỹ: Số dư = Tổng Thu - Tổng Chi
      expect(totalIncome, 1500000.0);
      expect(totalExpense, 300000.0);
      expect(balance, 1200000.0);
      expect(balance, equals(totalIncome - totalExpense));
    });

    test('4. Bộ lọc: Lọc giao dịch theo loại Thu/Chi', () async {
      final now = DateTime.now();
      await fundRepository.recordTransaction(FundTransactionModel(
        id: 't1',
        type: TransactionType.thu,
        amount: 100000.0,
        title: 'Thu 1',
        category: 'Test',
        recipientOrSponsor: 'A',
        createdAt: now,
      ));
      await fundRepository.recordTransaction(FundTransactionModel(
        id: 't2',
        type: TransactionType.chi,
        amount: 50000.0,
        title: 'Chi 1',
        category: 'Test',
        recipientOrSponsor: 'B',
        createdAt: now,
      ));

      final onlyIncome = await fundRepository.filterTransactions(type: TransactionType.thu);
      expect(onlyIncome.length, 1);
      expect(onlyIncome.first.type, TransactionType.thu);

      final onlyExpense = await fundRepository.filterTransactions(type: TransactionType.chi);
      expect(onlyExpense.length, 1);
      expect(onlyExpense.first.type, TransactionType.chi);
    });
  });
}

