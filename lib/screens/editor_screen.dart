import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../core/crypto_service.dart';
import '../providers/passport_provider.dart';
import '../providers/auth_provider.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PassportProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Studio'),
        actions: [
          IconButton(
            onPressed: provider.clear,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Project',
          ),
        ],
      ),
      body: _buildBody(context, provider, authProvider, theme),
    );
  }

  Widget _buildBody(BuildContext context, PassportProvider provider, AuthProvider auth, ThemeData theme) {
    if (provider.isProcessing) return const Center(child: CircularProgressIndicator());
    
    if (provider.processedImageBytes == null || provider.processedImagePath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text("Studio requires a valid photo."),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => provider.applyStandard(),
              child: const Text("Initialize Studio"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 1. Studio Preview Area
        Expanded(
          child: Center(
            child: _buildPreviewDisplay(provider, theme),
          ),
        ),
        
        // 2. Control Panel
        _buildControlPanel(context, provider, auth, theme),
      ],
    );
  }

  Widget _buildPreviewDisplay(PassportProvider provider, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 40, spreadRadius: -10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.memory(
              provider.processedImageBytes!,
              key: ValueKey(provider.processedImageBytes.hashCode),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_rounded, size: 50, color: Colors.white24)),
            ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, PassportProvider provider, AuthProvider auth, ThemeData theme) {
    final emerald = theme.primaryColor;
    final std = provider.selectedStandard!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Background Eraser Tool
          _buildActionButton(
            label: 'Auto AI Background',
            subtitle: 'Apply Studio White background',
            icon: Icons.auto_fix_high_rounded,
            color: emerald,
            onPressed: () async {
              final err = await provider.removeBackground();
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              }
            },
          ),
          
          const SizedBox(height: 20),
          
          // Passport Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: emerald, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('${std.name} (${std.widthMm}x${std.heightMm}mm)', style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('300 DPI Ready', style: TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Export Options
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generatePdf(context, provider),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('PDF Print'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadImage(context, provider, 'jpg'),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('JPEG'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadImage(context, provider, 'png'),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('PNG'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white10, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Action: Save to Cloud
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _uploadAndSave(context, provider),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Sync to History'),
              style: ElevatedButton.styleFrom(backgroundColor: emerald, foregroundColor: Colors.black, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required String label, required String subtitle, required IconData icon, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context, PassportProvider provider, String format) async {
    try {
      if (provider.processedImageBytes == null || provider.selectedStandard == null) return;
      
      final std = provider.selectedStandard!;
      if (context.mounted && !kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generating A4 Grid as ${format.toUpperCase()}...')));
      }

      // Generate A4 rasterized Grid
      Uint8List bytes = await compute((Map<String, dynamic> args) {
        final rawBytes = args['bytes'] as Uint8List;
        final wMm = args['wMm'] as double;
        final hMm = args['hMm'] as double;
        final formatOut = args['format'] as String;
        
        final photo = img.decodeImage(rawBytes);
        if (photo == null) return rawBytes;

        // A4 at 300 DPI
        const int a4Width = 2480;
        const int a4Height = 3508;
        const double ppMm = 300 / 25.4;
        
        final int photoWidth = (wMm * ppMm).round();
        final int photoHeight = (hMm * ppMm).round();
        
        final resizedPhoto = img.copyResize(photo, width: photoWidth, height: photoHeight, interpolation: img.Interpolation.linear);
        final canvas = img.Image(width: a4Width, height: a4Height, numChannels: 3)..clear(img.ColorRgb8(255, 255, 255));
        
        const int cols = 2;
        const int rows = 4;
        final int spacing = (12 * ppMm).round();
        
        final int startX = (a4Width - (cols * photoWidth + (cols - 1) * spacing)) ~/ 2;
        final int startY = (a4Height - (rows * photoHeight + (rows - 1) * spacing)) ~/ 2;
        
        for (int r = 0; r < rows; r++) {
          for (int c = 0; c < cols; c++) {
            int x = startX + c * (photoWidth + spacing);
            int y = startY + r * (photoHeight + spacing);
            img.compositeImage(canvas, resizedPhoto, dstX: x, dstY: y);
            img.drawRect(canvas, x1: x, y1: y, x2: x + photoWidth, y2: y + photoHeight, color: img.ColorRgb8(200, 200, 200), thickness: 2);
          }
        }

        if (formatOut == 'png') {
          return Uint8List.fromList(img.encodePng(canvas));
        } else {
          return Uint8List.fromList(img.encodeJpg(canvas, quality: 92));
        }
      }, {
        'bytes': provider.processedImageBytes!,
        'wMm': std.widthMm,
        'hMm': std.heightMm,
        'format': format.toLowerCase()
      });

      if (kIsWeb) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('To save: Right-click the photo and select "Save Image As..."'),
            duration: Duration(seconds: 4),
          ));
        }
        return;
      }

      // Safe Mobile/Desktop execution (Not Web)
      String targetPath = '';
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          targetPath = directory.path;
        } else {
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) targetPath = extDir.path;
        }
      } else {
        // iOS or other platforms
        final docDir = await getApplicationDocumentsDirectory();
        targetPath = docDir.path;
      }

      if (targetPath.isNotEmpty) {
        final file = File('$targetPath/passport_studio_export_${DateTime.now().millisecondsSinceEpoch}.$format');
        await file.writeAsBytes(bytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Saved locally: ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ));
        }
      } else {
        throw Exception("Could not find suitable directory to save file.");
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _uploadAndSave(BuildContext context, PassportProvider provider) async {
    try {
      final fileName = 'studio_photo_${DateTime.now().millisecondsSinceEpoch}.bin';
      final path = 'public/$fileName';
      
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final encryptedBytes = await CryptoService.encryptImage(provider.processedImageBytes!, userId);

      await Supabase.instance.client.storage.from('photos').uploadBinary(path, encryptedBytes, fileOptions: const FileOptions(contentType: 'application/octet-stream'));
      final publicUrl = Supabase.instance.client.storage.from('photos').getPublicUrl(path);
      
      await provider.addToHistory(publicUrl, provider.selectedStandard!.name);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Studio Project Saved securely to Cloud')));
    } catch (e) {
       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
    }
  }

  Future<void> _generatePdf(BuildContext context, PassportProvider provider) async {
    try {
      if (provider.processedImageBytes == null) throw Exception("Photo not processed yet.");
      
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.outfitRegular();
      final image = pw.MemoryImage(provider.processedImageBytes!);
      final std = provider.selectedStandard!;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ─── PHOTO GRID ───
                pw.Wrap(
                  spacing: 12, runSpacing: 12,
                  children: List.generate(8, (i) => pw.Container(
                    width: std.widthMm * PdfPageFormat.mm,
                    height: std.heightMm * PdfPageFormat.mm,
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.2)),
                    child: pw.Image(image),
                  )),
                ),

                pw.Spacer(), // Push content to bottom

                // ─── FOOTER DETAILS ───
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 10),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 1)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('STUDIO EXPORT DETAILS', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, letterSpacing: 1.2)),
                          pw.SizedBox(height: 4),
                          pw.Text('Standard: ${std.name}', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                          pw.Text('Dimensions: ${std.widthMm}mm x ${std.heightMm}mm', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                           pw.Text('Generated by', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                           pw.Text('Emerald Studio', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                           pw.Text('Professional AI ID Solutions', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Studio Error: $e')));
    }
  }
}
