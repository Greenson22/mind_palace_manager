import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class BuildingListItem extends StatelessWidget {
  final Directory buildingFolder;
  final Future<Map<String, dynamic>> iconDataFuture;
  final Function(String action) onActionSelected;
  final VoidCallback onTap;

  const BuildingListItem({
    super.key,
    required this.buildingFolder,
    required this.iconDataFuture,
    required this.onActionSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final folderName = p.basename(buildingFolder.path);

    return ListTile(
      leading: FutureBuilder<Map<String, dynamic>>(
        future: iconDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _buildIconContainer(
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final type = snapshot.data!['type'];
          final data = snapshot.data!['data'];
          final imageFile = snapshot.data!['file'] as File?;

          if (type == 'text' && data != null) {
            return _buildIconContainer(
              Text(
                data.toString(),
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (type == 'image' && imageFile != null) {
            return _buildIconContainer(null, imageFile: imageFile);
          }
          return _buildIconContainer(const Icon(Icons.location_city));
        },
      ),
      title: Text(folderName, style: const TextStyle(fontSize: 18)),
      subtitle: Text(buildingFolder.path, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: onActionSelected,
        itemBuilder: (c) => [
          const PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility),
                SizedBox(width: 8),
                Text('Lihat / Masuk'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit_room',
            child: Row(
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Edit Ruangan'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'move',
            child: Row(
              children: [
                Icon(Icons.drive_file_move, color: Colors.orange),
                SizedBox(width: 8),
                Text('Pindahkan'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'retract',
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Simpan ke Bank'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit_info',
            child: Row(
              children: [
                Icon(Icons.palette_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Ubah Info'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'export_icon',
            child: Row(
              children: [
                Icon(Icons.ios_share, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Export Ikon'),
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
                Text('Hapus'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer(Widget? child, {File? imageFile}) {
    double size = 40.0;
    switch (AppSettings.listIconShape) {
      case 'Bulat':
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: imageFile != null ? FileImage(imageFile) : null,
          child: imageFile == null ? child : null,
        );
      case 'Kotak':
        return Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: imageFile == null ? Colors.grey.shade200 : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: imageFile != null
              ? Image.file(imageFile, fit: BoxFit.cover)
              : Center(child: child),
        );
      default:
        return SizedBox(
          width: size,
          height: size,
          child: imageFile != null
              ? Image.file(imageFile, fit: BoxFit.contain)
              : Center(child: child),
        );
    }
  }
}
