import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
    
    // Initial user check
    _user = _supabase.auth.currentUser;
  }

  Future<String?> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      
      _setLoading(false);
      return res.user == null ? "Registration failed" : null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return e.toString();
    }
  }

  Future<void> loginWithProvider(OAuthProvider provider) async {
    await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : 'io.supabase.passportphoto://login-callback/',
    );
  }

  Future<String?> uploadPhoto(Uint8List bytes, String filename) async {
    if (_user == null) return "Not logged in";
    
    try {
      // Bucket name: photos (Must create this bucket in Supabase)
      final String path = '${_user!.id}/$filename';
      await _supabase.storage.from('photos').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      return _supabase.storage.from('photos').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
