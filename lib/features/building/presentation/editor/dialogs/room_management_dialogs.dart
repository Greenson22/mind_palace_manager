// lib/features/building/presentation/editor/dialogs/room_management_dialogs.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class RoomManagementDialogs {
  /// Dialog untuk menambah ruangan baru
  static Future<void> showAddRoom(
    BuildContext context,
    Function(String name, String? path) onConfirm,
  ) async {
    final nameCtrl = TextEditingController();
    String? pickedPath;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Buat Ruangan Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'Nama Ruangan'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
                onPressed: () async {
                  var res = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );
                  if (res != null) {
                    setState(() => pickedPath = res.files.single.path);
                  }
                },
              ),
              if (pickedPath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "File: ${p.basename(pickedPath!)}",
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  onConfirm(nameCtrl.text.trim(), pickedPath);
                  Navigator.pop(c);
                }
              },
              child: const Text('Buat'),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog untuk mengedit nama atau gambar ruangan
  static Future<void> showEditRoom(
    BuildContext context,
    Map<String, dynamic> room,
    Function(String newName, String? newPath) onConfirm,
  ) async {
    final nameCtrl = TextEditingController(text: room['name']);
    String? pickedPath;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) {
          String status = room['image'] == null
              ? 'Tidak ada gambar'
              : 'Gambar saat ini tersimpan';
          if (pickedPath == 'DELETE_IMAGE')
            status = 'Gambar akan dihapus';
          else if (pickedPath != null)
            status = 'Gambar baru dipilih: ${p.basename(pickedPath!)}';

          return AlertDialog(
            title: const Text('Edit Ruangan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Ruangan'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Ganti'),
                        onPressed: () async {
                          var res = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                          );
                          if (res != null)
                            setState(() => pickedPath = res.files.single.path);
                        },
                      ),
                    ),
                    if (room['image'] != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Hapus Gambar",
                        onPressed: () =>
                            setState(() => pickedPath = 'DELETE_IMAGE'),
                      ),
                    ],
                  ],
                ),
                Text(
                  status,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    onConfirm(nameCtrl.text.trim(), pickedPath);
                    Navigator.pop(c);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Dialog Manajemen Navigasi (Link antar ruangan)
  static Future<void> showNavigationDialog(
    BuildContext context,
    Map<String, dynamic> fromRoom,
    List<dynamic> allRooms, {
    required Function(Map<String, dynamic> conn) onAdd,
    required Function(Map<String, dynamic> conn, String newLabel) onEditLabel,
    required Function(Map<String, dynamic> conn) onDelete,
    required Function(String targetId) onOfferReturn,
  }) async {
    final labelCtrl = TextEditingController();
    String? selectedTargetId;

    // Filter agar tidak menautkan ke diri sendiri
    final targets = allRooms.where((r) => r['id'] != fromRoom['id']).toList();
    // List koneksi saat ini
    final connections = fromRoom['connections'] as List;

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Navigasi: ${fromRoom['name']}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Daftar Pintu/Link:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (connections.isEmpty)
                    const Text(
                      "Belum ada navigasi.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  ...connections.map((conn) {
                    final target = allRooms.firstWhere(
                      (r) => r['id'] == conn['targetRoomId'],
                      orElse: () => {'name': 'Ruangan Terhapus'},
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        title: Text("Ke: ${target['name']}"),
                        subtitle: Text("Label: ${conn['label']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orange,
                                size: 20,
                              ),
                              onPressed: () async {
                                final editCtrl = TextEditingController(
                                  text: conn['label'],
                                );
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text("Edit Label Tombol"),
                                    content: TextField(
                                      controller: editCtrl,
                                      autofocus: true,
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () {
                                          onEditLabel(conn, editCtrl.text);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("Simpan"),
                                      ),
                                    ],
                                  ),
                                );
                                setState(() {}); // Refresh list
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                onDelete(conn);
                                setState(() {}); // Refresh list
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Divider(height: 24),
                  const Text(
                    'Tambah Link Baru:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    hint: const Text("Pilih Ruangan Tujuan"),
                    value: selectedTargetId,
                    isExpanded: true,
                    items: targets
                        .map<DropdownMenuItem<String>>(
                          (r) => DropdownMenuItem(
                            value: r['id'],
                            child: Text(r['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedTargetId = v),
                  ),
                  TextField(
                    controller: labelCtrl,
                    decoration: const InputDecoration(
                      labelText: "Label Tombol (Opsional)",
                      hintText: "Biarkan kosong untuk pakai nama ruangan",
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Selesai'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedTargetId != null) {
                  final target = targets.firstWhere(
                    (r) => r['id'] == selectedTargetId,
                  );
                  final label = labelCtrl.text.trim().isEmpty
                      ? target['name']
                      : labelCtrl.text.trim();

                  // Panggil callback tambah
                  onAdd({
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'label': label,
                    'targetRoomId': selectedTargetId,
                    'direction': 'up',
                    'x': 0.5,
                    'y': 0.5,
                  });

                  // Tawarkan navigasi balik
                  onOfferReturn(selectedTargetId!);

                  // Reset Form
                  labelCtrl.clear();
                  selectedTargetId = null;
                  setState(() {});
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}
