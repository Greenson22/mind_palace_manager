// lib/features/building/presentation/editor/room_editor_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

// Imports dari file yang baru dibuat
import 'logic/room_editor_logic.dart';
import 'dialogs/room_management_dialogs.dart';
import 'dialogs/ai_visual_architect_dialog.dart';

// Import viewer untuk navigasi (opsional, jika ada fitur test view)
import 'package:mind_palace_manager/features/building/presentation/viewer/building_viewer_page.dart';

class RoomEditorPage extends StatefulWidget {
  final Directory buildingDirectory;
  const RoomEditorPage({super.key, required this.buildingDirectory});

  @override
  State<RoomEditorPage> createState() => _RoomEditorPageState();
}

class _RoomEditorPageState extends State<RoomEditorPage> {
  late RoomEditorLogic _logic;
  bool _isLoading = true;
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _logic = RoomEditorLogic(widget.buildingDirectory);
    _init();
  }

  Future<void> _init() async {
    await _logic.loadData();
    if (mounted) setState(() => _isLoading = false);
  }

  // --- UI Handlers (Menghubungkan Dialog dengan Logic) ---

  void _showAiDialog() {
    showDialog(
      context: context,
      builder: (c) =>
          AiVisualArchitectDialog(buildingDirectory: widget.buildingDirectory),
    );
  }

  void _onAddRoomPressed() {
    RoomManagementDialogs.showAddRoom(context, (name, path) async {
      setState(() => _isLoading = true);
      await _logic.addRoom(name, path);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ruangan "$name" dibuat')));
      }
    });
  }

  void _onEditRoomPressed(Map<String, dynamic> room) {
    RoomManagementDialogs.showEditRoom(context, room, (newName, newPath) async {
      setState(() => _isLoading = true);
      await _logic.updateRoom(room, newName, newPath);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ruangan diperbarui')));
      }
    });
  }

  void _onNavPressed(Map<String, dynamic> room) {
    RoomManagementDialogs.showNavigationDialog(
      context,
      room,
      _logic.rooms,
      onAdd: (conn) async {
        await _logic.addConnection(room, conn);
        setState(() {});
      },
      onEditLabel: (conn, label) async {
        await _logic.updateConnectionLabel(conn, label);
        setState(() {});
      },
      onDelete: (conn) async {
        await _logic.removeConnection(room, conn);
        setState(() {});
      },
      onOfferReturn: (targetId) {
        _offerReturnNav(room, targetId);
      },
    );
  }

  Future<void> _offerReturnNav(
    Map<String, dynamic> fromRoom,
    String targetId,
  ) async {
    // Dialog konfirmasi sederhana untuk navigasi balik
    bool confirm =
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Buat Jalan Balik?"),
            content: Text(
              "Otomatis buat pintu dari ruangan tujuan kembali ke ${fromRoom['name']}?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text("Tidak"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text("Ya"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _logic.createReturnConnection(
        fromRoom['id'],
        fromRoom['name'],
        targetId,
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Navigasi balik dibuat.")));
    }
  }

  void _onDeletePressed(Map<String, dynamic> room) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Hapus Ruangan?"),
            content: Text("Hapus '${room['name']}' beserta isinya?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(c, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _logic.deleteRoom(room['id']);
      setState(() {});
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Ruangan dihapus")));
    }
  }

  void _onExportPressed(Map<String, dynamic> room) async {
    bool success = await _logic.exportRoomImage(room);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gambar diexport ke folder Export")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal export (Tidak ada gambar/folder belum diatur)",
            ),
          ),
        );
      }
    }
  }

  // --- Main Widget ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${p.basename(widget.buildingDirectory.path)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
            tooltip: "AI Visual Architect",
            onPressed: _showAiDialog,
          ),
          IconButton(
            icon: Icon(_isReorderMode ? Icons.link : Icons.swap_vert),
            tooltip: _isReorderMode ? "Mode Navigasi/Edit" : "Mode Urutkan",
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddRoomPressed,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logic.rooms.isEmpty
          ? const Center(
              child: Text("Belum ada ruangan.\nTekan + untuk membuat."),
            )
          : ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: _logic.rooms.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  _logic.reorderRooms(oldIdx, newIdx);
                });
              },
              itemBuilder: (context, index) {
                final room = _logic.rooms[index];
                final imagePath = room['image'];

                return ListTile(
                  key: ValueKey(room['id']),
                  leading: imagePath != null
                      ? Image.file(
                          File(
                            p.join(widget.buildingDirectory.path, imagePath),
                          ),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.meeting_room,
                          size: 40,
                          color: Colors.grey,
                        ),
                  title: Text(room['name'] ?? 'Tanpa Nama'),

                  // Tap untuk masuk ke Viewer
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

                  // Trailing: Drag Handle atau Menu
                  trailing: _isReorderMode
                      ? ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        )
                      : PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'nav') _onNavPressed(room);
                            if (val == 'edit') _onEditRoomPressed(room);
                            if (val == 'export') _onExportPressed(room);
                            if (val == 'delete') _onDeletePressed(room);
                          },
                          itemBuilder: (c) => [
                            const PopupMenuItem(
                              value: 'nav',
                              child: Row(
                                children: [
                                  Icon(Icons.link, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Atur Navigasi'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text('Ubah Info'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'export',
                              child: Row(
                                children: [
                                  Icon(Icons.image, color: Colors.teal),
                                  SizedBox(width: 8),
                                  Text('Export Gambar'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hapus',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
