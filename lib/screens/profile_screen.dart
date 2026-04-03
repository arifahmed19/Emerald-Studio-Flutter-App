import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/passport_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'intro_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<PassportProvider>(context, listen: false);
    _apiKeyController = TextEditingController(text: provider.customApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final passportProvider = Provider.of<PassportProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.05),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.email ?? 'Developer',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 40),
                    
                    // NEW: Settings Section
                    _buildSettingsCard(context, passportProvider),
                    const SizedBox(height: 16),

                    // About section
                    _buildGlassCard(
                      context,
                      title: 'About The Project',
                      content: 'Emerald Studio is an automated studio-grade application for creating official photos. Built with Flutter, Supabase, and a custom Glassmorphism UI.\n\nDeveloped with ❤️ by Arif Ahmed.',
                      icon: Icons.info_outline_rounded,
                      action: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: '1210563042')).then((_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Binance UID copied to clipboard!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
                            label: const Text('Support via Binance (UID: 1210563042)'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF3BA2F), // Binance Yellow
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const IntroScreen(isFromAbout: true)),
                              );
                            },
                            icon: const Icon(Icons.slideshow_rounded, size: 16),
                            label: const Text('View App Intro'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          authProvider.logout();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, PassportProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings_rounded, size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  const Text('Studio Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Remove.bg API Key', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _apiKeyController,
                onChanged: (val) => provider.setCustomApiKey(val),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Paste your API key here',
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Get a free key from remove.bg to enable Magic Erase if credits are low.',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse('https://www.remove.bg/dashboard#api-key')),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text('Get Key', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required String title, required String content, required IconData icon, Widget? action}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5),
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
