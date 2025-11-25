// lib/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math' as math; // Tambahan import math
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p; // Import path
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/interior_picker_sheet.dart';
import 'package:mind_palace_manager/features/building/presentation/management/logic/district_building_logic.dart';

class PlanEditorDialogs {
  static final List<Color> _colors = [
    Colors.black,
    Colors.grey,
    Colors.blueGrey,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.white,
  ];

  // --- HELPER: MENAMPILKAN GAMBAR FULL SCREEN ---
  static void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9), // Latar belakang gelap
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Memenuhi layar
        child: Stack(
          children: [
            // 1. Interactive Viewer untuk Zoom & Pan
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.1,
                maxScale: 5.0,
                child: Image.file(File(imagePath), fit: BoxFit.contain),
              ),
            ),
            // 2. Tombol Tutup (X)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showLayerSettings(
    BuildContext context,
    PlanController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Atur Layer & Tampilan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text("Tampilkan Grid"),
                  value: controller.showGrid,
                  onChanged: (v) {
                    controller.toggleGridVisibility();
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text("Tombol Zoom (+/-)"),
                  subtitle: const Text("Sembunyikan jika mengganggu"),
                  value: controller.showZoomButtons,
                  onChanged: (v) {
                    controller.toggleZoomButtonsVisibility();
                    setState(() {});
                  },
                ),
                if (controller.showGrid) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Ukuran Kotak Grid"),
                    ),
                  ),
                  Slider(
                    value: controller.gridSize,
                    min: 10.0,
                    max: 100.0,
                    divisions: 18,
                    label: "${controller.gridSize.toInt()}px",
                    onChanged: (val) {
                      controller.setGridSize(val);
                      setState(() {});
                    },
                  ),
                ],
                const Divider(),
                CheckboxListTile(
                  title: const Text("Layer Tembok"),
                  value: controller.layerWalls,
                  onChanged: (v) {
                    controller.toggleLayer('walls');
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text("Layer Interior/Objek"),
                  value: controller.layerObjects,
                  onChanged: (v) {
                    controller.toggleLayer('objects');
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text("Layer Label Teks"),
                  value: controller.layerLabels,
                  onChanged: (v) {
                    controller.toggleLayer('labels');
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text("Ukuran Tembok"),
                  value: controller.layerDims,
                  onChanged: (v) {
                    controller.toggleLayer('dims');
                    setState(() {});
                  },
                ),
                const Divider(),
                const Text(
                  "Warna Latar Kanvas",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                            Colors.white,
                            Colors.blue.shade50,
                            Colors.grey.shade200,
                            const Color(0xFFFFF3E0),
                            Colors.black,
                            const Color(0xFF121212),
                          ]
                          .map(
                            (c) => InkWell(
                              onTap: () {
                                controller.setCanvasColor(c);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tutup"),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditDialog(
    BuildContext context,
    PlanController controller, {
    Directory? buildingDirectory,
  }) {
    final data = controller.getSelectedItemData();
    if (data == null) return;

    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['desc']);

    String? currentRefImage = data['refImage'];
    String? newRefImage = currentRefImage;

    final bool isPath = data['isPath'] ?? false;
    final bool isLabel = data['type'] == 'Label';
    final bool isWall = data['title'] == 'Tembok';
    final bool canNavigate =
        data['type'] == 'Interior' || data['type'] == 'Struktur';

    String? selectedNavFloorId = data['nav'];

    TextEditingController? lengthCtrl;
    if (isWall) {
      try {
        final wall = controller.walls.firstWhere((w) => w.id == data['id']);
        final lenPx = (wall.end - wall.start).distance;
        final lenM = (lenPx / 40.0).toStringAsFixed(2);
        lengthCtrl = TextEditingController(text: lenM);
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildNavDropdown() {
              if (!canNavigate || buildingDirectory == null) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: DistrictBuildingLogic(
                  buildingDirectory.parent,
                ).getBuildingPlans(buildingDirectory),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        "Memuat daftar denah...",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    );
                  }

                  final plans = snapshot.data!;
                  final List<DropdownMenuItem<String?>> items = [
                    const DropdownMenuItem(
                      value: null,
                      child: Text("Tidak Ada (Diam)"),
                    ),
                  ];

                  items.addAll(
                    plans.map(
                      (p) => DropdownMenuItem(
                        value: p['id'],
                        child: Text("Pindah ke: ${p['name']}"),
                      ),
                    ),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Aksi Saat Ditekan (View Mode):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        DropdownButton<String?>(
                          value: selectedNavFloorId,
                          isExpanded: true,
                          items: items,
                          onChanged: (val) {
                            setState(() => selectedNavFloorId = val);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            // Logic tampilan gambar preview di dialog
            ImageProvider? imageProvider;
            if (newRefImage != null) {
              // Cek apakah path relatif atau absolut
              String displayPath = newRefImage!;
              if (buildingDirectory != null && !p.isAbsolute(displayPath)) {
                displayPath = p.join(buildingDirectory.path, displayPath);
              }
              final file = File(displayPath);
              if (file.existsSync()) {
                imageProvider = FileImage(file);
              }
            }

            return AlertDialog(
              title: Text('Edit ${data['type']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isLabel && !isPath) ...[
                      const Text(
                        "Wujud Asli / Referensi:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(type: FileType.image);
                          if (result != null &&
                              result.files.single.path != null) {
                            setState(() {
                              // Simpan path absolut sementara dari picker
                              newRefImage = result.files.single.path;
                            });
                          }
                        },
                        // --- DI SINI MODE EDIT, JADI TAP UNTUK GANTI ---
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                            image: imageProvider != null
                                ? DecorationImage(
                                    image: imageProvider!,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageProvider == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.grey),
                                    Text(
                                      "Tambah Foto",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ),
                      if (newRefImage != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red,
                            ),
                            label: const Text(
                              "Hapus Foto",
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                            onPressed: () {
                              setState(() => newRefImage = null);
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: isLabel ? 'Isi Teks' : 'Nama',
                      ),
                      enabled: isPath || isLabel || !isWall,
                    ),
                    const SizedBox(height: 8),
                    if (!isLabel)
                      TextField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    if (isWall && lengthCtrl != null) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: lengthCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Panjang (Meter)',
                          suffixText: 'm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    buildNavDropdown(),

                    if (isPath) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text("Simpan ke Pustaka Saya"),
                        onPressed: () {
                          controller.updateSelectedAttribute(
                            desc: descCtrl.text,
                            name: titleCtrl.text,
                          );
                          controller.saveCurrentSelectionToLibrary();
                          Navigator.pop(dialogContext);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.deleteSelected();
                    Navigator.pop(dialogContext);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Hapus'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // --- LOGIKA BARU: COPY GAMBAR SAAT SIMPAN ---
                    String? finalRefImage = newRefImage;
                    if (newRefImage != null && buildingDirectory != null) {
                      // Jika path absolut (dari picker), berarti file baru
                      if (p.isAbsolute(newRefImage!)) {
                        try {
                          final ext = p.extension(newRefImage!);
                          final fileName =
                              'ref_img_${DateTime.now().millisecondsSinceEpoch}$ext';
                          final destPath = p.join(
                            buildingDirectory.path,
                            fileName,
                          );
                          await File(newRefImage!).copy(destPath);
                          finalRefImage = fileName; // Simpan path relatif
                        } catch (e) {
                          debugPrint("Gagal copy ref image: $e");
                        }
                      }
                    }
                    // ---------------------------------------------

                    controller.updateSelectedAttribute(
                      desc: descCtrl.text,
                      name: titleCtrl.text,
                      navTarget: selectedNavFloorId,
                      referenceImage:
                          finalRefImage, // Gunakan path yang sudah diproses
                    );

                    if (isWall && lengthCtrl != null) {
                      final newLen = double.tryParse(
                        lengthCtrl.text.replaceAll(',', '.'),
                      );
                      if (newLen != null && newLen > 0)
                        controller.updateSelectedWallLength(newLen);
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showColorPicker(
    BuildContext context,
    Function(Color) onColorSelected,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Warna"),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colors
                .map(
                  (color) => InkWell(
                    onTap: () {
                      onColorSelected(color);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  static void showInteriorPicker(
    BuildContext context,
    PlanController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return InteriorPickerSheet(
              controller: controller,
              scrollController: scrollController,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  // --- MODIFIED: SUPPORTS FULL SCREEN IMAGE TAP ---
  static void showViewModeInfo(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    String? refImage =
        data['refImage']; // Ini sekarang path absolut yang sudah di-resolve oleh Controller

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (refImage != null && File(refImage).existsSync()) ...[
              Stack(
                children: [
                  GestureDetector(
                    // --- AKSI TAP GAMBAR: BUKA FULL SCREEN ---
                    onTap: () => _showFullScreenImage(context, refImage),
                    child: Hero(
                      tag: refImage, // Efek Hero sederhana
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(refImage),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  "Ketuk gambar untuk memperbesar",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              data['title'],
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                data['type'],
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
              backgroundColor: colorScheme.primaryContainer,
              side: BorderSide.none,
            ),
            const Divider(height: 24),
            Text(
              (data['desc'] != null && data['desc'].isNotEmpty)
                  ? data['desc']
                  : "Tidak ada deskripsi.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- BARU: Dialog Rotasi Detail ---
  static void showRotationDialog(
    BuildContext context,
    double currentRotationRadians,
    Function(double) onRotationChanged,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        // Konversi radians ke derajat untuk tampilan UI
        double currentDegrees = (currentRotationRadians * 180 / math.pi) % 360;
        if (currentDegrees < 0) currentDegrees += 360;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Atur Rotasi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview Circle/Arrow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Transform.rotate(
                      angle: currentDegrees * math.pi / 180,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Teks Derajat
                  Text(
                    "${currentDegrees.round()}°",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Slider 0 - 360
                  Slider(
                    value: currentDegrees,
                    min: 0.0,
                    max: 360.0,
                    divisions: 360, // Step per 1 derajat
                    label: "${currentDegrees.round()}°",
                    onChanged: (val) {
                      setState(() {
                        currentDegrees = val;
                      });
                      // Kirim balik dalam radians
                      onRotationChanged(val * math.pi / 180);
                    },
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickRotateBtn("-45°", -45, currentDegrees, (v) {
                        setState(() => currentDegrees = v);
                        onRotationChanged(v * math.pi / 180);
                      }),
                      _buildQuickRotateBtn("0°", 0, currentDegrees, (v) {
                        setState(() => currentDegrees = v);
                        onRotationChanged(v * math.pi / 180);
                      }),
                      _buildQuickRotateBtn("+45°", 45, currentDegrees, (v) {
                        setState(() => currentDegrees = v);
                        onRotationChanged(v * math.pi / 180);
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Selesai"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Widget _buildQuickRotateBtn(
    String label,
    double delta,
    double current,
    Function(double) onChanged,
  ) {
    return OutlinedButton(
      onPressed: () {
        if (delta == 0) {
          onChanged(0);
        } else {
          double newVal = (current + delta) % 360;
          if (newVal < 0) newVal += 360;
          onChanged(newVal);
        }
      },
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
