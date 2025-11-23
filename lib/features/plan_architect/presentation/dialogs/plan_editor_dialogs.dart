import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';
import 'package:mind_palace_manager/features/plan_architect/presentation/dialogs/interior_picker_sheet.dart';

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

  // Method showFloorManager telah dihapus.

  static void showEditDialog(BuildContext context, PlanController controller) {
    final data = controller.getSelectedItemData();
    if (data == null) return;

    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['desc']);

    String? currentRefImage = data['refImage'];
    String? newRefImage = currentRefImage;

    final bool isPath = data['isPath'] ?? false;
    final bool isLabel = data['type'] == 'Label';
    final bool isWall = data['type'] == 'Struktur';

    // Navigasi dihapus, jadi kita set null
    String? selectedNavFloorId = null;

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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${data['type']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLabel && !isPath) ...[
                  const Text(
                    "Wujud Asli / Referensi:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(type: FileType.image);
                      if (result != null && result.files.single.path != null) {
                        setState(() {
                          newRefImage = result.files.single.path;
                        });
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                        image: newRefImage != null
                            ? DecorationImage(
                                image: FileImage(File(newRefImage!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: newRefImage == null
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
                // Dropdown navigasi dihapus
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
                      Navigator.pop(context);
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
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Hapus'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.updateSelectedAttribute(
                  desc: descCtrl.text,
                  name: titleCtrl.text,
                  navTarget: selectedNavFloorId,
                  referenceImage: newRefImage,
                );
                if (isWall && lengthCtrl != null) {
                  final newLen = double.tryParse(
                    lengthCtrl.text.replaceAll(',', '.'),
                  );
                  if (newLen != null && newLen > 0)
                    controller.updateSelectedWallLength(newLen);
                }
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
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

  static void showViewModeInfo(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    String? refImage = data['refImage'];

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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(refImage),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
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
}
