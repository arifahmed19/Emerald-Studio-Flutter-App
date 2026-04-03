import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/crypto_service.dart';
import '../providers/passport_provider.dart';
import '../models/history_item.dart';
import 'editor_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleRefresh(
    BuildContext context,
    PassportProvider provider,
  ) async {
    await Future.wait([provider.fetchHistory(), provider.fetchStandards()]);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Studio Sync Complete'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final passportProvider = Provider.of<PassportProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Logic
          _buildBackground(theme),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                _buildSliverHeader(context, theme, passportProvider),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildQuickStartCard(context, passportProvider),
                        const SizedBox(height: 40),
                        _buildSectionHeader(
                          'Standard Templates',
                          'Create for any country',
                        ),
                        const SizedBox(height: 16),
                        _buildStandardGrid(context, passportProvider, theme),
                        const SizedBox(height: 40),
                        _buildSectionHeader(
                          'Recent History',
                          'Re-edit your past designs',
                          onAction: passportProvider.historyItems.isNotEmpty
                              ? () => _showClearAllConfirm(
                                  context,
                                  passportProvider,
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                _buildHistorySliverList(context, passportProvider, theme),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          _buildFloatingNavBar(context, theme, size),
        ],
      ),
    );
  }

  Widget _buildBackground(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF091413)),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF285A48).withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF408A71).withOpacity(0.15),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(
    BuildContext context,
    ThemeData theme,
    PassportProvider provider,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to',
                  style: GoogleFonts.outfit(
                    color: Colors.white60,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Emerald Studio',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () => _handleRefresh(context, provider),
                  icon: const Icon(Icons.sync_rounded, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context, PassportProvider provider) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create New Photo',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.pickImage(ImageSource.camera);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: Colors.white.withOpacity(0.05),
                    leading: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFFB0E4CC),
                    ),
                    title: const Text(
                      'Take Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      provider.pickImage(ImageSource.gallery);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: Colors.white.withOpacity(0.05),
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFFB0E4CC),
                    ),
                    title: const Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF285A48).withOpacity(0.15),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFF408A71).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF408A71).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: Color(0xFFB0E4CC),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create New',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap here to take a picture or import one from your gallery to get started.',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF408A71).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle, {
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white30),
            ),
          ],
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              'Clear All',
              style: GoogleFonts.outfit(
                color: const Color(0xFF408A71),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStandardGrid(
    BuildContext context,
    PassportProvider provider,
    ThemeData theme,
  ) {
    if (provider.isLoadingStandards && provider.availableStandards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final standards = provider.availableStandards;
    final width = MediaQuery.of(context).size.width;

    // Calculate responsive column count
    int crossAxisCount = 2;
    if (width > 1200) {
      crossAxisCount = 5;
    } else if (width > 900) {
      crossAxisCount = 4;
    } else if (width > 600) {
      crossAxisCount = 3;
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: standards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final std = standards[index];
        final isSelected = provider.selectedStandard?.name == std.name;
        return AnimationConfiguration.staggeredGrid(
          position: index,
          columnCount: crossAxisCount,
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: GestureDetector(
                onTap: () => provider.setStandard(std),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF408A71).withOpacity(0.2)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF408A71).withOpacity(0.5)
                          : Colors.white10,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(std.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        std.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${std.widthMm}x${std.heightMm}mm',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isSelected
                              ? const Color(0xFFB0E4CC)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistorySliverList(
    BuildContext context,
    PassportProvider provider,
    ThemeData theme,
  ) {
    if (provider.historyItems.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'No projects yet.',
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = provider.historyItems[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHistoryCard(context, item, provider, theme),
          );
        }, childCount: provider.historyItems.length),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryItem item,
    PassportProvider provider,
    ThemeData theme,
  ) {
    return GestureDetector(
      onTap: () async {
        try {
          final userId = Supabase.instance.client.auth.currentUser!.id;
          final decryptedBytes = await CryptoService.fetchAndDecrypt(item.imageUrl, userId);
          if (decryptedBytes != null) {
            await provider.loadFromHistory(decryptedBytes, item.standardName);
            if (context.mounted)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditorScreen()),
              );
          }
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FutureBuilder<Uint8List?>(
                future: CryptoService.fetchAndDecrypt(item.imageUrl, Supabase.instance.client.auth.currentUser!.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(width: 48, height: 48, color: Colors.white10, child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))));
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(snapshot.data!, width: 48, height: 48, fit: BoxFit.cover);
                  }
                  return Container(
                    width: 48, height: 48,
                    color: Colors.white10,
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: Colors.white24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.standardName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Processed for Cloud History',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => provider.deleteHistoryItem(item.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white24,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  void _showClearAllConfirm(BuildContext context, PassportProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Clear History?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will permanently delete all your previous projects from the cloud.',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllHistory();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete All',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavBar(
    BuildContext context,
    ThemeData theme,
    Size size,
  ) {
    final provider = Provider.of<PassportProvider>(context);
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF285A48).withOpacity(0.4),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavIcon(
                  Icons.camera_alt_rounded,
                  'Camera',
                  () => provider.pickImage(ImageSource.camera),
                ),
                _buildNavIcon(
                  Icons.photo_library_rounded,
                  'Gallery',
                  () => provider.pickImage(ImageSource.gallery),
                ),
                if (provider.originalImageBytes != null)
                  _buildNavIcon(
                    Icons.edit_note_rounded,
                    'Editor',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditorScreen()),
                    ),
                    isPrimary: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 90,
        decoration: isPrimary
            ? BoxDecoration(
                color: const Color(0xFF408A71),
                borderRadius: BorderRadius.circular(30),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : Colors.white70,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
