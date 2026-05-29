import '../viewmodels/settings_viewmodel.dart';

class AppStrings {
  final AppLanguage lang;

  AppStrings(this.lang);

  bool get isVi => lang == AppLanguage.vietnamese;

  String get appTitle =>
      isVi ? 'Voice UID' : 'Voice UID';

  String get scanning =>
      isVi ? 'Đang quét...' : 'Scanning...';

  String get connecting =>
      isVi ? 'Đang kết nối...' : 'Connecting...';

  String get disconnected =>
      isVi ? 'Đã ngắt kết nối' : 'Disconnected';

  String get notConnected =>
      isVi ? 'Chưa kết nối' : 'Not connected';

  String get deviceNotFound =>
      isVi ? 'Không tìm thấy thiết bị'
          : 'Device not found';

  String get scanDevice =>
      isVi ? 'QUÉT THIẾT BỊ'
          : 'SCAN DEVICE';

  String get voiceRecognition =>
      isVi ? 'NHẬN DẠNG GIỌNG NÓI'
          : 'VOICE RECOGNITION';

  String get probability =>
      isVi ? 'PHÂN PHỐI XÁC SUẤT'
          : 'PROBABILITY';

  String get history =>
      isVi ? 'LỊCH SỬ'
          : 'HISTORY';

  String get rawFeatures =>
      isVi ? 'RAW FEATURES'
          : 'RAW FEATURES';

  String get noHistory =>
      isVi ? 'Chưa có lịch sử'
          : 'No history';

  String get noData =>
      isVi ? 'Chưa có dữ liệu'
          : 'No data';

  String get stay =>
      isVi ? 'Ở lại'
          : 'Stay';

  String get exit =>
      isVi ? 'Thoát'
          : 'Exit';

  String get exitTitle =>
      isVi ? 'Thoát ứng dụng?'
          : 'Exit Application?';

  String get exitQuestion =>
      isVi
          ? 'Bạn có chắc muốn thoát Voice UID không?'
          : 'Are you sure you want to exit Voice UID?';

  String get muteOn =>
      isVi ? 'Bật tiếng' : 'Unmute';

  String get muteOff =>
      isVi ? 'Tắt tiếng' : 'Mute';

  String get lightMode =>
      isVi ? 'Chế độ sáng' : 'Light mode';

  String get darkMode =>
      isVi ? 'Chế độ tối' : 'Dark mode';

  String get disconnect =>
      isVi ? 'Ngắt kết nối' : 'Disconnect';

  String get muted =>
      isVi ? 'TẮT TIẾNG' : 'MUTED';

  String get prediction =>
      isVi ? 'NHẬN DẠNG GIỌNG NÓI'
          : 'VOICE RECOGNITION';

  String get connectionLost =>
      isVi ? 'Mất kết nối'
          : 'Connection lost';

  // Prediction labels

  String get correct =>
      isVi ? 'Đúng' : 'Correct';

  String get incorrect =>
      isVi ? 'Sai' : 'Incorrect';

  String get silence =>
      isVi ? 'Không' : 'No';
}