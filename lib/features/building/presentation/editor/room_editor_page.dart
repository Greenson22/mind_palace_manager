// lib/features/building/presentation/editor/room_editor_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';

class RoomEditorPage extends StatefulWidget {
  final Directory buildingDirectory;

  const RoomEditorPage({super.key, required this.buildingDirectory});

  @override
  State<RoomEditorPage> createState() => _RoomEditorPageState();
}

class _RoomEditorPageState extends State<RoomEditorPage> {
  late File _jsonFile;
  Map<String, dynamic> _buildingData = {'rooms': []};
  bool _isLoading = true;
  bool _isReorderMode = false;
  final TextEditingController _roomNameController = TextEditingController();
  String? _pickedImagePath;

  // --- STATE UNTUK PROMPT GENERATOR ---
  final TextEditingController _promptThemeCtrl = TextEditingController();
  final TextEditingController _promptLightCtrl = TextEditingController();
  final TextEditingController _promptDoorCtrl = TextEditingController();
  final TextEditingController _aiResultCtrl =
      TextEditingController(); // Input Hasil AI
  double _promptLociCount = 5.0;
  String _generatedInstruction = ""; // Prompt Awal (Instruksi)

  List<dynamic> get _rooms => _buildingData['rooms'] as List? ?? [];

  @override
  void initState() {
    super.initState();
    _jsonFile = File(p.join(widget.buildingDirectory.path, 'data.json'));
    _loadData();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _promptThemeCtrl.dispose();
    _promptLightCtrl.dispose();
    _promptDoorCtrl.dispose();
    _aiResultCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      if (!await _jsonFile.exists()) await _saveData();
      final content = await _jsonFile.readAsString();
      setState(() {
        _buildingData = json.decode(content);
        for (var room in _rooms) {
          room['connections'] ??= [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  Future<void> _saveData() async {
    try {
      await _jsonFile.writeAsString(json.encode(_buildingData));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  // ===========================================================================
  // AI VISUAL ARCHITECT & HISTORY LOGIC
  // ===========================================================================

  void _generateAndShowPromptDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.purple),
                      SizedBox(width: 8),
                      Text("AI Visual Architect"),
                    ],
                  ),
                  // TOMBOL HISTORY (RIWAYAT)
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.blueGrey),
                    tooltip: "Lihat Riwayat Prompt Tersimpan",
                    onPressed: () => _showPromptHistoryDialog(),
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
                      // --- LANGKAH 1: GENERATOR ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Langkah 1: Buat Instruksi (Master Prompt)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _promptThemeCtrl,
                              decoration: const InputDecoration(
                                labelText: "Tema Utama",
                                hintText: "Misal: Cyberpunk Noir",
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _promptLightCtrl,
                              decoration: const InputDecoration(
                                labelText: "Pencahayaan",
                                hintText: "Misal: Golden Hour",
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _promptDoorCtrl,
                              decoration: const InputDecoration(
                                labelText: "Gaya Pintu",
                                hintText: "Misal: Kayu Jati",
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text("Loci: "),
                                Expanded(
                                  child: Slider(
                                    value: _promptLociCount,
                                    min: 1,
                                    max: 20,
                                    divisions: 19,
                                    label: _promptLociCount.toInt().toString(),
                                    onChanged: (val) => setDialogState(
                                      () => _promptLociCount = val,
                                    ),
                                  ),
                                ),
                                Text("${_promptLociCount.toInt()}"),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text("Generate & Salin Instruksi"),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              onPressed: () {
                                _runPromptGeneration();
                                Clipboard.setData(
                                  ClipboardData(text: _generatedInstruction),
                                );
                                setDialogState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Instruksi disalin! Tempel ke AI (ChatGPT/Gemini).",
                                    ),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              },
                            ),
                            if (_generatedInstruction.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "Instruksi siap. Silakan paste ke AI Anda.",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Divider(height: 32),

                      // --- LANGKAH 2: SIMPAN HASIL ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Langkah 2: Simpan Hasil dari AI",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Paste prompt gambar yang dihasilkan AI di sini untuk arsip.",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _aiResultCtrl,
                              maxLines: 5,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    "Paste hasil prompt gambar di sini...\nContoh: /imagine prompt: Isometric bedroom view...",
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text("Simpan ke Arsip Bangunan"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              onPressed: () async {
                                if (_aiResultCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Kotak hasil masih kosong.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await _saveResultToFile();
                                if (mounted) Navigator.pop(context);
                              },
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
          },
        );
      },
    );
  }

  void _runPromptGeneration() {
    final String theme = _promptThemeCtrl.text.isEmpty
        ? "[TEMA]"
        : _promptThemeCtrl.text;
    final String light = _promptLightCtrl.text.isEmpty
        ? "[CAHAYA]"
        : _promptLightCtrl.text;
    final String door = _promptDoorCtrl.text.isEmpty
        ? "[PINTU]"
        : _promptDoorCtrl.text;
    final int loci = _promptLociCount.toInt();

    // Template Instruksi Master Architect
    final String template =
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
WAKTU & PENCAHAYAAN: $light (Cahaya konsisten dari Kiri/Kanan Atas).
GAYA PINTU MASTER: $door (Sebutkan: Material, Warna, Detail Handle, dan Jenis Bingkai).
JUMLAH LOCI PER RUANGAN: $loci Loci.

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
(Ulangi blok ini untuk setiap aset: RUANG, KORIDOR, EKSTERIOR)
[NAMA ASET]
Data Teknis: (Posisi Pintu, Arah Cahaya).
PROMPT FINAL:
Plaintext
(Tulis Prompt Bahasa Inggris yang sangat panjang dan detail di sini. Gabungkan deskripsi Pintu + Layer Dinding + Layer Lantai + Loci + Lighting + Render Engine Keywords)
""";

    setState(() {
      _generatedInstruction = template;
    });
  }

  Future<void> _saveResultToFile() async {
    try {
      final file = File(
        p.join(widget.buildingDirectory.path, 'prompts_history.txt'),
      );
      final timestamp = DateTime.now().toString();

      final params =
          "Tema: ${_promptThemeCtrl.text} | Cahaya: ${_promptLightCtrl.text}";

      final entry =
          """
\n\n========================================
[SAVED ON: $timestamp]
[PARAMS: $params]
========================================
${_aiResultCtrl.text}
========================================\n
""";

      await file.writeAsString(entry, mode: FileMode.append);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Prompt berhasil disimpan ke: ${p.basename(file.path)}",
            ),
            backgroundColor: Colors.green,
          ),
        );
        _aiResultCtrl.clear();
      }
    } catch (e) {
      debugPrint("Gagal menyimpan prompt: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- FITUR HISTORY VIEWER ---
  void _showPromptHistoryDialog() {
    final file = File(
      p.join(widget.buildingDirectory.path, 'prompts_history.txt'),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.history, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("Riwayat Prompt"),
            ],
          ),
          content: FutureBuilder<String>(
            // PERBAIKAN DI SINI: Gunakan existsSync()
            future: file.existsSync()
                ? file.readAsString()
                : Future.value("Belum ada riwayat."),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final text = snapshot.data ?? "Belum ada riwayat.";

              if (text.isEmpty || text == "Belum ada riwayat.") {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      "Belum ada prompt tersimpan.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      text,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // ... (kode hapus tetap sama, tapi gunakan existsSync() atau await exists())
                if (file.existsSync()) {
                  // Gunakan existsSync di sini juga agar konsisten
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Hapus Semua Riwayat?"),
                      content: const Text(
                        "Tindakan ini tidak bisa dibatalkan.",
                      ),
                      actions: [
                        TextButton(
                          child: const Text("Batal"),
                          onPressed: () => Navigator.pop(c, false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text("Hapus"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await file.delete();
                    if (context.mounted) Navigator.pop(context);
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Riwayat dihapus.")),
                      );
                  }
                }
              },
              child: const Text(
                "Hapus Semua",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
  // ===========================================================================
  // ROOM MANAGEMENT LOGIC
  // ===========================================================================

  Future<void> _showAddRoomDialog() async {
    _roomNameController.clear();
    _pickedImagePath = null;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Ruangan Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Ruangan',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar'),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          setDialogState(
                            () => _pickedImagePath = result.files.single.path!,
                          );
                        }
                      },
                    ),
                    if (_pickedImagePath != null)
                      Text(
                        'Gambar: ${p.basename(_pickedImagePath!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Buat'),
                  onPressed: _createNewRoom,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNewRoom() async {
    final String roomName = _roomNameController.text.trim();
    if (roomName.isEmpty) return;
    try {
      String? relativeImagePath;
      if (_pickedImagePath != null) {
        final sourceFile = File(_pickedImagePath!);
        final extension = p.extension(_pickedImagePath!);
        final uniqueFileName =
            'room_${DateTime.now().millisecondsSinceEpoch}$extension';
        final destinationPath = p.join(
          widget.buildingDirectory.path,
          uniqueFileName,
        );
        await sourceFile.copy(destinationPath);
        relativeImagePath = uniqueFileName;
      }
      final newRoom = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': roomName,
        'image': relativeImagePath,
        'connections': [],
      };
      setState(() => _rooms.add(newRoom));
      await _saveData();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ruangan "$roomName" dibuat')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat ruangan: $e')));
      }
    }
  }

  Future<void> _showEditRoomDialog(Map<String, dynamic> room) async {
    _roomNameController.text = room['name'] ?? '';
    _pickedImagePath = null;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String currentImageName = room['image'] == null
                ? 'Tidak ada gambar'
                : 'Saat ini: ${room['image']}';
            if (_pickedImagePath != null) {
              currentImageName = 'Baru: ${p.basename(_pickedImagePath!)}';
            } else if (_pickedImagePath == 'DELETE_IMAGE') {
              currentImageName = 'Gambar akan dihapus';
            }
            return AlertDialog(
              title: Text('Ubah Ruangan: ${room['name']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(
                        hintText: 'Nama Ruangan',
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar Baru'),
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        if (result != null &&
                            result.files.single.path != null) {
                          setDialogState(
                            () => _pickedImagePath = result.files.single.path!,
                          );
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        currentImageName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (room['image'] != null)
                      TextButton(
                        onPressed: () => setDialogState(
                          () => _pickedImagePath =
                              _pickedImagePath == 'DELETE_IMAGE'
                              ? null
                              : 'DELETE_IMAGE',
                        ),
                        child: Text(
                          _pickedImagePath == 'DELETE_IMAGE'
                              ? 'Batalkan Hapus'
                              : 'Hapus Gambar',
                          style: TextStyle(
                            color: _pickedImagePath == 'DELETE_IMAGE'
                                ? Colors.blue
                                : Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Simpan'),
                  onPressed: () async {
                    if (_roomNameController.text.trim().isEmpty) return;
                    await _updateRoom(room);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
    _roomNameController.clear();
    _pickedImagePath = null;
    await _loadData();
  }

  Future<void> _updateRoom(Map<String, dynamic> room) async {
    try {
      final String newName = _roomNameController.text.trim();
      final String? oldImageName = room['image'];
      String? newRelativeImagePath = oldImageName;
      if (_pickedImagePath == 'DELETE_IMAGE') {
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.buildingDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) await oldFile.delete();
        }
        newRelativeImagePath = null;
      } else if (_pickedImagePath != null) {
        if (oldImageName != null) {
          final oldFile = File(
            p.join(widget.buildingDirectory.path, oldImageName),
          );
          if (await oldFile.exists()) await oldFile.delete();
        }
        final sourceFile = File(_pickedImagePath!);
        final extension = p.extension(_pickedImagePath!);
        final uniqueFileName =
            'room_${DateTime.now().millisecondsSinceEpoch}$extension';
        await sourceFile.copy(
          p.join(widget.buildingDirectory.path, uniqueFileName),
        );
        newRelativeImagePath = uniqueFileName;
      }
      setState(() {
        room['name'] = newName;
        room['image'] = newRelativeImagePath;
      });
      await _saveData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    }
  }

  Future<void> _deleteRoom(Map<String, dynamic> room) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ruangan'),
        content: Text('Hapus "${room['name']}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      if (room['image'] != null) {
        final f = File(p.join(widget.buildingDirectory.path, room['image']));
        if (await f.exists()) await f.delete();
      }
      setState(() {
        _rooms.removeWhere((r) => r['id'] == room['id']);
        for (var r in _rooms) {
          (r['connections'] as List).removeWhere(
            (c) => c['targetRoomId'] == room['id'],
          );
        }
      });
      await _saveData();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruangan dihapus'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }

  // --- NAVIGATION LOGIC ---

  Map<String, double> _getDefaultCoordsForDirection(String dir) {
    switch (dir) {
      case 'up':
        return {'x': 0.5, 'y': 0.1};
      case 'down':
        return {'x': 0.5, 'y': 0.9};
      case 'left':
        return {'x': 0.1, 'y': 0.5};
      case 'right':
        return {'x': 0.9, 'y': 0.5};
      default:
        return {'x': 0.5, 'y': 0.5};
    }
  }

  Future<void> _showNavigationDialog(Map<String, dynamic> fromRoom) async {
    final otherRooms = _rooms.where((r) => r['id'] != fromRoom['id']).toList();
    final connections = (fromRoom['connections'] as List? ?? []);
    final labelController = TextEditingController();
    String? selectedTargetRoomId;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Atur Navigasi: ${fromRoom['name']}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Navigasi Saat Ini:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (connections.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Belum ada navigasi.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ...connections.map((conn) {
                        final targetName = _rooms.firstWhere(
                          (r) => r['id'] == conn['targetRoomId'],
                          orElse: () => {'name': '?'},
                        )['name'];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(
                              Icons.login,
                              color: Colors.blue,
                            ),
                            title: Text(
                              "Ke: $targetName",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Label: ${conn['label'] ?? 'Pintu'}\nArah: ${conn['direction'] ?? 'up'}",
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    await _showEditLabelDialog(conn);
                                    setDialogState(() {});
                                  },
                                  tooltip: "Ubah Label",
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() => connections.remove(conn));
                                    _saveData();
                                    setDialogState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      const Text(
                        'Tambah Navigasi Baru:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        hint: const Text('Pilih Ruangan Tujuan'),
                        value: selectedTargetRoomId,
                        isExpanded: true,
                        items: otherRooms
                            .map(
                              (room) => DropdownMenuItem(
                                value: room['id'].toString(),
                                child: Text(room['name'] ?? '?'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedTargetRoomId = val),
                      ),
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label Tombol (Kosong = Nama Ruangan)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Catatan: Posisi dan Arah panah diatur di Viewer.",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Tutup'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Tambah'),
                  onPressed: () async {
                    if (selectedTargetRoomId == null) return;

                    final targetRoom = _rooms.firstWhere(
                      (r) => r['id'] == selectedTargetRoomId,
                    );
                    final targetName = targetRoom['name'] ?? 'Ruangan';

                    final label = labelController.text.trim().isEmpty
                        ? targetName
                        : labelController.text.trim();

                    final newConnection = {
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'label': label,
                      'targetRoomId': selectedTargetRoomId,
                      'direction': 'up',
                      'x': 0.5,
                      'y': 0.5,
                    };

                    setState(() => connections.add(newConnection));
                    await _saveData();

                    if (mounted)
                      _offerReturnNavigation(fromRoom, selectedTargetRoomId!);

                    labelController.clear();
                    selectedTargetRoomId = null;
                    setDialogState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditLabelDialog(Map<String, dynamic> connection) async {
    final controller = TextEditingController(text: connection['label']);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Label Tombol'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Label Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                connection['label'] = controller.text.trim();
                await _saveData();
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _offerReturnNavigation(
    Map<String, dynamic> fromRoom,
    String targetId,
  ) async {
    final targetRoom = _rooms.firstWhere((r) => r['id'] == targetId);
    bool? create = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Navigasi Balik'),
        content: Text(
          'Buat pintu balik dari "${targetRoom['name']}" ke "${fromRoom['name']}"?',
        ),
        actions: [
          TextButton(
            child: const Text('Tidak'),
            onPressed: () => Navigator.pop(c, false),
          ),
          ElevatedButton(
            child: const Text('Ya'),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (create == true) {
      targetRoom['connections'] ??= [];
      final coords = _getDefaultCoordsForDirection('down');
      (targetRoom['connections'] as List).add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'label': fromRoom['name'],
        'targetRoomId': fromRoom['id'],
        'direction': 'down',
        'x': coords['x'],
        'y': coords['y'],
      });
      await _saveData();
    }
  }

  Future<void> _exportRoomImage(Map<String, dynamic> room) async {
    if (room['image'] == null || AppSettings.exportPath == null) return;
    final src = File(p.join(widget.buildingDirectory.path, room['image']));
    if (await src.exists()) {
      final dest = p.join(
        AppSettings.exportPath!,
        'room_export_${p.basename(src.path)}',
      );
      await src.copy(dest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gambar diexport'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${p.basename(widget.buildingDirectory.path)}'),
        actions: [
          // --- TOMBOL BARU UNTUK AI PROMPT ---
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
            tooltip: "AI Visual Architect",
            onPressed: _generateAndShowPromptDialog,
          ),
          // -----------------------------------
          IconButton(
            icon: Icon(_isReorderMode ? Icons.link : Icons.swap_vert),
            tooltip: _isReorderMode ? 'Mode Navigasi' : 'Mode Urutkan',
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildRoomList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRoomList() {
    if (_rooms.isEmpty) return const Center(child: Text('Belum ada ruangan.'));

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final imagePath = room['image'];
        Widget leading = imagePath != null
            ? Image.file(
                File(p.join(widget.buildingDirectory.path, imagePath)),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.sensor_door);

        return ListTile(
          key: ValueKey(room['id']),
          leading: leading,
          title: Text(room['name'] ?? '?'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => BuildingViewerPage(
                  buildingDirectory: widget.buildingDirectory,
                  initialRoomId: room['id'],
                ),
              ),
            );
          },
          trailing: _isReorderMode
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                )
              : PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'nav') _showNavigationDialog(room);
                    if (v == 'edit') _showEditRoomDialog(room);
                    if (v == 'export') _exportRoomImage(room);
                    if (v == 'del') _deleteRoom(room);
                  },
                  itemBuilder: (c) => [
                    const PopupMenuItem(
                      value: 'nav',
                      child: Text('Atur Navigasi'),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Info'),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export Gambar'),
                    ),
                    const PopupMenuItem(
                      value: 'del',
                      child: Text('Hapus', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
        );
      },
      onReorder: (oldIdx, newIdx) {
        setState(() {
          if (newIdx > oldIdx) newIdx -= 1;
          final item = _rooms.removeAt(oldIdx);
          _rooms.insert(newIdx, item);
        });
        _saveData();
      },
    );
  }
}
