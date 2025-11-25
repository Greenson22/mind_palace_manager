// lib/features/building/presentation/editor/dialogs/ai_visual_architect_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_markdown/flutter_markdown.dart'; // Pastikan package ini ada

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

  // Menggunakan RangeValues untuk Loci (Min - Max)
  RangeValues _promptLociRange = const RangeValues(5, 10);
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
    // Logika: Jika kosong, biarkan AI yang menentukan
    final theme = _promptThemeCtrl.text.trim().isEmpty
        ? "BEBAS (Tentukan sendiri tema yang paling atmosferik dan koheren)"
        : _promptThemeCtrl.text;

    final light = _promptLightCtrl.text.trim().isEmpty
        ? "BEBAS (Tentukan pencahayaan dramatis yang mendukung mood)"
        : _promptLightCtrl.text;

    final door = _promptDoorCtrl.text.trim().isEmpty
        ? "BEBAS (Sesuaikan gaya pintu dengan Tema Utama)"
        : _promptDoorCtrl.text;

    // Format rentang loci (misal: "5-10")
    final lociString =
        "${_promptLociRange.start.round()} - ${_promptLociRange.end.round()}";

    setState(() {
      _generatedInstruction =
          """
SYSTEM ROLE: MASTER VISUAL ARCHITECT (MIND PALACE)
Bertindaklah sebagai Arsitek Visual Elit dan Desainer Level Game dengan spesialisasi High-Fidelity Isometric Environments. Tugas Anda adalah merancang aset visual 'Mind Palace' yang sangat mendetail, tekstural, dan logis untuk produksi game.

BAGIAN 0: LOGIKA PERENCANAAN & ALUR (Wajib Output Pertama)
Sebelum membuat prompt gambar, Anda WAJIB menyusun Rencana Alur berdasarkan aturan ini:
Aturan Hitungan: Koridor TIDAK mengurangi kuota ruangan.
Logika "Smart Corridor":
JANGAN gunakan koridor jika ruangan bersebelahan memiliki fungsi/suasana serupa. (Contoh: Ruang Tamu -> Ruang Makan = Sambung Langsung).
GUNAKAN koridor HANYA untuk perubahan drastis (Contoh: Dapur yang panas -> Gudang Dingin) atau jarak jauh.
Loci Placement: Tentukan area spesifik di dalam ruangan untuk penempatan Loci sesuai jumlah yang diminta.

PARAMETER GLOBAL (Wajib Diisi User):
TEMA UTAMA: $theme
WAKTU & PENCAHAYAAN: $light
GAYA PINTU MASTER: $door
JUMLAH LOCI PER RUANGAN: $lociString Loci (Pilih acak dalam rentang ini).

BAGIAN 1: ATURAN DESAIN INTERIOR (ULTRA-DETAIL)
Untuk mencapai detail maksimal pada Dinding, Lantai, dan Pintu, gunakan "Layered Description Technique" dalam prompt:
A. DINDING (Wall Layers): Jangan hanya menyebut "Dinding Batu". Deskripsikan:
Base Material: (Batu bata, Panel Kayu, Beton).
Secondary Detail: (Wallpaper terkelupas, Cat retak, Lumut di sela-sela, Kabel terekspos).
Trim/Structure: (Baseboard/Lis bawah, Molding atap, Kolom penguat).
B. LANTAI (Floor Layers): Jangan hanya menyebut "Lantai Kayu". Deskripsikan:
Pattern: (Herringbone, Ubin Catur, Papan Acak).
Texture/Finish: (Highly polished, Matte dusty, Wet reflection).
Imperfections: (Goresan furnitur, Noda air, Ubin retak, Debu di sudut).
C. PINTU (The Anchor): Harus menyatu dengan dinding. Deskripsikan Daun Pintu, Bingkai (Frame) yang tebal, Engsel, dan Ambang bawah (Threshold).
D. STRUKTUR VIEW (Isometric Cutaway):
View: Isometric 30-degree orthographic projection.
Front Walls: Invisible/Cutaway (untuk melihat isi).
Background: Full Atmospheric Background (Sesuai Tema) mengisi kanvas di belakang ruangan.

BAGIAN 2: ATURAN EKSTERIOR (CHROMA SAFE)
Satu prompt khusus untuk tampilan luar bangunan.
Composition: "Extreme Long Shot" atau "Zoomed Out". Objek harus berada di tengah dengan Padding/Margin minimal 20% di semua sisi. Bangunan DILARANG TERPOTONG.
Chroma Key: Background Solid Hex Code #00FF00 (Green Screen).
Shadow Logic:
Bangunan wajib memiliki Contact Shadow dan Cast Shadow di tanah.
Warna bayangan: HITAM/ABU TUA (Natural).
PENTING: Bayangan tidak boleh berwarna hijau atau transparan. Harus kontras tajam.

BAGIAN 3: ATURAN MAP 2D
Satu prompt akhir untuk navigasi.
View: Strict 90-degree Top-Down (Plan View). Flat graphic style.
Clarity: Tampilkan jalur jalan kaki (pathway) yang jelas antar kotak ruangan.
Icons: Tandai posisi pintu dengan garis lengkung atau ikon pintu standar arsitektur.

FORMAT OUTPUT RESPON (Strict Formatting)
Ikuti struktur ini. PENTING: Semua PROMPT FINAL Bahasa Inggris harus berada di dalam Markdown Code Block (```) agar mudah disalin.
1. RENCANA ALUR & LOCI
Sequence: Ruang 1 -> [Koneksi] -> Ruang 2 -> dst.
Alasan Koneksi: (Penjelasan singkat).
Distribusi Loci: (Daftar loci per ruangan).
2. PROMPT GENERATION
(Ulangi blok ini untuk setiap aset)
[NAMA ASET: RUANG X / KORIDOR / EKSTERIOR]
Data Teknis: (Posisi Pintu, Arah Cahaya).
Deskripsi Detail (ID): (Ringkasan elemen dinding/lantai dalam Bahasa Indonesia).
PROMPT FINAL:
Plaintext
(Tulis Prompt Bahasa Inggris yang sangat panjang dan detail di sini. Gabungkan deskripsi Pintu + Layer Dinding + Layer Lantai + Loci + Lighting + Render Engine Keywords)
""";
    });
  }

  Future<void> _saveResultToHistory() async {
    if (_aiResultCtrl.text.trim().isEmpty) return;

    try {
      final file = File(
        p.join(widget.buildingDirectory.path, 'prompts_history.txt'),
      );
      final timestamp = DateTime.now().toString().substring(0, 16);
      // Simpan format Markdown di file text
      final entry = "\n\n## [SAVED: $timestamp]\n${_aiResultCtrl.text}\n***\n";

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
        // Menggunakan Container dengan ukuran tetap agar scrollable
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<String>(
            future: file.existsSync()
                ? file.readAsString()
                : Future.value("Belum ada riwayat."),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              // Menggunakan Markdown Widget untuk merender teks
              return Markdown(
                data: snapshot.data!,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  h2: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  code: const TextStyle(
                    backgroundColor: Colors.black12,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final purpleContainer = isDark
        ? Colors.purple.shade900.withOpacity(0.3)
        : Colors.purple.shade50;
    final purpleBorder = isDark
        ? Colors.purple.shade700
        : Colors.purple.shade100;
    final purpleTitle = isDark ? Colors.purple.shade200 : Colors.purple;

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
                  color: purpleContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: purpleBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "1. Generator Instruksi Visual",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: purpleTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptThemeCtrl,
                      decoration: const InputDecoration(
                        labelText: "Tema (Kosongkan = AI Pilih)",
                        hintText: "Cth: Cyberpunk / Victorian",
                        isDense: true,
                      ),
                    ),
                    TextField(
                      controller: _promptLightCtrl,
                      decoration: const InputDecoration(
                        labelText: "Pencahayaan (Kosongkan = AI Pilih)",
                        hintText: "Cth: Neon / Lilin Redup",
                        isDense: true,
                      ),
                    ),
                    TextField(
                      controller: _promptDoorCtrl,
                      decoration: const InputDecoration(
                        labelText: "Gaya Pintu (Kosongkan = AI Pilih)",
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // --- RANGE SLIDER UNTUK LOCI ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Rentang Loci (Acak): "),
                        Text(
                          "${_promptLociRange.start.round()} - ${_promptLociRange.end.round()}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _promptLociRange,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      labels: RangeLabels(
                        _promptLociRange.start.round().toString(),
                        _promptLociRange.end.round().toString(),
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _promptLociRange = values;
                        });
                      },
                    ),

                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text("Generate & Salin"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 36),
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
                            content: Text(
                              "Instruksi disalin! Paste ke ChatGPT/Gemini.",
                            ),
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
                  color: greenContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: greenBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "2. Simpan Prompt Hasil AI",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: greenTitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _aiResultCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        hintText:
                            "Paste prompt bahasa Inggris hasil AI di sini untuk disimpan...",
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
