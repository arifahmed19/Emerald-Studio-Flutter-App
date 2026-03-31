import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../providers/passport_provider.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PassportProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust & Export'),
        actions: [
          if (provider.processedImageBytes != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => _handleExport(context, provider),
            ),
        ],
      ),
      body: provider.isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('Processing Image...', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : provider.processedImageBytes == null
              ? const Center(child: Text('No image selected'))
              : Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _buildPreview(context, provider),
                            const SizedBox(height: 32),
                            _buildStandardInfo(context, provider),
                            const SizedBox(height: 48), // Replaced spacer with consistent padding
                            _buildExportButtons(context, provider),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildPreview(BuildContext context, PassportProvider provider) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white, // Standard passport backgrounds are usually white/off-white
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          provider.processedImageBytes!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildStandardInfo(BuildContext context, PassportProvider provider) {
    final std = provider.selectedStandard!;
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Format', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  Text(std.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const Divider(height: 32, color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dimensions', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                  Text('${std.widthMm} x ${std.heightMm} mm', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
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

  Widget _buildExportButtons(BuildContext context, PassportProvider provider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () => _printTemplate(context, provider),
            icon: const Icon(Icons.print_rounded),
            label: const Text('Generate Printable Template (A4)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            onPressed: () => _handleExport(context, provider, format: 'jpeg'),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Single JPEG'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleExport(BuildContext context, PassportProvider provider, {String format = 'pdf'}) async {
    // Basic download/share logic
    if (format == 'jpeg') {
       await Printing.sharePdf(
        bytes: provider.processedImageBytes!,
        filename: 'passport_photo.jpg',
      );
    } else {
      _printTemplate(context, provider);
    }
  }

  Future<void> _printTemplate(BuildContext context, PassportProvider provider) async {
    final pdf = pw.Document();
    final std = provider.selectedStandard!;
    final image = pw.MemoryImage(provider.processedImageBytes!);

    // A4 dimensions in points (1mm = 2.83465 points)
    const mmToPt = 2.83465;
    final photoWidth = std.widthMm * mmToPt;
    final photoHeight = std.heightMm * mmToPt;
    const spacing = 5 * mmToPt;
    const margin = 10 * mmToPt;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(margin),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Passport Photo Studio - ${std.name}', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: List.generate(8, (index) {
                  return pw.Container(
                    width: photoWidth,
                    height: photoHeight,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Image(image, fit: pw.BoxFit.cover),
                  );
                }),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Guidelines: Cut along the grey lines. Ensure no shadows are cast on the surface.', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'passport_template_${std.country.toLowerCase()}.pdf',
    );
  }
}
