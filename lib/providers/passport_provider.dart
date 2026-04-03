import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/passport_standard.dart';
import '../models/history_item.dart';

class PassportProvider extends ChangeNotifier {
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  String? _processedImagePath;
  PassportStandard? _selectedStandard;
  bool _isProcessing = false;
  List<HistoryItem> _historyItems = [];
  List<PassportStandard> _availableStandards = [];
  String? _customApiKey;
  bool _isLoadingStandards = true;

  Uint8List? get originalImageBytes => _originalImageBytes;
  Uint8List? get processedImageBytes => _processedImageBytes;
  String? get processedImagePath => _processedImagePath;
  PassportStandard? get selectedStandard => _selectedStandard;
  bool get isProcessing => _isProcessing;
  bool get isLoadingStandards => _isLoadingStandards;
  List<HistoryItem> get historyItems => _historyItems;
  List<PassportStandard> get availableStandards => _availableStandards;
  String? get customApiKey => _customApiKey;

  PassportProvider() {
    _availableStandards = PassportStandard.defaultStandards; // Optimistic first load
    _selectedStandard = _availableStandards.first;
    _initSettings().then((_) {
      // Parallel load in first phase
      Future.wait([fetchHistory(), fetchStandards()]);
    });

    // CRITICAL: Watch for user change to purge cache immediately
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedOut || event == AuthChangeEvent.userUpdated) {
        _clearAllCache();
        fetchHistory(); // Attempt fresh fetch for new user
      }
    });
  }

  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _customApiKey = prefs.getString('custom_removebg_key');
    notifyListeners();
  }

  Future<void> setCustomApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    _customApiKey = key;
    if (key == null || key.isEmpty) {
      await prefs.remove('custom_removebg_key');
    } else {
      await prefs.setString('custom_removebg_key', key);
    }
    notifyListeners();
  }

  void setStandard(PassportStandard standard) {
    if (_selectedStandard?.name == standard.name) return;
    _selectedStandard = standard;
    notifyListeners();
    if (_originalImageBytes != null) applyStandard();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await setImageBytes(bytes);
  }

  Future<void> setImageBytes(Uint8List bytes) async {
    _originalImageBytes = bytes;
    _clearProcessedState();
    notifyListeners();
    await applyStandard();
  }

  Future<void> setImageFile(String path) async {
    _setProcessing(true);
    notifyListeners();
    try {
      final safeBytes = await compute(_readFileAndShrink, path);
      if (safeBytes != null) {
        _originalImageBytes = safeBytes;
        _clearProcessedState();
        await applyStandard();
      }
    } catch (e) {
      debugPrint("Read file error: $e");
    } finally {
      // applyStandard handles setting _isProcessing = false and notifying
      if (!_isProcessing) notifyListeners(); 
    }
  }

  Future<void> loadFromHistory(Uint8List bytes, String standardName) async {
    _setProcessing(true);
    try {
      _originalImageBytes = bytes;
      _processedImageBytes = kIsWeb
          ? _toSafeJpeg(bytes)
          : await compute(_toSafeJpeg, bytes);
      if (_processedImageBytes != null) await _syncToCache();
      _selectedStandard = PassportStandard.defaultStandards.firstWhere(
        (s) => s.name == standardName,
        orElse: () => PassportStandard.defaultStandards.first,
      );
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> applyStandard() async {
    if (_originalImageBytes == null || _selectedStandard == null) return;
    _setProcessing(true);
    try {
      final params = {'bytes': _originalImageBytes!, 'standard': _selectedStandard!};
      _processedImageBytes = kIsWeb
          ? await _processImageTask(params)
          : await compute(_processImageTask, params);
      if (_processedImageBytes != null) await _syncToCache();
    } catch (e) {
      debugPrint('Studio Error: $e');
    } finally {
      _setProcessing(false);
    }
  }

  Future<String?> removeBackground() async {
    if (_processedImageBytes == null) return "No photo to process.";
    final activeKey = (_customApiKey?.isNotEmpty ?? false) ? _customApiKey! : '8z6i5R9A7X5pZp8kX4w2Z9Y6';
    
    _setProcessing(true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('https://api.remove.bg/v1.0/removebg'));
      request.headers.addAll({'X-Api-Key': activeKey, 'Accept': 'image/png'});
      request.files.add(http.MultipartFile.fromBytes('image_file', _processedImageBytes!, filename: 'photo.jpg'));
      request.fields['size'] = 'auto';


      final response = await request.send().timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        final resultBytes = await response.stream.toBytes();
        final finalBytes = kIsWeb
            ? await _fillWhiteAndToJpeg(resultBytes)
            : await compute(_fillWhiteAndToJpeg, resultBytes);
        if (finalBytes != null) {
          _processedImageBytes = finalBytes;
          await _syncToCache();
          return null;
        }
        return "Critical: AI result could not be decoded.";
      } else {
        final err = await response.stream.bytesToString();
        return "Background Removal Failed: $err";
      }
    } catch (e) {
      return "Network error during Background Removal: $e";
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> fetchStandards() async {
    try {
      final response = await Supabase.instance.client.from('standards').select().order('name');
      final list = (response as List).map((e) {
        return PassportStandard(
          country: e['country'] ?? e['name'] ?? 'Unknown',
          name: e['name'] ?? 'Unknown',
          flag: e['flag'] ?? '❓',
          widthMm: (e['width_mm'] ?? 35).toDouble(),
          heightMm: (e['height_mm'] ?? 45).toDouble(),
          description: e['description'] ?? '${e['width_mm']}x${e['height_mm']} mm',
        );
      }).toList();
      
      if (list.isNotEmpty) {
        _availableStandards = list;
        // Keep selection if it still exists in the new list, otherwise reset
        if (_selectedStandard != null) {
          final stillExists = _availableStandards.any((s) => s.name == _selectedStandard!.name);
          if (!stillExists) _selectedStandard = _availableStandards.first;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Standards Fetch Error: $e');
    } finally {
      _isLoadingStandards = false;
      notifyListeners();
    }
  }

  Future<void> _clearAllCache() async {
    _historyItems = [];
    _originalImageBytes = null;
    _processedImageBytes = null;
    _processedImagePath = null;
    notifyListeners();

    if (!kIsWeb) {
      try {
        final tempDir = await getTemporaryDirectory();
        final entities = tempDir.listSync();
        for (var entity in entities) {
          if (entity is File && entity.path.contains('studio_v2_')) {
            await entity.delete();
          }
        }
      } catch (e) {
        debugPrint("Cache Purge Error: $e");
      }
    }
  }

  Future<void> fetchHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _clearAllCache();
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('history')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      _historyItems = (response as List).map((e) => HistoryItem.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('History Error: $e');
    }
  }

  Future<void> addToHistory(String imageUrl, String standardName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('history').insert({'user_id': user.id, 'image_url': imageUrl, 'standard_name': standardName});
      await fetchHistory();
    } catch (e) {
      debugPrint('History Write Error: $e');
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    final index = _historyItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final removedItem = _historyItems.removeAt(index);
      notifyListeners();
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Delete from storage if it exists
          if (removedItem.imageUrl.contains('/photos/')) {
            final path = removedItem.imageUrl.split('/photos/').last;
            final storageRes = await Supabase.instance.client.storage.from('photos').remove([path]);
            if (storageRes.isEmpty) {
               debugPrint('Warning: Storage delete failed or skipped. (Check Storage RLS policies)');
            }
          }
          
          // Delete from DB strictly matching the ID
          await Supabase.instance.client.from('history').delete().eq('id', removedItem.id);
        }
      } catch (e) {
        _historyItems.insert(index, removedItem);
        notifyListeners();
        debugPrint('History Delete Error: $e');
        // Ignore the error throwing to UI if context isn't accessible, just reverse optimistic UI
      }
    }
  }

  Future<void> clearAllHistory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    final originalHistory = List<HistoryItem>.from(_historyItems);
    if (originalHistory.isEmpty) return;
    
    _historyItems.clear();
    notifyListeners();
    try {
      // 1. Delete all images from storage
      final paths = originalHistory
          .where((item) => item.imageUrl.contains('/photos/'))
          .map((item) => item.imageUrl.split('/photos/').last)
          .toList();
          
      if (paths.isNotEmpty) {
        final storageRes = await Supabase.instance.client.storage.from('photos').remove(paths);
        if (storageRes.isEmpty) {
           debugPrint('Warning: Bulk storage delete failed. (Check Storage RLS policies)');
        }
      }

      // 2. Delete all records from DB
      await Supabase.instance.client.from('history').delete().eq('user_id', user.id);
    } catch (e) {
      _historyItems = originalHistory;
      notifyListeners();
      debugPrint('History Clear Error: $e');
    }
  }

  void _setProcessing(bool val) {
    _isProcessing = val;
    notifyListeners();
  }

  void _clearProcessedState() {
    _processedImageBytes = null;
    _processedImagePath = null;
  }

  Future<void> _syncToCache() async {
    if (_processedImageBytes == null) return;
    // path_provider and dart:io File are not available on Web
    if (kIsWeb) {
      _processedImagePath = 'web_buffer';
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/studio_v2_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(_processedImageBytes!);
      _processedImagePath = file.path;
      notifyListeners();
    } catch (e) {
      // Silently skip caching on unsupported platforms
      debugPrint('Cache skipped: $e');
    }
  }

  void clear() {
    _originalImageBytes = null;
    _clearProcessedState();
    notifyListeners();
  }
}

// ─── Isolate operations ───

Future<Uint8List?> _readFileAndShrink(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    return _toSafeJpeg(bytes);
  } catch (_) { return null; }
}

Uint8List? _toSafeJpeg(Uint8List bytes) {
  try {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final rgb = img.copyResize(image, width: image.width.clamp(1, 1080), interpolation: img.Interpolation.linear);
    return Uint8List.fromList(img.encodeJpg(rgb, quality: 92));
  } catch (_) { return null; }
}

Future<Uint8List?> _processImageTask(Map<String, dynamic> params) async {
  final Uint8List bytes = params['bytes'];
  final PassportStandard standard = params['standard'];
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  final resized = img.copyResize(image, width: image.width.clamp(1, 1080), interpolation: img.Interpolation.linear);
  final targetAspect = standard.widthMm / standard.heightMm;
  final w = resized.width;
  final h = resized.height;
  final currentAspect = w / h;
  img.Image cropped;
  if (currentAspect > targetAspect) {
    final newW = (h * targetAspect).toInt();
    cropped = img.copyCrop(resized, x: (w - newW) ~/ 2, y: 0, width: newW, height: h);
  } else {
    final newH = (w / targetAspect).toInt();
    cropped = img.copyCrop(resized, x: 0, y: (h - newH) ~/ 2, width: w, height: newH);
  }
  return Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
}

Future<Uint8List?> _fillWhiteAndToJpeg(Uint8List bytes) async {
  final foreground = img.decodeImage(bytes);
  if (foreground == null) return null;
  final canvas = img.Image(width: foreground.width, height: foreground.height, numChannels: 3)..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(canvas, foreground);
  return Uint8List.fromList(img.encodeJpg(canvas, quality: 92));
}
