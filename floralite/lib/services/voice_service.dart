class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  bool _isListening = false;
  String _recognizedText = '';

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<void> startListening() async {
    _isListening = true;
    _recognizedText = '';
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  void setRecognizedText(String text) {
    _recognizedText = text;
  }
}
