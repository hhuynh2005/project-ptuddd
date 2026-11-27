import 'package:flutter/foundation.dart';
import '../datasources/database_helper.dart';
import '../models/challenge_model.dart';
import '../models/fund_transaction_model.dart';
import '../models/proof_model.dart';
import 'challenge_repository.dart';
import 'fund_transaction_repository.dart';
import 'proof_repository.dart';

/// Triển khai SQLite cho ChallengeRepository
class ChallengeRepositoryImpl implements IChallengeRepository {
  final DatabaseHelper _db;

  ChallengeRepositoryImpl({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  @override
  Future<List<ChallengeModel>> getChallenges() => _db.getAllChallenges();

  @override
  Future<ChallengeModel?> getChallengeById(String id) =>
      _db.getChallengeById(id);

  @override
  Future<int> addChallenge(ChallengeModel challenge) =>
      _db.insertChallenge(challenge);
}

/// Triển khai SQLite cho ProofRepository
class ProofRepositoryImpl implements IProofRepository {
  final DatabaseHelper _db;

  ProofRepositoryImpl({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  @override
  Future<List<ProofModel>> getProofs() => _db.getAllProofs();

  @override
  Future<List<ProofModel>> getPendingProofs() => _db.getPendingProofs();

  @override
  Future<int> submitProof(ProofModel proof) => _db.insertProof(proof);

  @override
  Future<bool> approveProof(String proofId, {String? feedback}) =>
      _db.approveProof(proofId, adminFeedback: feedback);

  @override
  Future<bool> rejectProof(String proofId, {required String reason}) =>
      _db.rejectProof(proofId, reason: reason);
}

/// Triển khai SQLite cho FundTransactionRepository
class FundTransactionRepositoryImpl implements IFundTransactionRepository {
  final DatabaseHelper _db;

  FundTransactionRepositoryImpl({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  @override
  Future<List<FundTransactionModel>> getTransactions() =>
      _db.getAllTransactions();

  @override
  Future<int> recordTransaction(FundTransactionModel tx) =>
      _db.insertTransaction(tx);

  @override
  Future<double> getTotalIncome() => _db.getTotalIncome();

  @override
  Future<double> getTotalExpense() => _db.getTotalExpense();

  @override
  Future<double> getBalance() => _db.getBalance();

  @override
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
}

/// Facade Repository trung gian tương thích ngược 100% với toàn bộ ứng dụng
class FundRepository
    implements
        IChallengeRepository,
        IProofRepository,
        IFundTransactionRepository {
  FundRepository._internal()
      : challengeRepo = ChallengeRepositoryImpl(),
        proofRepo = ProofRepositoryImpl(),
        transactionRepo = FundTransactionRepositoryImpl();

  FundRepository({
    IChallengeRepository? challengeRepository,
    IProofRepository? proofRepository,
    IFundTransactionRepository? transactionRepository,
  })  : challengeRepo = challengeRepository ?? ChallengeRepositoryImpl(),
        proofRepo = proofRepository ?? ProofRepositoryImpl(),
        transactionRepo =
            transactionRepository ?? FundTransactionRepositoryImpl();

  static final FundRepository instance = FundRepository._internal();

  final IChallengeRepository challengeRepo;
  final IProofRepository proofRepo;
  final IFundTransactionRepository transactionRepo;

  /// Bộ đếm phiên bản cập nhật quỹ để phát tín hiệu đồng bộ Realtime (Dashboard, Sổ Quỹ, Badge)
  final ValueNotifier<int> fundUpdateVersion = ValueNotifier<int>(0);

  /// Kích hoạt thông báo khi có biến động quỹ hoặc minh chứng
  void notifyFundUpdated() {
    fundUpdateVersion.value++;
  }

  // ==============================
  // THỬ THÁCH VIỆC TỐT
  // ==============================
  @override
  Future<List<ChallengeModel>> getChallenges() => challengeRepo.getChallenges();

  @override
  Future<ChallengeModel?> getChallengeById(String id) =>
      challengeRepo.getChallengeById(id);

  @override
  Future<int> addChallenge(ChallengeModel challenge) async {
    final result = await challengeRepo.addChallenge(challenge);
    if (result > 0) notifyFundUpdated();
    return result;
  }

  // ==============================
  // MINH CHỨNG & PHÊ DUYỆT
  // ==============================
  @override
  Future<List<ProofModel>> getProofs() => proofRepo.getProofs();

  @override
  Future<List<ProofModel>> getPendingProofs() => proofRepo.getPendingProofs();

  @override
  Future<int> submitProof(ProofModel proof) async {
    final result = await proofRepo.submitProof(proof);
    if (result > 0) notifyFundUpdated();
    return result;
  }

  @override
  Future<bool> approveProof(String proofId, {String? feedback}) async {
    final result = await proofRepo.approveProof(proofId, feedback: feedback);
    if (result) notifyFundUpdated();
    return result;
  }

  @override
  Future<bool> rejectProof(String proofId, {required String reason}) async {
    final result = await proofRepo.rejectProof(proofId, reason: reason);
    if (result) notifyFundUpdated();
    return result;
  }

  // ==============================
  // SỔ QUỸ THU - CHI
  // ==============================
  @override
  Future<List<FundTransactionModel>> getTransactions() =>
      transactionRepo.getTransactions();

  @override
  Future<int> recordTransaction(FundTransactionModel tx) async {
    final result = await transactionRepo.recordTransaction(tx);
    if (result > 0) notifyFundUpdated();
    return result;
  }

  @override
  Future<double> getTotalIncome() => transactionRepo.getTotalIncome();

  @override
  Future<double> getTotalExpense() => transactionRepo.getTotalExpense();

  @override
  Future<double> getBalance() => transactionRepo.getBalance();

  @override
  Future<List<FundTransactionModel>> filterTransactions({
    TransactionType? type,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return transactionRepo.filterTransactions(
      type: type,
      category: category,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
