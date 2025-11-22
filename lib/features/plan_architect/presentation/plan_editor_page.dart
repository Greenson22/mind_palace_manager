// lib/features/plan_architect/presentation/plan_editor_page.dart
import 'package:flutter/material.dart';
import '../logic/plan_controller.dart';
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

  // ... (Metode _showEditDialog SAMA SEPERTI SEBELUMNYA, tidak diubah) ...
  void _showEditDialog() {
    final data = _controller.getSelectedItemData();
    if (data == null) return;

    final titleCtrl = TextEditingController(text: data['title']);
    final descCtrl = TextEditingController(text: data['desc']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${data['type']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_controller.isObjectSelected)
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Nama Interior'),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Deskripsi / Keterangan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
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
                newName: _controller.isObjectSelected ? titleCtrl.text : null,
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
          // Tombol UNDO
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return IconButton(
                icon: const Icon(Icons.undo),
                onPressed: _controller.canUndo ? _controller.undo : null,
                tooltip: "Undo",
              );
            },
          ),
          // Tombol REDO
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return IconButton(
                icon: const Icon(Icons.redo),
                onPressed: _controller.canRedo ? _controller.redo : null,
                tooltip: "Redo",
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // --- TOOLBAR ---
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: SingleChildScrollView(
              // Tambah scroll jika layar sempit
              scrollDirection: Axis.horizontal,
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    children: [
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
                      // Tombol Custom Interior (Freehand)
                      _buildToolBtn(
                        icon: Icons.brush,
                        label: "Gambar",
                        isActive: _controller.activeTool == PlanTool.freehand,
                        onTap: () => _controller.setTool(PlanTool.freehand),
                      ),
                      const SizedBox(width: 8),
                      // Object Menu
                      PopupMenuButton<Map<String, dynamic>>(
                        child: _buildToolBtn(
                          icon: _controller.selectedObjectIcon ?? Icons.chair,
                          label: "Furnitur",
                          isActive: _controller.activeTool == PlanTool.object,
                          onTap: null,
                        ),
                        onSelected: (val) {
                          _controller.selectObjectIcon(
                            val['icon'],
                            val['name'],
                          );
                        },
                        itemBuilder: (ctx) => [
                          _buildPopupItem(Icons.chair, "Kursi"),
                          _buildPopupItem(Icons.table_bar, "Meja"),
                          _buildPopupItem(Icons.bed, "Kasur"),
                          _buildPopupItem(Icons.door_front_door, "Pintu"),
                          _buildPopupItem(Icons.kitchen, "Kulkas"),
                          _buildPopupItem(Icons.tv, "TV"),
                          _buildPopupItem(Icons.wc, "Toilet"),
                          _buildPopupItem(Icons.local_florist, "Tanaman"),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Tombol Penghapus (Toggle Delete)
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

          // --- INFO BAR (Edit Panel) ---
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.selectedId != null) {
                final data = _controller.getSelectedItemData();
                return Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data?['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              data?['desc'] ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Detail"),
                        onPressed: _showEditDialog,
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Info saat mode Penghapus aktif
              if (_controller.activeTool == PlanTool.eraser) {
                return Container(
                  color: Colors.red.shade50,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "Mode Penghapus: Ketuk objek/tembok untuk menghapus.",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // --- CANVAS ---
          Expanded(
            child: GestureDetector(
              onPanStart: (d) => _controller.onPanStart(d.localPosition),
              onPanUpdate: (d) => _controller.onPanUpdate(d.localPosition),
              onPanEnd: (d) => _controller.onPanEnd(),
              onTapUp: (d) => _controller.onTapUp(d.localPosition),
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
