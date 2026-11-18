import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/challenge_model.dart';
import '../models/fund_transaction_model.dart';
import '../models/proof_model.dart';

/// DatabaseHelper - Quản lý kết nối SQLite và tạo các bảng cho GoodDeeds Fund
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'gooddeeds_fund.db';
  static const int _dbVersion = 1;

  // Tên các bảng
  static const String tableChallenges = 'challenges';
  static const String tableProofs = 'proofs';
  static const String tableFundTransactions = 'fund_transactions';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  /// Tạo cấu trúc 3 bảng: challenges, proofs, fund_transactions
  Future<void> _onCreate(Database db, int version) async {
    // 1. Bảng challenges
    await db.execute('''
      CREATE TABLE $tableChallenges (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        rewardAmount REAL NOT NULL,
        category TEXT NOT NULL,
        icon TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. Bảng proofs
    await db.execute('''
      CREATE TABLE $tableProofs (
        id TEXT PRIMARY KEY,
        challengeId TEXT NOT NULL,
        challengeTitle TEXT NOT NULL,
        memberName TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        ocrExtractedText TEXT,
        detectedTime TEXT,
        submittedAt TEXT NOT NULL,
        status TEXT NOT NULL,
        rewardAmount REAL NOT NULL,
        note TEXT,
        adminFeedback TEXT,
        FOREIGN KEY (challengeId) REFERENCES $tableChallenges (id)
      )
    ''');

    // 3. Bảng fund_transactions
    await db.execute('''
      CREATE TABLE $tableFundTransactions (
        id TEXT PRIMARY KEY,
        proofId TEXT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        proofImagePath TEXT,
        note TEXT,
        recipientOrSponsor TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (proofId) REFERENCES $tableProofs (id)
      )
    ''');

    // Chèn dữ liệu mẫu ban đầu (Seed Data)
    await _seedInitialData(db);
  }

  /// Khởi tạo dữ liệu mẫu ban đầu cho chiến dịch
  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();

    // Thử thách mẫu
    final defaultChallenges = [
      const ChallengeModel(
        id: 'ch_01',
        title: 'Dậy sớm trước 6:00 sáng',
        description: 'Chụp ảnh bàn học, đồng hồ hoặc app báo thức chứng minh bạn đã dậy và học bài trước 6h00.',
        rewardAmount: 20000,
        category: 'Kỷ luật',
        icon: 'wb_sunny',
      ),
      const ChallengeModel(
        id: 'ch_02',
        title: 'Gia sư dạy học cho trẻ em',
        description: 'Dạy kèm 1 buổi học (toán, tiếng Việt, tiếng Anh) cho các em nhỏ có hoàn cảnh khó khăn.',
        rewardAmount: 50000,
        category: 'Gia sư',
        icon: 'school',
      ),
      const ChallengeModel(
        id: 'ch_03',
        title: 'Giải 5 bài toán tư duy / code thuật toán',
        description: 'Chụp ảnh bài giải hoặc commit code trên nền tảng LeetCode/HackerRank rèn luyện tư duy.',
        rewardAmount: 30000,
        category: 'Học tập',
        icon: 'psychology',
      ),
      const ChallengeModel(
        id: 'ch_04',
        title: 'Chạy bộ 3km hoặc rèn luyện thể thao',
        description: 'Chụp ảnh màn hình ứng dụng Strava / Smartwatch ghi nhận hoạt động chạy bộ nâng cao sức khỏe.',
        rewardAmount: 25000,
        category: 'Sức khỏe',
        icon: 'directions_run',
      ),
    ];

    for (final ch in defaultChallenges) {
      await db.insert(tableChallenges, ch.toMap());
    }

    // Giao dịch mở quỹ mẫu
    final initialTx = FundTransactionModel(
      id: 'tx_init_01',
      type: TransactionType.thu,
      amount: 2000000,
      title: 'Tài trợ mở quỹ từ Cựu sinh viên KTPM',
      category: 'Tài trợ mở quỹ',
      note: 'Khoản tài trợ ban đầu của cựu sinh viên khóa 60 cho GoodDeeds Fund',
      recipientOrSponsor: 'Cựu sinh viên Khoa CNTT',
      createdAt: now.subtract(const Duration(days: 10)),
    );
    await db.insert(tableFundTransactions, initialTx.toMap());
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
