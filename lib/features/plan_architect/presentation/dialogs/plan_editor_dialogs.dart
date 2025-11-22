// lib/features/plan_architect/presentation/dialogs/plan_editor_dialogs.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/plan_architect/logic/plan_controller.dart';
import 'package:mind_palace_manager/features/plan_architect/data/plan_models.dart';

class PlanEditorDialogs {
  // --- PALET WARNA ---
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
  ];

  // FUNGSI showCanvasResizer DIHAPUS KARENA CANVAS SUDAH INFINITE/FIXED

  static void showLayerSettings(
    BuildContext context,
    PlanController controller,
  ) {
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

                // --- BAGIAN RESIZE CANVAS DIHAPUS DI SINI ---
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

  static void showFloorManager(
    BuildContext context,
    PlanController controller,
  ) {
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
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
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
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
            ElevatedButton(
              onPressed: () {
                controller.updateSelectedAttribute(
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

  static void showInteriorPicker(
    BuildContext context,
    PlanController controller,
  ) {
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
                          _buildIconGrid(context, controller, [
                            {'icon': Icons.chair, 'name': 'Kursi'},
                            {'icon': Icons.table_bar, 'name': 'Meja'},
                            {'icon': Icons.bed, 'name': 'Kasur'},
                            {'icon': Icons.weekend, 'name': 'Sofa'},
                          ]),
                          _buildIconGrid(context, controller, [
                            {'icon': Icons.tv, 'name': 'TV'},
                            {'icon': Icons.computer, 'name': 'PC'},
                          ]),
                          _buildIconGrid(context, controller, [
                            {'icon': Icons.bathtub, 'name': 'Bathtub'},
                            {'icon': Icons.wc, 'name': 'Toilet'},
                          ]),
                          _buildIconGrid(context, controller, [
                            {'icon': Icons.door_front_door, 'name': 'Pintu'},
                            {'icon': Icons.window, 'name': 'Jendela'},
                          ]),
                          _buildIconGrid(context, controller, [
                            {'icon': Icons.local_florist, 'name': 'Tanaman'},
                            {'icon': Icons.light, 'name': 'Lampu'},
                          ]),
                          controller.savedCustomInteriors.isEmpty
                              ? const Center(
                                  child: Text("Belum ada interior tersimpan."),
                                )
                              : ListView.builder(
                                  itemCount:
                                      controller.savedCustomInteriors.length,
                                  itemBuilder: (context, index) {
                                    final path =
                                        controller.savedCustomInteriors[index];
                                    return ListTile(
                                      leading: const Icon(Icons.brush),
                                      title: Text(path.name),
                                      onTap: () {
                                        final center = Offset(
                                          MediaQuery.of(context).size.width / 2,
                                          MediaQuery.of(context).size.height /
                                              3,
                                        );
                                        controller.placeSavedPath(path, center);
                                        Navigator.pop(context);
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

  static Widget _buildIconGrid(
    BuildContext context,
    PlanController controller,
    List<Map<String, dynamic>> items,
  ) {
    return GridView.builder(
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
            controller.selectObjectIcon(item['icon'], item['name']);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item['icon'], size: 28),
              Text(
                item['name'],
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  static void showViewModeInfo(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Chip(
              label: Text(data['type']),
              backgroundColor: Colors.blue.shade50,
            ),
            const Divider(height: 24),
            Text(
              (data['desc'] != null && data['desc'].isNotEmpty)
                  ? data['desc']
                  : "Tidak ada deskripsi.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
