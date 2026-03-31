import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
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

  Future<String?> removeBackground() async {
    // WARNING: Replace with your actual API key!
    const String apiKey = 'V4jW92ExGe44oN4Gjsi91ZxB'; 
    
    if (_processedImageBytes == null) return "No image to process";
    
    _isProcessing = true;
    notifyListeners();

    try {
      final request = http.MultipartRequest('POST', Uri.parse('https://api.remove.bg/v1.0/removebg'));
      request.headers['X-Api-Key'] = apiKey;
      request.files.add(http.MultipartFile.fromBytes('image_file', _processedImageBytes!, filename: 'photo.jpg'));
      request.fields['size'] = 'auto';

      final response = await request.send();
      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        
        // Use background isolate to fill transparency with white for passport standards
        _processedImageBytes = await compute(_fillBackgroundWhite, bytes);
        
        _isProcessing = false;
        notifyListeners();
        return null;
      } else {
        _isProcessing = false;
        notifyListeners();
        return "API Error: ${response.statusCode}";
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> applyStandard() async {
    if (_originalImageBytes == null || _selectedStandard == null) return;
    _isProcessing = true;
    notifyListeners();

    try {
      // Use compute to run heavy image processing in a background Isolate
      _processedImageBytes = await compute(_processImageTask, {
        'bytes': _originalImageBytes!,
        'standard': _selectedStandard!,
      });
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

// Background Task: Process image standards
Future<Uint8List?> _processImageTask(Map<String, dynamic> params) async {
  final Uint8List bytes = params['bytes'];
  final PassportStandard standard = params['standard'];
  
  final decodedImage = img.decodeImage(bytes);
  if (decodedImage == null) return null;

  final targetAspect = standard.widthMm / standard.heightMm;
  
  img.Image cropped;
  int width = decodedImage.width;
  int height = decodedImage.height;
  double currentAspect = width / height;

  if (currentAspect > targetAspect) {
    int newWidth = (height * targetAspect).toInt();
    int offset = (width - newWidth) ~/ 2;
    cropped = img.copyCrop(decodedImage, x: offset, y: 0, width: newWidth, height: height);
  } else {
    int newHeight = (width / targetAspect).toInt();
    int offset = (height - newHeight) ~/ 2;
    cropped = img.copyCrop(decodedImage, x: 0, y: offset, width: width, height: newHeight);
  }

  return Uint8List.fromList(img.encodeJpg(cropped, quality: 95));
}

// Background Task: Fill transparent background with solid white
Future<Uint8List?> _fillBackgroundWhite(Uint8List bytes) async {
  final foreground = img.decodePng(bytes);
  if (foreground == null) return bytes;

  // Create solid white background image of the same size
  final background = img.Image(
    width: foreground.width,
    height: foreground.height,
  )..clear(img.ColorRgb8(255, 255, 255));

  // Blend subject onto white background
  img.compositeImage(background, foreground);

  return Uint8List.fromList(img.encodeJpg(background, quality: 95));
}
