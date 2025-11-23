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

    // Bungkus seluruh ListTile dengan FutureBuilder
    return FutureBuilder<Map<String, dynamic>>(
      future: iconDataFuture,
      builder: (context, snapshot) {
        // Default values saat loading
        Widget leadingIcon = _buildIconContainer(
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
        String buildingType = 'standard';

        if (snapshot.hasData) {
          final type = snapshot.data!['type'];
          final data = snapshot.data!['data'];
          final imageFile = snapshot.data!['file'] as File?;
          buildingType = snapshot.data!['buildingType'] ?? 'standard';

          Widget? child;
          File? img;

          if (type == 'text' && data != null) {
            child = Text(
              data.toString(),
              style: const TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            );
          } else if (type == 'image' && imageFile != null) {
            img = imageFile;
          } else {
            child = Icon(
              buildingType == 'plan' ? Icons.architecture : Icons.location_city,
            );
          }
          leadingIcon = _buildIconContainer(child, imageFile: img);
        }

        return ListTile(
          leading: leadingIcon,
          title: Text(folderName, style: const TextStyle(fontSize: 18)),
          subtitle: Text(
            "${buildingFolder.path}\nTipe: ${buildingType == 'plan' ? 'Denah' : 'Ruangan'}",
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          onTap: onTap,
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: onActionSelected,
            itemBuilder: (c) {
              // --- LOGIKA MENU DINAMIS ---
              if (buildingType == 'plan') {
                // Menu Khusus Denah
                return [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Lihat Denah'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit_plan',
                    child: Row(
                      children: [
                        Icon(Icons.design_services),
                        SizedBox(width: 8),
                        Text('Edit Arsitektur'),
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
                ];
              } else {
                // Menu Standar (Building Biasa)
                return [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility),
                        SizedBox(width: 8),
                        Text('Masuk Ruangan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit_room',
                    child: Row(
                      children: [
                        Icon(Icons.dashboard_customize),
                        SizedBox(width: 8),
                        Text('Struktur Ruangan'),
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
                ];
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildIconContainer(Widget? child, {File? imageFile}) {
    double size = 40.0;
    switch (AppSettings.listIconShape) {
      case 'Bulat':
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: imageFile != null ? FileImage(imageFile) : null,
          onBackgroundImageError: imageFile != null
              ? (e, s) => const Icon(Icons.image_not_supported)
              : null,
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
              ? Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                )
              : Center(child: child),
        );
      case 'Tidak Ada (Tanpa Latar)':
      default:
        return SizedBox(
          width: size,
          height: size,
          child: imageFile != null
              ? Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) =>
                      const Center(child: Icon(Icons.image_not_supported)),
                )
              : Center(child: child),
        );
    }
  }
}
