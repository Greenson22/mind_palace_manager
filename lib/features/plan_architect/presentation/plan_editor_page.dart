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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Fitur simpan JSON (Tahap Selanjutnya)"),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- TOOLBAR ---
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(8),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolBtn(
                      icon: Icons.pan_tool,
                      label: "Pilih/Edit",
                      isActive: _controller.activeTool == PlanTool.select,
                      onTap: () => _controller.setTool(PlanTool.select),
                    ),
                    _buildToolBtn(
                      icon: Icons.format_paint,
                      label: "Tembok",
                      isActive: _controller.activeTool == PlanTool.wall,
                      onTap: () => _controller.setTool(PlanTool.wall),
                    ),
                    // Object Menu
                    PopupMenuButton<Map<String, dynamic>>(
                      child: _buildToolBtn(
                        icon: _controller.selectedObjectIcon ?? Icons.chair,
                        label: "Interior",
                        isActive: _controller.activeTool == PlanTool.object,
                        onTap: null, // Handled by popup
                      ),
                      onSelected: (val) {
                        _controller.selectObjectIcon(val['icon'], val['name']);
                      },
                      itemBuilder: (ctx) => [
                        _buildPopupItem(Icons.chair, "Kursi"),
                        _buildPopupItem(Icons.table_bar, "Meja"),
                        _buildPopupItem(Icons.bed, "Kasur"),
                        _buildPopupItem(Icons.door_front_door, "Pintu"),
                        _buildPopupItem(Icons.kitchen, "Kulkas"),
                        _buildPopupItem(Icons.tv, "TV"),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // --- INFO BAR ---
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
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Edit"),
                        onPressed: _showEditDialog,
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
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
                color: Colors.white, // Canvas Background
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.black87),
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
