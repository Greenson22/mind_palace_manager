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

  // Palet Warna
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

  // ===============================================================
  // 1. DIALOG PENGATURAN TAMPILAN & LAYER
  // ===============================================================

  // --- BARU: DIALOG UBAH UKURAN CANVAS ---
  void _showCanvasResizer(BuildContext context) {
    final widthCtrl = TextEditingController(
      text: _controller.canvasWidth.toInt().toString(),
    );
    final heightCtrl = TextEditingController(
      text: _controller.canvasHeight.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ubah Ukuran Canvas"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan ukuran dalam pixel (px)."),
            const SizedBox(height: 16),
            TextField(
              controller: widthCtrl,
              decoration: const InputDecoration(labelText: "Lebar (Width)"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: heightCtrl,
              decoration: const InputDecoration(labelText: "Tinggi (Height)"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(widthCtrl.text) ?? 2500.0;
              final h = double.tryParse(heightCtrl.text) ?? 2500.0;

              // Batasi minimal agar tidak error/terlalu kecil
              final finalW = (w < 500) ? 500.0 : w;
              final finalH = (h < 500) ? 500.0 : h;

              _controller.updateCanvasSize(finalW, finalH);
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Ukuran diubah menjadi ${finalW.toInt()} x ${finalH.toInt()}",
                  ),
                ),
              );
            },
            child: const Text("Terapkan"),
          ),
        ],
      ),
    );
  }

  void _showLayerSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Atur Layer & Tampilan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text("Tampilkan Grid"),
                  value: _controller.showGrid,
                  onChanged: (v) {
                    _controller.toggleGridVisibility();
                    setState(() {});
                  },
                ),
                const Divider(),
                const Text(
                  "Visibilitas Layer",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CheckboxListTile(
                  title: const Text("Layer Tembok"),
                  value: _controller.layerWalls,
                  onChanged: (v) {
                    _controller.toggleLayer('walls');
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text("Layer Interior/Objek"),
                  value: _controller.layerObjects,
                  onChanged: (v) {
                    _controller.toggleLayer('objects');
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text("Layer Label Teks"),
                  value: _controller.layerLabels,
                  onChanged: (v) {
                    _controller.toggleLayer('labels');
                    setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text("Ukuran Tembok"),
                  value: _controller.layerDims,
                  onChanged: (v) {
                    _controller.toggleLayer('dims');
                    setState(() {});
                  },
                ),
                const Divider(),

                // --- BARU: OPSI UKURAN CANVAS ---
                ListTile(
                  leading: const Icon(Icons.aspect_ratio),
                  title: const Text("Ukuran Area Gambar"),
                  subtitle: Text(
                    "${_controller.canvasWidth.toInt()} x ${_controller.canvasHeight.toInt()} px",
                  ),
                  onTap: () {
                    Navigator.pop(ctx); // Tutup dialog setting dulu
                    _showCanvasResizer(context); // Buka dialog resize
                  },
                  trailing: const Icon(Icons.edit, size: 16),
                ),
                const Divider(),

                // ------------------------------------
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
                          ]
                          .map(
                            (c) => InkWell(
                              onTap: () {
                                _controller.setCanvasColor(c);
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  border: Border.all(color: Colors.grey),
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

  // ===============================================================
  // 2. MANAJEMEN LANTAI
  // ===============================================================
  void _showFloorManager() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Kelola Lantai"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _controller.floors.length,
                itemBuilder: (c, i) {
                  final floor = _controller.floors[i];
                  final isActive = i == _controller.activeFloorIndex;
                  return ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isActive ? Colors.blue : Colors.grey,
                    ),
                    title: Text(
                      floor.name,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () {
                        final ctrl = TextEditingController(text: floor.name);
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("Ganti Nama Lantai"),
                            content: TextField(controller: ctrl),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  _controller.renameActiveFloor(
                                    ctrl.text,
                                  ); // Logic rename perlu disesuaikan utk target index, tapi utk MVP rename active ok
                                  Navigator.pop(c);
                                  setState(() {});
                                },
                                child: const Text("Simpan"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      _controller.setActiveFloor(i);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            actions: [
              if (_controller.floors.length > 1)
                TextButton(
                  onPressed: () {
                    _controller.removeActiveFloor();
                    Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("Hapus Lantai Ini"),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Tambah Lantai"),
                onPressed: () {
                  _controller.addFloor();
                  setState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ===============================================================
  // 3. INFO & EDIT DIALOGS
  // ===============================================================
  void _showViewModeInfo(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'],
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(data['type']),
              backgroundColor: Colors.blue.shade50,
            ),
            const Divider(height: 24),
            const Text(
              "Keterangan:",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              (data['desc'] != null && data['desc'].isNotEmpty)
                  ? data['desc']
                  : "Tidak ada deskripsi.",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    final data = _controller.getSelectedItemData();
    if (data == null) return;

    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['desc']);
    final bool isPath = data['isPath'] ?? false;
    final bool isLabel = data['type'] == 'Label';

    // Navigasi state
    String? selectedNavFloorId = data['nav'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit ${data['type']}'),
          content: SingleChildScrollView(
            child: Column(
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

                if (data['type'] == 'Interior') ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Aksi Navigasi (Mode Lihat)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Tidak ada aksi"),
                    value: selectedNavFloorId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text("Tidak ada aksi"),
                      ),
                      ..._controller.floors.map(
                        (f) => DropdownMenuItem(
                          value: f.id,
                          child: Text("Pindah ke: ${f.name}"),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => selectedNavFloorId = v),
                  ),
                ],

                if (isPath) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text("Simpan ke Pustaka Saya"),
                    onPressed: () {
                      _controller.updateSelectedAttribute(
                        desc: descCtrl.text,
                        name: titleCtrl.text,
                      );
                      _controller.saveCurrentSelectionToLibrary();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Disimpan ke Pustaka!")),
                      );
                    },
                  ),
                ],
              ],
            ),
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
                _controller.updateSelectedAttribute(
                  desc: descCtrl.text,
                  name: titleCtrl.text,
                  navTarget: selectedNavFloorId,
                );
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // 4. PICKERS (COLOR & INTERIOR)
  // ===============================================================
  void _showColorPicker(BuildContext context, Function(Color) onColorSelected) {
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
                          color: Colors.grey.shade300,
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
                            {'icon': Icons.bed, 'name': 'Kasur'},
                            {'icon': Icons.single_bed, 'name': 'Single Bed'},
                            {'icon': Icons.weekend, 'name': 'Sofa'},
                            {'icon': Icons.event_seat, 'name': 'Bangku'},
                            {'icon': Icons.desk, 'name': 'Meja Kerja'},
                            {'icon': Icons.shelves, 'name': 'Rak Buku'},
                            {'icon': Icons.kitchen, 'name': 'Kulkas'},
                            {'icon': Icons.inventory_2, 'name': 'Lemari'},
                          ]),
                          _buildIconGrid([
                            {'icon': Icons.tv, 'name': 'TV'},
                            {'icon': Icons.computer, 'name': 'PC'},
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
                            {'icon': Icons.door_front_door, 'name': 'Pintu'},
                            {'icon': Icons.door_sliding, 'name': 'Geser'},
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
                            {'icon': Icons.checkroom, 'name': 'Gantung'},
                            {'icon': Icons.palette, 'name': 'Lukisan'},
                            {'icon': Icons.fitness_center, 'name': 'Gym'},
                            {'icon': Icons.pool, 'name': 'Kolam'},
                            {'icon': Icons.directions_car, 'name': 'Mobil'},
                          ]),
                          // CUSTOM LIBRARY
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
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.brown.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.brush,
                                          color: Colors.brown,
                                        ),
                                      ),
                                      title: Text(path.name),
                                      subtitle: Text(
                                        path.description,
                                        maxLines: 1,
                                      ),
                                      onTap: () {
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
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            _controller.selectObjectIcon(item['icon'], item['name']);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(item['icon'], color: Colors.black87, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                item['name'],
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // ===============================================================
  // 5. HELPERS (EXPORT & TAP)
  // ===============================================================
  Future<void> _exportImage() async {
    if (AppSettings.exportPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Atur folder export di Pengaturan dulu.")),
      );
      return;
    }
    try {
      final recorder = ui.PictureRecorder();
      // --- MODIFIED: Gunakan ukuran canvas dinamis untuk export ---
      final exportSize = Size(
        _controller.canvasWidth,
        _controller.canvasHeight,
      );
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
      );
      canvas.drawRect(
        Rect.fromLTWH(0, 0, exportSize.width, exportSize.height),
        Paint()..color = _controller.canvasColor,
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
            'plan_${now.year}${now.month}${now.day}_${now.hour}${now.minute}${now.second}.png';
        final file = File(p.join(AppSettings.exportPath!, fileName));
        await file.writeAsBytes(pngBytes.buffer.asUint8List());
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Disimpan: ${file.path}"),
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
    if (_controller.activeTool == PlanTool.text && !_controller.isViewMode) {
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
                if (textCtrl.text.isNotEmpty)
                  _controller.addLabel(localPos, textCtrl.text);
                Navigator.pop(ctx);
              },
              child: const Text("Tambah"),
            ),
          ],
        ),
      );
    } else {
      _controller.onTapUp(localPos);
      if (_controller.isViewMode && _controller.selectedId != null) {
        final data = _controller.getSelectedItemData();
        if (data != null) _showViewModeInfo(data);
      }
    }
  }

  // ===============================================================
  // MAIN BUILD
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final bool isView = _controller.isViewMode;
        final bool isHand = _controller.activeTool == PlanTool.hand;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(
                  isView ? "Mode Lihat" : "Arsitek Denah",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  _controller.activeFloor.name,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            backgroundColor: isView ? Colors.white : null,
            elevation: isView ? 1 : 4,
            actions: [
              // Floor Switcher
              TextButton.icon(
                icon: const Icon(Icons.layers),
                label: const Text("Lantai"),
                onPressed: _showFloorManager,
              ),
              // Toggle View
              IconButton(
                icon: Icon(isView ? Icons.edit : Icons.visibility),
                tooltip: isView ? "Kembali ke Edit" : "Mode Presentasi",
                onPressed: _controller.toggleViewMode,
              ),
              // Settings
              IconButton(
                icon: const Icon(Icons.settings_display),
                tooltip: "Layer & Tampilan",
                onPressed: () => _showLayerSettings(context),
              ),
              if (!isView) ...[
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: "Export",
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
                        'Hapus Semua',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: Column(
            children: [
              // --- TOOLBAR UTAMA (Hidden di View Mode) ---
              if (!isView)
                Container(
                  color: Colors.grey.shade100,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
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
                              icon: Icons.pan_tool_alt,
                              label: "Geser",
                              isActive: _controller.activeTool == PlanTool.hand,
                              onTap: () => _controller.setTool(PlanTool.hand),
                            ),
                            const SizedBox(width: 8),
                            _buildToolBtn(
                              icon: Icons.pan_tool,
                              label: "Pilih",
                              isActive:
                                  _controller.activeTool == PlanTool.select,
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
                              label: "Teks",
                              isActive: _controller.activeTool == PlanTool.text,
                              onTap: () => _controller.setTool(PlanTool.text),
                            ),
                            const SizedBox(width: 8),
                            _buildToolBtn(
                              icon: Icons.brush,
                              label: "Gambar",
                              isActive:
                                  _controller.activeTool == PlanTool.freehand,
                              onTap: () =>
                                  _controller.setTool(PlanTool.freehand),
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
                              onSelected: (type) =>
                                  _controller.selectShape(type),
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
                            InkWell(
                              onTap: () => _showInteriorPicker(context),
                              child: _buildToolBtn(
                                icon:
                                    _controller.selectedObjectIcon ??
                                    Icons.chair,
                                label: "Interior",
                                isActive:
                                    _controller.activeTool == PlanTool.object,
                                onTap: null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildToolBtn(
                              icon: Icons.delete_forever,
                              label: "Hapus",
                              isActive:
                                  _controller.activeTool == PlanTool.eraser,
                              iconColor: Colors.red,
                              onTap: () => _controller.setTool(PlanTool.eraser),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Atribut: ",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
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
                              onChanged: (v) =>
                                  _controller.setActiveStrokeWidth(v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // --- BAR SELEKSI ---
              if (!isView && _controller.selectedId != null)
                Container(
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
                              "${_controller.getSelectedItemData()?['title']} (${_controller.getSelectedItemData()?['type']})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showColorPicker(
                              context,
                              (c) =>
                                  _controller.updateSelectedAttribute(color: c),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.color_lens, color: Colors.blue),
                            ),
                          ),
                          if (_controller.getSelectedItemData()?['type'] ==
                                  'Struktur' ||
                              _controller.getSelectedItemData()?['type'] ==
                                  'Gambar')
                            SizedBox(
                              width: 80,
                              child: Slider(
                                value:
                                    (_controller
                                            .getSelectedItemData()?['type'] ==
                                        'Struktur')
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
                ),

              // --- Info Bar Khusus ---
              if (!isView && _controller.activeTool == PlanTool.eraser)
                Container(
                  color: Colors.red.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Mode Penghapus Aktif",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              if (!isView && _controller.activeTool == PlanTool.text)
                Container(
                  color: Colors.orange.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Ketuk di layar untuk menambah teks",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                ),

              // --- KANVAS ---
              Expanded(
                child: Stack(
                  children: [
                    InteractiveViewer(
                      transformationController: _controller.transformController,
                      panEnabled:
                          isHand || isView, // Pan hanya di mode Hand atau View
                      scaleEnabled: isHand || isView,
                      minScale: 0.1,
                      maxScale: 5.0,
                      child: GestureDetector(
                        onPanStart: (d) =>
                            _controller.onPanStart(d.localPosition),
                        onPanUpdate: (d) =>
                            _controller.onPanUpdate(d.localPosition),
                        onPanEnd: (d) => _controller.onPanEnd(),
                        onTapUp: (d) => _handleTapUp(d.localPosition),

                        // --- MODIFIED: Ukuran dinamis dari controller ---
                        child: Container(
                          width: _controller.canvasWidth,
                          height: _controller.canvasHeight,
                          color: Colors.grey.shade200, // Placeholder color
                          child: CustomPaint(
                            painter: PlanPainter(controller: _controller),
                          ),
                        ),
                      ),
                    ),
                    // Zoom Controls
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: "zi",
                            onPressed: _controller.zoomIn,
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "zo",
                            onPressed: _controller.zoomOut,
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: "zr",
                            onPressed: _controller.resetZoom,
                            child: const Icon(Icons.center_focus_strong),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
