// lib/features/world/presentation/dialogs/ai_map_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiMapPromptDialog extends StatefulWidget {
  const AiMapPromptDialog({super.key});

  @override
  State<AiMapPromptDialog> createState() => _AiMapPromptDialogState();
}

class _AiMapPromptDialogState extends State<AiMapPromptDialog> {
  // --- 1. Input Controller (Parameter yang bisa diubah) ---

  // Kolom Bentuk (Shape)
  final TextEditingController _shapeCtrl = TextEditingController(
    text:
        "massive, sprawling continent-sized island", // Default dari prompt Anda
  );

  // Kolom Tema (Theme/Landmass Description)
  final TextEditingController _themeCtrl = TextEditingController(
    text: "huge and complex", // Default
  );

  // Kolom Detail Penting (Features)
  final TextEditingController _detailsCtrl = TextEditingController(
    text:
        "extensive mountain ranges with topological contour lines, multiple long winding river systems", // Default
  );

  String _generatedPrompt = "";

  @override
  void initState() {
    super.initState();
    _generatePrompt(); // Generate awal saat dibuka
  }

  @override
  void dispose() {
    _shapeCtrl.dispose();
    _themeCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  // --- 2. Logika Penyusunan Prompt ---
  void _generatePrompt() {
    setState(() {
      // Template Prompt sesuai permintaan Anda
      _generatedPrompt =
          "Direct top-down aerial map view of a ${_shapeCtrl.text} dominating the entire frame. "
          "The landmass is ${_themeCtrl.text}, featuring ${_detailsCtrl.text} cutting across vast dense green forests and wide plains. "
          "The entire coastline is bordered by a continuous sandy beige beach with a thick, prominent white wave foam border against the deep blue ocean background. "
          "The style is a 2D hand-painted game asset, with smooth digital textures, soft even lighting, vibrant earthy colors, and miniature-scale trees scattered across the vast landscape to emphasize the immense scale. "
          "No clouds, clean edges, high resolution. --no isometric view, tilted angle, 3d render, low poly, realism, photorealistic, perspective distortion, blurry, grainy, simple geography, small island, dark shadows";
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPrompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Prompt lengkap disalin! Paste ke Midjourney/Dall-E."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warna tema (Ungu untuk AI)
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.psychology, color: Colors.purple),
          SizedBox(width: 8),
          Text("AI Map Prompt Gen"),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade100),
                ),
                child: const Text(
                  "Isi parameter di bawah ini. Prompt panjang akan otomatis disusun sesuai template Anda.",
                  style: TextStyle(fontSize: 12, color: Colors.purple),
                ),
              ),
              const SizedBox(height: 16),

              // --- INPUT 1: BENTUK (SHAPE) ---
              TextField(
                controller: _shapeCtrl,
                decoration: const InputDecoration(
                  labelText: "Bentuk Wilayah (Shape)",
                  hintText: "Cth: massive continent / ring island",
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText:
                      "Menggantikan 'massive, sprawling continent-sized island'",
                ),
                onChanged: (_) => _generatePrompt(),
              ),
              const SizedBox(height: 16),

              // --- INPUT 2: TEMA (THEME) ---
              TextField(
                controller: _themeCtrl,
                decoration: const InputDecoration(
                  labelText: "Tema / Kondisi Daratan",
                  hintText: "Cth: volcanic and jagged / frozen and flat",
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: "Menggantikan 'huge and complex'",
                ),
                onChanged: (_) => _generatePrompt(),
              ),
              const SizedBox(height: 16),

              // --- INPUT 3: DETAIL (FEATURES) ---
              TextField(
                controller: _detailsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Detail Fitur Geografis",
                  hintText:
                      "Cth: giant crater lakes, golden rivers, crystal mountains",
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText:
                      "Akan disambung dengan 'cutting across vast dense green forests...'",
                ),
                onChanged: (_) => _generatePrompt(),
              ),

              const Divider(height: 32),

              const Row(
                children: [
                  Icon(
                    Icons.text_snippet_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Preview Prompt Final:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // --- PREVIEW BOX ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  _generatedPrompt,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Tutup"),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text("Salin Prompt"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          onPressed: _copyToClipboard,
        ),
      ],
    );
  }
}
