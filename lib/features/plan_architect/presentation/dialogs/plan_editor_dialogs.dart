// lib/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';

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

  // --- DATABASE INTERIOR ---
  static final List<Map<String, dynamic>> _allInteriors = [
    // Furnitur
    {'icon': Icons.chair, 'name': 'Kursi', 'cat': 'Furnitur'},
    {'icon': Icons.chair_alt, 'name': 'Kursi Kayu', 'cat': 'Furnitur'},
    {'icon': Icons.table_bar, 'name': 'Meja', 'cat': 'Furnitur'},
    {'icon': Icons.table_restaurant, 'name': 'Meja Makan', 'cat': 'Furnitur'},
    {'icon': Icons.desk, 'name': 'Meja Kerja', 'cat': 'Furnitur'},
    {'icon': Icons.bed, 'name': 'Kasur', 'cat': 'Furnitur'},
    {'icon': Icons.single_bed, 'name': 'Kasur Single', 'cat': 'Furnitur'},
    {'icon': Icons.king_bed, 'name': 'Kasur King', 'cat': 'Furnitur'},
    {'icon': Icons.weekend, 'name': 'Sofa', 'cat': 'Furnitur'},
    {'icon': Icons.chair_outlined, 'name': 'Sofa 1', 'cat': 'Furnitur'},
    {'icon': Icons.shelves, 'name': 'Rak Buku', 'cat': 'Furnitur'},
    {'icon': Icons.kitchen, 'name': 'Lemari', 'cat': 'Furnitur'},
    {'icon': Icons.door_sliding, 'name': 'Lemari Geser', 'cat': 'Furnitur'},
    {'icon': Icons.inventory_2, 'name': 'Laci', 'cat': 'Furnitur'},
    {'icon': Icons.event_seat, 'name': 'Bangku', 'cat': 'Furnitur'},

    // Elektronik
    {'icon': Icons.tv, 'name': 'TV', 'cat': 'Elektronik'},
    {'icon': Icons.desktop_windows, 'name': 'PC', 'cat': 'Elektronik'},
    {'icon': Icons.laptop, 'name': 'Laptop', 'cat': 'Elektronik'},
    {'icon': Icons.kitchen, 'name': 'Kulkas', 'cat': 'Elektronik'},
    {'icon': Icons.microwave, 'name': 'Microwave', 'cat': 'Elektronik'},
    {
      'icon': Icons.local_laundry_service,
      'name': 'Mesin Cuci',
      'cat': 'Elektronik',
    },
    {'icon': Icons.ac_unit, 'name': 'AC', 'cat': 'Elektronik'},
    {'icon': Icons.mode_fan_off, 'name': 'Kipas', 'cat': 'Elektronik'},
    {'icon': Icons.speaker, 'name': 'Speaker', 'cat': 'Elektronik'},
    {'icon': Icons.router, 'name': 'Router', 'cat': 'Elektronik'},
    {'icon': Icons.print, 'name': 'Printer', 'cat': 'Elektronik'},
    {'icon': Icons.phone_android, 'name': 'HP', 'cat': 'Elektronik'},
    {'icon': Icons.camera_alt, 'name': 'Kamera', 'cat': 'Elektronik'},

    // Sanitasi
    {'icon': Icons.bathtub, 'name': 'Bathtub', 'cat': 'Sanitasi'},
    {'icon': Icons.wc, 'name': 'Toilet', 'cat': 'Sanitasi'},
    {'icon': Icons.wash, 'name': 'Wastafel', 'cat': 'Sanitasi'},
    {'icon': Icons.shower, 'name': 'Shower', 'cat': 'Sanitasi'},
    {'icon': Icons.water_drop, 'name': 'Keran', 'cat': 'Sanitasi'},
    {'icon': Icons.soap, 'name': 'Sabun', 'cat': 'Sanitasi'},
    {'icon': Icons.cleaning_services, 'name': 'Alat Pel', 'cat': 'Sanitasi'},

    // Struktur
    {'icon': Icons.door_front_door, 'name': 'Pintu', 'cat': 'Struktur'},
    {'icon': Icons.sensor_door, 'name': 'Pintu Masuk', 'cat': 'Struktur'},
    {'icon': Icons.window, 'name': 'Jendela', 'cat': 'Struktur'},
    {'icon': Icons.stairs, 'name': 'Tangga', 'cat': 'Struktur'},
    {'icon': Icons.elevator, 'name': 'Lift', 'cat': 'Struktur'},
    {'icon': Icons.fence, 'name': 'Pagar', 'cat': 'Struktur'},
    {'icon': Icons.garage, 'name': 'Garasi', 'cat': 'Struktur'},
    {'icon': Icons.view_column, 'name': 'Pilar', 'cat': 'Struktur'},
    {'icon': Icons.roofing, 'name': 'Atap', 'cat': 'Struktur'},
    {'icon': Icons.foundation, 'name': 'Fondasi', 'cat': 'Struktur'},

    // Dekorasi
    {'icon': Icons.local_florist, 'name': 'Tanaman', 'cat': 'Dekorasi'},
    {'icon': Icons.yard, 'name': 'Pot Bunga', 'cat': 'Dekorasi'},
    {'icon': Icons.light, 'name': 'Lampu', 'cat': 'Dekorasi'},
    {'icon': Icons.lightbulb, 'name': 'Bohlam', 'cat': 'Dekorasi'},
    {'icon': Icons.image, 'name': 'Lukisan', 'cat': 'Dekorasi'},
    {'icon': Icons.access_time, 'name': 'Jam', 'cat': 'Dekorasi'},
    {
      'icon': Icons.local_fire_department,
      'name': 'Perapian',
      'cat': 'Dekorasi',
    },
    {'icon': Icons.curtains, 'name': 'Gorden', 'cat': 'Dekorasi'},
    {'icon': Icons.palette, 'name': 'Palet Seni', 'cat': 'Dekorasi'},
    {'icon': Icons.music_note, 'name': 'Instrumen', 'cat': 'Dekorasi'},

    // Lainnya
    {'icon': Icons.directions_car, 'name': 'Mobil', 'cat': 'Lainnya'},
    {'icon': Icons.pedal_bike, 'name': 'Sepeda', 'cat': 'Lainnya'},
    {'icon': Icons.motorcycle, 'name': 'Motor', 'cat': 'Lainnya'},
    {'icon': Icons.fitness_center, 'name': 'Gym', 'cat': 'Lainnya'},
    {'icon': Icons.restaurant_menu, 'name': 'Alat Makan', 'cat': 'Lainnya'},
    {'icon': Icons.build, 'name': 'Perkakas', 'cat': 'Lainnya'},
    {'icon': Icons.shopping_cart, 'name': 'Belanjaan', 'cat': 'Lainnya'},
    {'icon': Icons.pets, 'name': 'Hewan', 'cat': 'Lainnya'},
    {'icon': Icons.coffee, 'name': 'Kopi', 'cat': 'Lainnya'},
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

  static void showFloorManager(
    BuildContext context,
    PlanController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
                itemCount: controller.floors.length,
                itemBuilder: (c, i) {
                  final floor = controller.floors[i];
                  final isActive = i == controller.activeFloorIndex;
                  return ListTile(
                    leading: Icon(
                      isActive
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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
                                  controller.renameActiveFloor(ctrl.text);
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
                      controller.setActiveFloor(i);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            actions: [
              if (controller.floors.length > 1)
                TextButton(
                  onPressed: () {
                    controller.removeActiveFloor();
                    Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text("Hapus Lantai Ini"),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Tambah Lantai"),
                onPressed: () {
                  controller.addFloor();
                  setState(() {});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static void showEditDialog(BuildContext context, PlanController controller) {
    final data = controller.getSelectedItemData();
    if (data == null) return;

    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['desc']);
    final bool isPath = data['isPath'] ?? false;
    final bool isLabel = data['type'] == 'Label';
    final bool isWall = data['type'] == 'Struktur';
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
                      ...controller.floors.map(
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
                );

                if (isWall && lengthCtrl != null) {
                  final newLen = double.tryParse(
                    lengthCtrl.text.replaceAll(',', '.'),
                  );
                  if (newLen != null && newLen > 0) {
                    controller.updateSelectedWallLength(newLen);
                  }
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

  // --- PERBAIKAN UTAMA: FITUR PENCARIAN INTERIOR ---
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
            return _InteriorPickerSheet(
              controller: controller,
              scrollController: scrollController,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }

  // ... (Helper icon grid moved into _InteriorPickerSheet logic)

  static void showViewModeInfo(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

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

// --- INTERNAL WIDGET UNTUK PENCARIAN INTERIOR ---
class _InteriorPickerSheet extends StatefulWidget {
  final PlanController controller;
  final ScrollController scrollController;
  final ColorScheme colorScheme;

  const _InteriorPickerSheet({
    required this.controller,
    required this.scrollController,
    required this.colorScheme,
  });

  @override
  State<_InteriorPickerSheet> createState() => _InteriorPickerSheetState();
}

class _InteriorPickerSheetState extends State<_InteriorPickerSheet> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    return PlanEditorDialogs._allInteriors
        .where((item) => item['name'].toLowerCase().contains(query))
        .toList();
  }

  List<Map<String, dynamic>> _getItemsByCategory(String category) {
    return PlanEditorDialogs._allInteriors
        .where((item) => item['cat'] == category)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchQuery.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari interior (cth: Kursi, TV)...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: widget.colorScheme.surfaceContainerHighest,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          Expanded(
            child: isSearching
                ? _buildSearchResults()
                : DefaultTabController(
                    length: 6,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          labelColor: widget.colorScheme.primary,
                          unselectedLabelColor:
                              widget.colorScheme.onSurfaceVariant,
                          indicatorColor: widget.colorScheme.primary,
                          tabs: const [
                            Tab(text: "Furnitur"),
                            Tab(text: "Elektronik"),
                            Tab(text: "Sanitasi"),
                            Tab(text: "Struktur"),
                            Tab(text: "Dekorasi"),
                            Tab(text: "Lainnya"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildGrid(_getItemsByCategory('Furnitur')),
                              _buildGrid(_getItemsByCategory('Elektronik')),
                              _buildGrid(_getItemsByCategory('Sanitasi')),
                              _buildGrid(_getItemsByCategory('Struktur')),
                              _buildGrid(_getItemsByCategory('Dekorasi')),
                              _buildGrid(_getItemsByCategory('Lainnya')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _getFilteredItems();
    if (results.isEmpty) {
      return Center(
        child: Text(
          "Tidak ditemukan interior '$originalQuery'",
          style: TextStyle(color: widget.colorScheme.onSurfaceVariant),
        ),
      );
    }
    return _buildGrid(results);
  }

  String get originalQuery => _searchController.text;

  Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      controller:
          widget.scrollController, // Agar scroll smooth dengan bottom sheet
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            widget.controller.selectObjectIcon(item['icon'], item['name']);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 28, color: widget.colorScheme.onSurface),
              const SizedBox(height: 4),
              Text(
                item['name'],
                style: TextStyle(
                  fontSize: 11,
                  color: widget.colorScheme.onSurface,
                ),
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
}
