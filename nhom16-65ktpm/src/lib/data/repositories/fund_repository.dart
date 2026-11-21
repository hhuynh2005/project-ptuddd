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

  // ==============================
  // THỬ THÁCH VIỆC TỐT
  // ==============================
  @override
  Future<List<ChallengeModel>> getChallenges() => challengeRepo.getChallenges();

  @override
  Future<ChallengeModel?> getChallengeById(String id) =>
      challengeRepo.getChallengeById(id);

  @override
  Future<int> addChallenge(ChallengeModel challenge) =>
      challengeRepo.addChallenge(challenge);

  // ==============================
  // MINH CHỨNG & PHÊ DUYỆT
  // ==============================
  @override
  Future<List<ProofModel>> getProofs() => proofRepo.getProofs();

  @override
  Future<List<ProofModel>> getPendingProofs() => proofRepo.getPendingProofs();

  @override
  Future<int> submitProof(ProofModel proof) => proofRepo.submitProof(proof);

  @override
  Future<bool> approveProof(String proofId, {String? feedback}) =>
      proofRepo.approveProof(proofId, feedback: feedback);

  @override
  Future<bool> rejectProof(String proofId, {required String reason}) =>
      proofRepo.rejectProof(proofId, reason: reason);

  // ==============================
  // SỔ QUỸ THU - CHI
  // ==============================
  @override
  Future<List<FundTransactionModel>> getTransactions() =>
      transactionRepo.getTransactions();

  @override
  Future<int> recordTransaction(FundTransactionModel tx) =>
      transactionRepo.recordTransaction(tx);

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
