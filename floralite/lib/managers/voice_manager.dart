import '../services/voice_service.dart';

class VoiceManager {
  VoiceManager(this._voiceService);

  final VoiceService _voiceService;

  bool get isListening => _voiceService.isListening;
  String get recognizedText => _voiceService.recognizedText;

  Future<void> startListening() async {
    await _voiceService.startListening();
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  void setRecognizedText(String text) {
    _voiceService.setRecognizedText(text);
  }
}
