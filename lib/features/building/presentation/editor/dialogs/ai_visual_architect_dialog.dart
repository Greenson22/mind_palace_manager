// lib/features/building/presentation/editor/dialogs/ai_visual_architect_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class AiVisualArchitectDialog extends StatefulWidget {
  final Directory buildingDirectory;
  const AiVisualArchitectDialog({super.key, required this.buildingDirectory});

  @override
  State<AiVisualArchitectDialog> createState() =>
      _AiVisualArchitectDialogState();
}

class _AiVisualArchitectDialogState extends State<AiVisualArchitectDialog> {
  // Controller
  final _promptThemeCtrl = TextEditingController();
  final _promptLightCtrl = TextEditingController();
  final _promptDoorCtrl = TextEditingController();
  final _aiResultCtrl = TextEditingController();

  double _promptLociCount = 5.0;
  String _generatedInstruction = "";

  @override
  void dispose() {
    _promptThemeCtrl.dispose();
    _promptLightCtrl.dispose();
    _promptDoorCtrl.dispose();
    _aiResultCtrl.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _runPromptGeneration() {
    final theme = _promptThemeCtrl.text.isEmpty
        ? "[TEMA]"
        : _promptThemeCtrl.text;
    final light = _promptLightCtrl.text.isEmpty
        ? "[CAHAYA]"
        : _promptLightCtrl.text;
    final door = _promptDoorCtrl.text.isEmpty
        ? "[PINTU]"
        : _promptDoorCtrl.text;
    final loci = _promptLociCount.toInt();

    // Template (Disederhanakan untuk file ini)
    setState(() {
      _generatedInstruction =
          """
SYSTEM ROLE: MASTER VISUAL ARCHITECT
Tugas: Rancang aset visual Mind Palace.

PARAMETER:
- TEMA: $theme
- CAHAYA: $light
- PINTU: $door
- LOCI: $loci

OUTPUT:
Berikan prompt Midjourney/DALL-E yang detail untuk ruangan Isometric View, 
termasuk tekstur dinding, lantai, dan objek Loci.
""";
    });
  }

  Future<void> _saveResultToHistory() async {
    if (_aiResultCtrl.text.trim().isEmpty) return;

    try {
      final file = File(
        p.join(widget.buildingDirectory.path, 'prompts_history.txt'),
      );
      final timestamp = DateTime.now().toString();
      final entry = "\n\n=== [SAVED: $timestamp] ===\n${_aiResultCtrl.text}\n";

      await file.writeAsString(entry, mode: FileMode.append);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Prompt disimpan ke Riwayat"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving history: $e");
    }
  }

  void _showHistoryViewer() {
    final file = File(
      p.join(widget.buildingDirectory.path, 'prompts_history.txt'),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Riwayat Prompt"),
        content: FutureBuilder<String>(
          future: file.existsSync()
              ? file.readAsString()
              : Future.value("Belum ada riwayat."),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  snapshot.data!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text(
              "Hapus Semua",
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              if (await file.exists()) await file.delete();
              if (context.mounted) Navigator.pop(ctx);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    // --- DETEKSI TEMA (DARK/LIGHT) ---
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna Adaptif untuk Bagian Ungu (Generator)
    final purpleContainer = isDark
        ? Colors.purple.shade900.withOpacity(0.3)
        : Colors.purple.shade50;
    final purpleBorder = isDark
        ? Colors.purple.shade700
        : Colors.purple.shade100;
    final purpleTitle = isDark ? Colors.purple.shade200 : Colors.purple;

    // Warna Adaptif untuk Bagian Hijau (Simpan)
    final greenContainer = isDark
        ? Colors.green.shade900.withOpacity(0.3)
        : Colors.green.shade50;
    final greenBorder = isDark ? Colors.green.shade700 : Colors.green.shade100;
    final greenTitle = isDark ? Colors.green.shade200 : Colors.green;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple),
              SizedBox(width: 8),
              Text("AI Architect"),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Lihat Riwayat",
            onPressed: _showHistoryViewer,
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Section 1: Generate
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: purpleContainer, // Gunakan warna adaptif
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: purpleBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. Generator Instruksi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: purpleTitle, // Gunakan warna adaptif
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptThemeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Tema",
                        isDense: true,
                      ),
                    ),
                    TextField(
                      controller: _promptLightCtrl,
                      decoration: const InputDecoration(
                        labelText: "Pencahayaan",
                        isDense: true,
                      ),
                    ),
                    TextField(
                      controller: _promptDoorCtrl,
                      decoration: const InputDecoration(
                        labelText: "Gaya Pintu",
                        isDense: true,
                      ),
                    ),
                    Row(
                      children: [
                        const Text("Loci: "),
                        Expanded(
                          child: Slider(
                            value: _promptLociCount,
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: "${_promptLociCount.toInt()}",
                            onChanged: (v) =>
                                setState(() => _promptLociCount = v),
                          ),
                        ),
                        Text("${_promptLociCount.toInt()}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text("Generate & Salin"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
                        // Tombol tetap ungu solid agar kontras
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _runPromptGeneration();
                        Clipboard.setData(
                          ClipboardData(text: _generatedInstruction),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Instruksi disalin! Paste ke AI."),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Section 2: Save
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: greenContainer, // Gunakan warna adaptif
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: greenBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "2. Simpan Hasil",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: greenTitle, // Gunakan warna adaptif
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aiResultCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        hintText: "Paste hasil dari AI di sini...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan ke Arsip"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      onPressed: _saveResultToHistory,
                    ),
                  ],
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
      ],
    );
  }
}
