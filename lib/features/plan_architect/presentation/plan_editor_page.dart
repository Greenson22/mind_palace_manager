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

  final List<Color> _colors = [
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
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- WIDGET DIALOG WARNA ---
  void _showColorPicker(BuildContext context, Function(Color) onColorSelected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Warna"),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors
                .map(
                  (color) => InkWell(
                    onTap: () {
                      onColorSelected(color);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
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

  // --- FUNGSI UNTUK MEMILIH INTERIOR (BOTTOM SHEET) ---
  void _showInteriorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DefaultTabController(
                length: 6,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const TabBar(
                      isScrollable: true,
                      labelColor: Colors.black,
                      tabs: [
                        Tab(text: "Furnitur"),
                        Tab(text: "Elektronik"),
                        Tab(text: "Sanitasi"),
                        Tab(text: "Struktur"),
                        Tab(text: "Dekorasi"),
                        Tab(text: "Pustaka Saya"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildIconGrid([
                            {'icon': Icons.chair, 'name': 'Kursi'},
                            {'icon': Icons.chair_alt, 'name': 'Kursi 2'},
                            {'icon': Icons.table_bar, 'name': 'Meja Bulat'},
                            {
                              'icon': Icons.table_restaurant,
                              'name': 'Meja Makan',
                            },
                            {'icon': Icons.bed, 'name': 'Kasur King'},
                            {'icon': Icons.single_bed, 'name': 'Kasur Single'},
                            {'icon': Icons.weekend, 'name': 'Sofa'},
                            {'icon': Icons.event_seat, 'name': 'Bangku'},
                            {'icon': Icons.desk, 'name': 'Meja Kerja'},
                            {'icon': Icons.shelves, 'name': 'Rak Buku'},
                            {'icon': Icons.kitchen, 'name': 'Lemari Es'},
                            {'icon': Icons.inventory_2, 'name': 'Lemari'},
                          ]),
                          _buildIconGrid([
                            {'icon': Icons.tv, 'name': 'TV'},
                            {'icon': Icons.computer, 'name': 'Komputer'},
                            {'icon': Icons.laptop, 'name': 'Laptop'},
                            {'icon': Icons.microwave, 'name': 'Microwave'},
                            {'icon': Icons.print, 'name': 'Printer'},
                            {'icon': Icons.speaker, 'name': 'Speaker'},
                            {'icon': Icons.router, 'name': 'Router'},
                            {'icon': Icons.videogame_asset, 'name': 'Konsol'},
                          ]),
                          _buildIconGrid([
                            {'icon': Icons.bathtub, 'name': 'Bathtub'},
                            {'icon': Icons.shower, 'name': 'Shower'},
                            {'icon': Icons.wc, 'name': 'Toilet'},
                            {'icon': Icons.wash, 'name': 'Wastafel'},
                            {'icon': Icons.water_drop, 'name': 'Keran'},
                            {'icon': Icons.soap, 'name': 'Sabun'},
                          ]),
                          _buildIconGrid([
                            {
                              'icon': Icons.door_front_door,
                              'name': 'Pintu Depan',
                            },
                            {'icon': Icons.door_sliding, 'name': 'Pintu Geser'},
                            {'icon': Icons.window, 'name': 'Jendela'},
                            {'icon': Icons.stairs, 'name': 'Tangga'},
                            {'icon': Icons.elevator, 'name': 'Lift'},
                            {'icon': Icons.fence, 'name': 'Pagar'},
                            {'icon': Icons.garage, 'name': 'Garasi'},
                            {'icon': Icons.balcony, 'name': 'Balkon'},
                          ]),
                          _buildIconGrid([
                            {'icon': Icons.local_florist, 'name': 'Tanaman'},
                            {'icon': Icons.light, 'name': 'Lampu'},
                            {'icon': Icons.curtains, 'name': 'Gorden'},
                            {'icon': Icons.checkroom, 'name': 'Gantungan'},
                            {'icon': Icons.palette, 'name': 'Lukisan'},
                            {'icon': Icons.fitness_center, 'name': 'Alat Gym'},
                            {'icon': Icons.pool, 'name': 'Kolam'},
                            {'icon': Icons.directions_car, 'name': 'Mobil'},
                          ]),
                          // TAB CUSTOM LIBRARY
                          _controller.savedCustomInteriors.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Belum ada interior tersimpan.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount:
                                      _controller.savedCustomInteriors.length,
                                  itemBuilder: (context, index) {
                                    final path =
                                        _controller.savedCustomInteriors[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.brown,
                                        child: Icon(
                                          Icons.brush,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(path.name),
                                      subtitle: Text(path.description),
                                      onTap: () {
                                        // Hitung center layar
                                        final center = Offset(
                                          MediaQuery.of(context).size.width / 2,
                                          MediaQuery.of(context).size.height /
                                              3,
                                        );
                                        _controller.placeSavedPath(
                                          path,
                                          center,
                                        );
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Interior kustom diletakkan.",
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            _controller.selectObjectIcon(item['icon'], item['name']);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[100],
                child: Icon(item['icon'], color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                item['name'],
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  // ... (Metode Export, HandleTapUp, ShowEditDialog SAMA seperti sebelumnya) ...
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
            child: Column(
              children: [
                SingleChildScrollView(
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
                            isActive:
                                _controller.activeTool == PlanTool.freehand,
                            onTap: () => _controller.setTool(PlanTool.freehand),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<PlanShapeType>(
                            child: _buildToolBtn(
                              icon: Icons.category,
                              label: "Bentuk",
                              isActive:
                                  _controller.activeTool == PlanTool.shape,
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

                          // TOMBOL INTERIOR BARU
                          InkWell(
                            onTap: () => _showInteriorPicker(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _controller.activeTool == PlanTool.object
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    _controller.activeTool == PlanTool.object
                                    ? null
                                    : Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _controller.selectedObjectIcon ??
                                        Icons.chair,
                                    size: 20,
                                    color:
                                        _controller.activeTool ==
                                            PlanTool.object
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Interior",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight:
                                          _controller.activeTool ==
                                              PlanTool.object
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color:
                                          _controller.activeTool ==
                                              PlanTool.object
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

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
                const Divider(height: 12),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Default: ", style: TextStyle(fontSize: 12)),
                      InkWell(
                        onTap: () => _showColorPicker(
                          context,
                          (c) => _controller.setActiveColor(c),
                        ),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _controller.activeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.line_weight,
                        size: 20,
                        color: Colors.grey,
                      ),
                      SizedBox(
                        width: 100,
                        child: Slider(
                          value: _controller.activeStrokeWidth,
                          min: 1.0,
                          max: 20.0,
                          divisions: 19,
                          label: _controller.activeStrokeWidth
                              .round()
                              .toString(),
                          onChanged: (v) => _controller.setActiveStrokeWidth(v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BAR SELEKSI
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.selectedId != null) {
                final data = _controller.getSelectedItemData();
                final bool canHaveStroke =
                    data?['type'] == 'Struktur' || data?['type'] == 'Gambar';
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
                          InkWell(
                            onTap: () => _showColorPicker(
                              context,
                              (c) => _controller.updateSelectedColor(c),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.color_lens, color: Colors.blue),
                            ),
                          ),
                          if (canHaveStroke)
                            SizedBox(
                              width: 80,
                              child: Slider(
                                value: (data?['type'] == 'Struktur')
                                    ? (_controller.walls
                                          .firstWhere(
                                            (w) =>
                                                w.id == _controller.selectedId,
                                          )
                                          .thickness)
                                    : (_controller.paths
                                          .firstWhere(
                                            (p) =>
                                                p.id == _controller.selectedId,
                                          )
                                          .strokeWidth),
                                min: 1.0,
                                max: 20.0,
                                divisions: 19,
                                onChanged: (v) =>
                                    _controller.updateSelectedStrokeWidth(v),
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
