import '../datasources/database_helper.dart';
import '../models/challenge_model.dart';
import '../models/fund_transaction_model.dart';
import '../models/proof_model.dart';

/// Repository trung gian cung cấp dữ liệu từ SQLite Database cho toàn bộ ứng dụng
class FundRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ==============================
  // SỔ QUỸ THU - CHI
  // ==============================
  Future<List<FundTransactionModel>> getTransactions() {
    return _db.getAllTransactions();
  }

  Future<int> recordTransaction(FundTransactionModel tx) {
    return _db.insertTransaction(tx);
  }

  Future<double> getTotalIncome() => _db.getTotalIncome();
  Future<double> getTotalExpense() => _db.getTotalExpense();
  Future<double> getBalance() => _db.getBalance();

  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _db.filterTransactions(
      type: type,
      category: category,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  // ==============================
  // THỬ THÁCH VIỆC TỐT
  // ==============================
  Future<List<ChallengeModel>> getChallenges() => _db.getAllChallenges();
  Future<ChallengeModel?> getChallengeById(String id) => _db.getChallengeById(id);
  Future<int> addChallenge(ChallengeModel challenge) => _db.insertChallenge(challenge);

  // ==============================
  // MINH CHỨNG & PHÊ DUYỆT
  // ==============================
  Future<List<ProofModel>> getProofs() => _db.getAllProofs();
  Future<List<ProofModel>> getPendingProofs() => _db.getPendingProofs();
  Future<int> submitProof(ProofModel proof) => _db.insertProof(proof);

  /// Duyệt minh chứng -> tự động tạo giao dịch Thu vào Quỹ
  Future<bool> approveProof(String proofId, {String? feedback}) =>
      _db.approveProof(proofId, adminFeedback: feedback);

  /// Từ chối minh chứng
  Future<bool> rejectProof(String proofId, {required String reason}) =>
      _db.rejectProof(proofId, reason: reason);
}

