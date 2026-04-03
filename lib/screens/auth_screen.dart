import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    String? error;

    if (_isLogin) {
      error = await auth.login(_emailController.text, _passwordController.text);
    } else {
      error = await auth.register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLogin ? 'Welcome Back' : 'Create Account',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premium Emerald Studio',
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                            ),
                            const SizedBox(height: 32),
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration('Full Name', Icons.person_outline),
                                validator: (v) => v!.isEmpty ? 'Enter name' : null,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: _inputDecoration('Email Address', Icons.email_outlined),
                              validator: (v) => v!.isEmpty ? 'Enter email' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: _inputDecoration('Password', Icons.lock_outline),
                              validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                            ),
                            const SizedBox(height: 32),
                            
                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _submit,
                                child: authProvider.isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            _buildSocialLoginSection(context, authProvider),
                            const SizedBox(height: 24),
                            
                            TextButton(
                              onPressed: () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin ? "Don't have an account? Register Now" : "Already have an account? Login",
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('OR CONTINUE WITH', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, letterSpacing: 1.2)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(context, Icons.g_mobiledata_rounded, OAuthProvider.google, auth),
            const SizedBox(width: 20),
            _socialIcon(context, Icons.facebook_rounded, OAuthProvider.facebook, auth),
            const SizedBox(width: 20),
            _socialIcon(context, Icons.alternate_email_rounded, OAuthProvider.twitter, auth),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(BuildContext context, IconData icon, OAuthProvider provider, AuthProvider auth) {
    return InkWell(
      onTap: () => auth.loginWithProvider(provider),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          color: Colors.white.withOpacity(0.03),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 28),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
