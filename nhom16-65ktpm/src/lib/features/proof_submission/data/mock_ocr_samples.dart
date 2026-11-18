// Dữ liệu mẫu phục vụ kiểm thử tích hợp OCR trong Sprint 1.
// Mô phỏng kết quả văn bản xuất hiện trên ảnh check-in thử thách việc tốt.

class MockOcrSample {
  const MockOcrSample({
    required this.id,
    required this.challengeTitle,
    required this.sampleText,
    required this.description,
  });

  final String id;
  final String challengeTitle;
  final String sampleText;
  final String description;
}

const List<MockOcrSample> mockOcrSamples = [
  MockOcrSample(
    id: 'sample_early_valid',
    challengeTitle: 'Dậy sớm học bài trước 06:00',
    sampleText: '05:42 AM - 18/11/2026\nÔn tập Lập trình Thiết bị Di động Flutter\nNhóm 16 - 65KTPM',
    description: 'Ảnh chụp đồng hồ bàn học lúc 05:42 sáng (Hợp lệ < 06:00)',
  ),
  MockOcrSample(
    id: 'sample_early_late',
    challengeTitle: 'Dậy sớm học bài trước 06:00',
    sampleText: '07:25 - Check-in bàn học buổi sáng\nĐọc tài liệu Clean Architecture',
    description: 'Ảnh chụp đồng hồ lúc 07:25 sáng (Trễ giờ quy định)',
  ),
  MockOcrSample(
    id: 'sample_tutor',
    challengeTitle: 'Gia sư miễn phí cho trẻ em',
    sampleText: '19:00 - Lớp học tình thương\nBài giảng: Toán tư duy & Phân số lớp 5',
    description: 'Ảnh chụp bảng viết lớp dạy học tình nguyện buổi tối',
  ),
  MockOcrSample(
    id: 'sample_math_coding',
    challengeTitle: 'Giải toán & Lập trình mỗi ngày',
    sampleText: '21:15\nHoàn thành 5 bài tập thuật toán Quy hoạch động & Cấu trúc dữ liệu',
    description: 'Ảnh chụp màn hình/vở bài tập toán và lập trình',
  ),
];
