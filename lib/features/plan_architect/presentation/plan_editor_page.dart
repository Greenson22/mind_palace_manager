// lib/features/plan_architect/presentation/plan_editor_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import '../logic/plan_controller.dart';
import '../data/plan_models.dart';
import 'plan_painter.dart';

class PlanEditorPage extends StatefulWidget {
  const PlanEditorPage({super.key});

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  final PlanController _controller = PlanController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ... (Metode Export dan Handle TapUp SAMA) ...
  Future<void> _exportImage() async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Atur folder export di Pengaturan dulu.")),
      );
      return;
    }
    try {
      final recorder = ui.PictureRecorder();
      const exportSize = Size(1000, 1000);
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
        Paint()..color = Colors.white,
      );
      final painter = PlanPainter(controller: _controller);
      painter.paint(canvas, exportSize);
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        exportSize.width.toInt(),
        exportSize.height.toInt(),
      );
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes != null) {
        final now = DateTime.now();
        final fileName =
            'plan_${now.year}${now.month}${now.day}_${now.hour}${now.minute}.png';
        final file = File(p.join(AppSettings.exportPath!, fileName));
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tersimpan: ${file.path}"),
              backgroundColor: Colors.green,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal export: $e"),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  void _handleTapUp(Offset localPos) {
    if (_controller.activeTool == PlanTool.text) {
      final textCtrl = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Tambah Label"),
          content: TextField(
            controller: textCtrl,
            decoration: const InputDecoration(hintText: "Nama Ruangan"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (textCtrl.text.isNotEmpty) {
                  _controller.addLabel(localPos, textCtrl.text);
                }
                Navigator.pop(ctx);
              },
              child: const Text("Tambah"),
            ),
          ],
        ),
      );
    } else {
      _controller.onTapUp(localPos);
    }
  }

  void _showEditDialog() {
    /* ... SAMA SEPERTI SEBELUMNYA ... */
    final data = _controller.getSelectedItemData();
    if (data == null) return;
    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['desc']);
    final bool isPath = data['isPath'] ?? false;
    final bool isLabel = data['type'] == 'Label';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${data['type']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: isLabel ? 'Isi Teks' : 'Nama',
              ),
              enabled: isPath || isLabel || data['type'] != 'Struktur',
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
            if (isPath) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.bookmark_add),
                label: const Text("Simpan ke Pustaka Saya"),
                onPressed: () {
                  _controller.updateDescription(
                    descCtrl.text,
                    newName: titleCtrl.text,
                  );
                  _controller.saveCurrentSelectionToLibrary();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Item '${titleCtrl.text}' disimpan ke Pustaka!",
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _controller.deleteSelected();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.updateDescription(
                descCtrl.text,
                newName: titleCtrl.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Arsitek Denah"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: "Export Image",
            onPressed: _exportImage,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _controller.clearAll();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text(
                  'Hapus Semua (Reset)',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // TOOLBAR ATAS
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _controller.enableSnap
                              ? Icons.grid_on
                              : Icons.grid_off,
                          color: Colors.grey,
                        ),
                        onPressed: _controller.toggleSnap,
                        tooltip: "Snap",
                      ),
                      IconButton(
                        icon: const Icon(Icons.undo, color: Colors.grey),
                        onPressed: _controller.canUndo
                            ? _controller.undo
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.redo, color: Colors.grey),
                        onPressed: _controller.canRedo
                            ? _controller.redo
                            : null,
                      ),
                      const VerticalDivider(width: 20, thickness: 1),

                      _buildToolBtn(
                        icon: Icons.pan_tool,
                        label: "Pilih",
                        isActive: _controller.activeTool == PlanTool.select,
                        onTap: () => _controller.setTool(PlanTool.select),
                      ),
                      const SizedBox(width: 8),
                      _buildToolBtn(
                        icon: Icons.format_paint,
                        label: "Tembok",
                        isActive: _controller.activeTool == PlanTool.wall,
                        onTap: () => _controller.setTool(PlanTool.wall),
                      ),
                      const SizedBox(width: 8),
                      _buildToolBtn(
                        icon: Icons.text_fields,
                        label: "Label",
                        isActive: _controller.activeTool == PlanTool.text,
                        onTap: () => _controller.setTool(PlanTool.text),
                      ),
                      const SizedBox(width: 8),
                      _buildToolBtn(
                        icon: Icons.brush,
                        label: "Gambar",
                        isActive: _controller.activeTool == PlanTool.freehand,
                        onTap: () => _controller.setTool(PlanTool.freehand),
                      ),
                      const SizedBox(width: 8),

                      // Shape Menu
                      PopupMenuButton<PlanShapeType>(
                        child: _buildToolBtn(
                          icon: Icons.category,
                          label: "Bentuk",
                          isActive: _controller.activeTool == PlanTool.shape,
                          onTap: null,
                        ),
                        onSelected: (type) => _controller.selectShape(type),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: PlanShapeType.rectangle,
                            child: Row(
                              children: [
                                Icon(Icons.crop_square),
                                SizedBox(width: 8),
                                Text("Kotak"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: PlanShapeType.circle,
                            child: Row(
                              children: [
                                Icon(Icons.circle_outlined),
                                SizedBox(width: 8),
                                Text("Bulat"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: PlanShapeType.star,
                            child: Row(
                              children: [
                                Icon(Icons.star_border),
                                SizedBox(width: 8),
                                Text("Bintang"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),

                      _buildInteriorMenu(),
                      const SizedBox(width: 8),
                      _buildToolBtn(
                        icon: Icons.delete_forever,
                        label: "Hapus",
                        isActive: _controller.activeTool == PlanTool.eraser,
                        iconColor: Colors.red,
                        onTap: () => _controller.setTool(PlanTool.eraser),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // BAR SELEKSI & EDIT (BAWAH TOOLBAR)
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.selectedId != null) {
                final data = _controller.getSelectedItemData();
                return Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${data?['title']} (${data?['type']})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text("Info"),
                            onPressed: _showEditDialog,
                            style: ElevatedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      // ACTION BAR (Copy, Rotate, Layer)
                      const Divider(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: _controller.duplicateSelected,
                            tooltip: "Duplikat",
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_right, size: 20),
                            onPressed: _controller.rotateSelected,
                            tooltip: "Putar",
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_to_front, size: 20),
                            onPressed: _controller.bringToFront,
                            tooltip: "Ke Depan",
                          ),
                          IconButton(
                            icon: const Icon(Icons.flip_to_back, size: 20),
                            onPressed: _controller.sendToBack,
                            tooltip: "Ke Belakang",
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
              if (_controller.activeTool == PlanTool.eraser)
                return Container(
                  color: Colors.red.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Mode Penghapus Aktif",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              if (_controller.activeTool == PlanTool.text)
                return Container(
                  color: Colors.orange.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Ketuk di layar untuk menambah teks",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                );
              return const SizedBox.shrink();
            },
          ),

          // CANVAS
          Expanded(
            child: GestureDetector(
              onPanStart: (d) => _controller.onPanStart(d.localPosition),
              onPanUpdate: (d) => _controller.onPanUpdate(d.localPosition),
              onPanEnd: (d) => _controller.onPanEnd(),
              onTapUp: (d) => _handleTapUp(d.localPosition),
              child: Container(
                color: Colors.white,
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: PlanPainter(controller: _controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Helper Widgets SAMA: _buildInteriorMenu, _buildToolBtn) ...
  Widget _buildInteriorMenu() {
    return PopupMenuButton<dynamic>(
      child: _buildToolBtn(
        icon: _controller.selectedObjectIcon ?? Icons.chair,
        label: "Interior",
        isActive: _controller.activeTool == PlanTool.object,
        onTap: null,
      ),
      onSelected: (val) {
        if (val is Map) {
          _controller.selectObjectIcon(val['icon'], val['name']);
        } else if (val is PlanPath) {
          final center = Offset(
            MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 3,
          );
          _controller.placeSavedPath(val, center);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Interior kustom diletakkan.")),
          );
        }
      },
      itemBuilder: (ctx) {
        List<PopupMenuEntry<dynamic>> items = [];
        items.add(
          const PopupMenuItem(
            enabled: false,
            child: Text(
              "STANDAR",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        );
        items.addAll([
          _buildPopupItem(Icons.chair, "Kursi"),
          _buildPopupItem(Icons.table_bar, "Meja"),
          _buildPopupItem(Icons.bed, "Kasur"),
          _buildPopupItem(Icons.door_front_door, "Pintu"),
          _buildPopupItem(Icons.kitchen, "Kulkas"),
          _buildPopupItem(Icons.tv, "TV"),
          _buildPopupItem(Icons.wc, "Toilet"),
          _buildPopupItem(Icons.local_florist, "Tanaman"),
        ]);
        if (_controller.savedCustomInteriors.isNotEmpty) {
          items.add(const PopupMenuDivider());
          items.add(
            const PopupMenuItem(
              enabled: false,
              child: Text(
                "PUSTAKA SAYA",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
          for (var savedPath in _controller.savedCustomInteriors) {
            items.add(
              PopupMenuItem(
                value: savedPath,
                child: Row(
                  children: [
                    const Icon(Icons.draw, color: Colors.brown),
                    const SizedBox(width: 8),
                    Text(savedPath.name),
                  ],
                ),
              ),
            );
          }
        }
        return items;
      },
    );
  }

  PopupMenuItem<Map<String, dynamic>> _buildPopupItem(
    IconData icon,
    String name,
  ) {
    return PopupMenuItem(
      value: {'icon': icon, 'name': name},
      child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(name)]),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (iconColor ?? Colors.blueAccent)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : (iconColor ?? Colors.black87),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
