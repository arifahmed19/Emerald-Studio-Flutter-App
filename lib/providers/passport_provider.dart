import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/passport_standard.dart';

class PassportProvider extends ChangeNotifier {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  PassportStandard? _selectedStandard;
  bool _isProcessing = false;

  Uint8List? get originalImageBytes => _originalImageBytes;
  Uint8List? get processedImageBytes => _processedImageBytes;
  PassportStandard? get selectedStandard => _selectedStandard;
  bool get isProcessing => _isProcessing;

  PassportProvider() {
    // default standard
    _selectedStandard = PassportStandard.defaultStandards[0];
  }

  void setStandard(PassportStandard standard) {
    _selectedStandard = standard;
    notifyListeners();
    if (_originalImageBytes != null) {
      applyStandard();
    }
  }

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      await setImageBytes(bytes);
    }
  }

  Future<void> setImageBytes(Uint8List bytes) async {
    _originalImageBytes = bytes;
    _processedImageBytes = null;
    notifyListeners();
    await applyStandard();
  }

  Future<void> applyStandard() async {
    if (_originalImageBytes == null || _selectedStandard == null) return;
    _isProcessing = true;
    notifyListeners();

    try {
      final decodedImage = img.decodeImage(_originalImageBytes!);
      if (decodedImage != null) {
        // Compute target aspect ratio from standard
        final targetAspect = _selectedStandard!.widthMm / _selectedStandard!.heightMm;
        
        // Simple center crop
        img.Image cropped;
        int width = decodedImage.width;
        int height = decodedImage.height;
        double currentAspect = width / height;

        if (currentAspect > targetAspect) {
          // Image is wider, crop width
          int newWidth = (height * targetAspect).toInt();
          int offset = (width - newWidth) ~/ 2;
          cropped = img.copyCrop(decodedImage, x: offset, y: 0, width: newWidth, height: height);
        } else {
          // Image is taller, crop height
          int newHeight = (width / targetAspect).toInt();
          int offset = (height - newHeight) ~/ 2;
          cropped = img.copyCrop(decodedImage, x: 0, y: offset, width: width, height: newHeight);
        }

        _processedImageBytes = Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
      }
    } catch (e) {
      debugPrint('Processing error: $e');
    }

    _isProcessing = false;
    notifyListeners();
  }

  void clear() {
    _originalImageBytes = null;
    _processedImageBytes = null;
    notifyListeners();
  }
}
