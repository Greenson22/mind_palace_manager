// lib/features/world/presentation/dialogs/ai_world_map_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AiWorldMapPromptDialog extends StatefulWidget {
  const AiWorldMapPromptDialog({super.key});

  @override
  State<AiWorldMapPromptDialog> createState() => _AiWorldMapPromptDialogState();
}

class _AiWorldMapPromptDialogState extends State<AiWorldMapPromptDialog> {
  // --- 1. Input Controller (Parameter) ---

  // Kolom 1: Tipe Dunia (Menggantikan "low-poly ocean")
  final TextEditingController _worldTypeCtrl = TextEditingController(
    text: "low-poly ocean",
  );

  // Kolom 2: Tekstur Permukaan/Warna (Menggantikan "fine mesh of blue polygons")
  final TextEditingController _textureCtrl = TextEditingController(
    text: "fine mesh of blue polygons",
  );

  // Kolom 3: Objek Tersebar (Menggantikan "circular icons representing islands")
  final TextEditingController _featureCtrl = TextEditingController(
    text: "circular icons representing islands",
  );

  String _generatedPrompt = "";

  @override
  void initState() {
    super.initState();
    _generatePrompt();
  }

  @override
  void dispose() {
    _worldTypeCtrl.dispose();
    _textureCtrl.dispose();
    _featureCtrl.dispose();
    super.dispose();
  }

  // --- 2. Logika Penyusunan Prompt (Template World Map) ---
  void _generatePrompt() {
    setState(() {
      _generatedPrompt =
          "Extreme high-altitude aerial shot of a ${_worldTypeCtrl.text} world. "
          "The viewpoint is so high that the water/surface texture looks like a ${_textureCtrl.text}. "
          "The ocean/landscape feels massive and overwhelming in scale. "
          "Tiny, insignificant ${_featureCtrl.text} are scattered far apart on the vast surface. "
          "No text labels. The horizon is very distant and slightly curved, emphasizing the planet's scale. "
          "Clouds appear as small wisps floating high above the surface.";
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPrompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Prompt Dunia disalin! Paste ke Midjourney/Dall-E."),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color containerBg = isDark
        ? Colors.grey.shade900
        : Colors.grey.shade100;
    final Color containerBorder = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
    final Color previewTextColor = isDark
        ? Colors.grey.shade300
        : Colors.grey.shade800;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.public, color: Colors.blue), // Ikon Bola Dunia
          SizedBox(width: 8),
          Text("AI World Prompt"),
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
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: const Text(
                  "Generator ini dirancang untuk membuat peta skala PLANET/SAMUDRA luas (High Altitude).",
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),

              // --- INPUT 1: TIPE DUNIA ---
              TextField(
                controller: _worldTypeCtrl,
                decoration: const InputDecoration(
                  labelText: "Tipe Dunia (World Style)",
                  hintText: "Cth: vast desert / cyberpunk ocean",
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: "Menggantikan 'low-poly ocean'",
                ),
                onChanged: (_) => _generatePrompt(),
              ),
              const SizedBox(height: 16),

              // --- INPUT 2: TEKSTUR ---
              TextField(
                controller: _textureCtrl,
                decoration: const InputDecoration(
                  labelText: "Tekstur & Warna Permukaan",
                  hintText: "Cth: shifting golden sands / dark digital grid",
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText: "Menggantikan 'fine mesh of blue polygons'",
                ),
                onChanged: (_) => _generatePrompt(),
              ),
              const SizedBox(height: 16),

              // --- INPUT 3: FITUR TERSEBAR ---
              TextField(
                controller: _featureCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Objek Kecil Tersebar (Islands)",
                  hintText: "Cth: glowing neon cities / rocky oasis dots",
                  border: OutlineInputBorder(),
                  isDense: true,
                  helperText:
                      "Menggantikan 'circular icons representing islands'",
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

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: containerBorder),
                ),
                child: SelectableText(
                  _generatedPrompt,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                    color: previewTextColor,
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
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: _copyToClipboard,
        ),
      ],
    );
  }
}
