import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahkan intl di pubspec.yaml
import 'package:mind_palace_manager/features/settings/logic/backup_logic.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final BackupLogic _logic = BackupLogic();
  List<BackupInfo> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  Future<void> _refreshList() async {
    setState(() => _isLoading = true);
    try {
      final list = await _logic.loadBackups();
      setState(() => _backups = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    // Delay sedikit agar UI loading muncul
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await _logic.createBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Backup berhasil dibuat!"),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _refreshList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat backup: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(BackupInfo info) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Restore Backup?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PERINGATAN: Tindakan ini akan MENGHAPUS semua data saat ini dan menggantinya dengan data dari backup.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("File: ${info.fileName}"),
            Text(
              "Tanggal: ${DateFormat('dd MMM yyyy HH:mm').format(info.date)}",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Ya, Restore & Timpa"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500)); // UX Delay
      try {
        await _logic.restoreBackup(info.path);
        if (mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text("Restore Berhasil"),
              content: const Text(
                "Aplikasi perlu direstart atau kembali ke dashboard agar data termuat ulang dengan benar.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(c);
                    Navigator.pop(context); // Kembali ke settings
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal restore: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBackup(BackupInfo info) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Hapus File Backup?"),
        content: Text(info.fileName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logic.deleteBackup(info.path);
      _refreshList();
    }
  }

  Future<void> _exportBackup(BackupInfo info) async {
    try {
      final dest = await _logic.exportBackupToDevice(info.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Disimpan ke: $dest"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Cancelled or error
    }
  }

  Future<void> _importExternal() async {
    await _logic.importExternalBackup();
    _refreshList();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backup & Restore"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: "Import Backup Eksternal",
            onPressed: _importExternal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Backup menyimpan seluruh data wilayah, bangunan, dan gambar. Simpan file ZIP di tempat aman.",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text("Belum ada backup tersimpan."),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _backups.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = _backups[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: index == 0
                                ? Colors.green.shade100
                                : Colors.blue.shade50,
                            child: Icon(
                              Icons.inventory_2,
                              color: index == 0 ? Colors.green : Colors.blue,
                            ),
                          ),
                          title: Text(
                            DateFormat('dd MMMM yyyy, HH:mm').format(item.date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${_formatBytes(item.sizeBytes)} • v${item.appVersion}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  _StatBadge(
                                    icon: Icons.public,
                                    label: "${item.regionCount} Wilayah",
                                  ),
                                  const SizedBox(width: 12),
                                  _StatBadge(
                                    icon: Icons.location_city,
                                    label: "${item.buildingCount} Bangunan",
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text("Export"),
                                  onPressed: () => _exportBackup(item),
                                ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.restore,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  label: const Text(
                                    "Restore",
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                  onPressed: () => _restoreBackup(item),
                                ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    "Hapus",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () => _deleteBackup(item),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _createBackup,
        icon: const Icon(Icons.save),
        label: const Text("Buat Backup Baru"),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }
}
