// lib/features/settings/helpers/wallpaper_image_loader.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:convert';
import 'package:mind_palace_manager/app_settings.dart';

class ImageSourceInfo {
  final String path;
  final String label;
  final String? buildingPath;
  ImageSourceInfo(this.path, this.label, {this.buildingPath});
}

class BuildingInfo {
  final Directory directory;
  final String name;
  final String districtName;
  final String regionName;
  final String? iconType;
  final dynamic iconData;
  BuildingInfo(
    this.directory,
    this.name,
    this.districtName,
    this.regionName,
    this.iconType,
    this.iconData,
  );
}

// --- BARU: Class helper untuk Distrik ---
class DistrictInfo {
  final Directory directory;
  final String name;
  final String regionName;
  final int buildingCount; // Untuk info tambahan
  DistrictInfo(this.directory, this.name, this.regionName, this.buildingCount);
}

class WallpaperImageLoader {
  static Widget buildBuildingListIcon(
    String? iconType,
    dynamic iconData,
    String buildingPath,
  ) {
    double size = 40.0;
    Widget child = const Icon(Icons.location_city, size: 24);
    File? imageFile;

    if (iconType == 'text' &&
        iconData != null &&
        iconData.toString().isNotEmpty) {
      child = Text(
        iconData.toString(),
        style: const TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      );
    } else if (iconType == 'image' && iconData != null) {
      final path = p.join(buildingPath, iconData.toString());
      final file = File(path);
      if (file.existsSync()) {
        imageFile = file;
      }
    }

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

  static Future<List<ImageSourceInfo>> loadAllIconImages() async {
    final List<ImageSourceInfo> images = [];
    if (AppSettings.baseBuildingsPath == null) return images;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) return images;

    await for (final regionEntity in rootDir.list()) {
      if (regionEntity is Directory) {
        final regionName = p.basename(regionEntity.path);

        final regionDataFile = File(
          p.join(regionEntity.path, 'region_data.json'),
        );
        if (await regionDataFile.exists()) {
          try {
            final content = await regionDataFile.readAsString();
            final data = json.decode(content);
            if (data['icon_type'] == 'image' && data['icon_data'] != null) {
              final iconPath = p.join(regionEntity.path, data['icon_data']);
              if (await File(iconPath).exists()) {
                images.add(ImageSourceInfo(iconPath, 'Wilayah: $regionName'));
              }
            }
          } catch (_) {}
        }

        await for (final districtEntity in regionEntity.list()) {
          if (districtEntity is Directory) {
            final districtName = p.basename(districtEntity.path);

            final districtDataFile = File(
              p.join(districtEntity.path, 'district_data.json'),
            );
            if (await districtDataFile.exists()) {
              try {
                final content = await districtDataFile.readAsString();
                final data = json.decode(content);
                if (data['icon_type'] == 'image' && data['icon_data'] != null) {
                  final iconPath = p.join(
                    districtEntity.path,
                    data['icon_data'],
                  );
                  if (await File(iconPath).exists()) {
                    images.add(
                      ImageSourceInfo(iconPath, 'Distrik: $districtName'),
                    );
                  }
                }
              } catch (_) {}
            }

            await for (final buildingEntity in districtEntity.list()) {
              if (buildingEntity is Directory) {
                final buildingDataFile = File(
                  p.join(buildingEntity.path, 'data.json'),
                );

                if (!await buildingDataFile.exists()) continue;

                try {
                  final content = await buildingDataFile.readAsString();
                  Map<String, dynamic> buildingData = json.decode(content);

                  if (buildingData['icon_type'] == 'image' &&
                      buildingData['icon_data'] != null) {
                    final iconPath = p.join(
                      buildingEntity.path,
                      buildingData['icon_data'],
                    );
                    if (await File(iconPath).exists()) {
                      images.add(
                        ImageSourceInfo(
                          iconPath,
                          'Bangunan: ${p.basename(buildingEntity.path)}',
                        ),
                      );
                    }
                  }
                } catch (_) {}
              }
            }
          }
        }
      }
    }
    return images;
  }

  static Future<List<BuildingInfo>> loadAllBuildingsWithRooms() async {
    final List<BuildingInfo> result = [];
    if (AppSettings.baseBuildingsPath == null) return result;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) return result;

    await for (final regionEntity in rootDir.list()) {
      if (regionEntity is Directory) {
        final regionName = p.basename(regionEntity.path);
        await for (final districtEntity in regionEntity.list()) {
          if (districtEntity is Directory) {
            final districtName = p.basename(districtEntity.path);
            await for (final buildingEntity in districtEntity.list()) {
              if (buildingEntity is Directory) {
                final buildingName = p.basename(buildingEntity.path);
                final buildingDataFile = File(
                  p.join(buildingEntity.path, 'data.json'),
                );

                if (!await buildingDataFile.exists()) continue;

                try {
                  final content = await buildingDataFile.readAsString();
                  Map<String, dynamic> buildingData = json.decode(content);

                  final iconType = buildingData['icon_type'];
                  final iconData = buildingData['icon_data'];

                  List<dynamic> rooms = buildingData['rooms'] ?? [];
                  bool hasRoomImage = rooms.any((room) {
                    if (room['image'] != null) {
                      final imagePath = p.join(
                        buildingEntity.path,
                        room['image'],
                      );
                      return File(imagePath).existsSync();
                    }
                    return false;
                  });

                  if (hasRoomImage) {
                    result.add(
                      BuildingInfo(
                        buildingEntity,
                        buildingName,
                        districtName,
                        regionName,
                        iconType,
                        iconData,
                      ),
                    );
                  }
                } catch (_) {}
              }
            }
          }
        }
      }
    }
    return result;
  }

  // --- BARU: Memuat semua Distrik yang memiliki bangunan ---
  static Future<List<DistrictInfo>> loadAllDistrictsWithRooms() async {
    final List<DistrictInfo> result = [];
    if (AppSettings.baseBuildingsPath == null) return result;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    if (!await rootDir.exists()) return result;

    await for (final regionEntity in rootDir.list()) {
      if (regionEntity is Directory) {
        final regionName = p.basename(regionEntity.path);
        await for (final districtEntity in regionEntity.list()) {
          if (districtEntity is Directory) {
            final districtName = p.basename(districtEntity.path);
            int buildingCount = 0;

            // Cek apakah distrik memiliki bangunan dengan ruangan
            // Kita hitung sekilas
            try {
              await for (final buildingEntity in districtEntity.list()) {
                if (buildingEntity is Directory &&
                    await File(
                      p.join(buildingEntity.path, 'data.json'),
                    ).exists()) {
                  buildingCount++;
                }
              }
            } catch (_) {}

            if (buildingCount > 0) {
              result.add(
                DistrictInfo(
                  districtEntity,
                  districtName,
                  regionName,
                  buildingCount,
                ),
              );
            }
          }
        }
      }
    }
    return result;
  }

  static Future<List<ImageSourceInfo>> loadRoomImagesFromBuilding(
    Directory buildingDir,
  ) async {
    final List<ImageSourceInfo> images = [];
    final buildingDataFile = File(p.join(buildingDir.path, 'data.json'));
    if (!await buildingDataFile.exists()) return images;

    try {
      final content = await buildingDataFile.readAsString();
      Map<String, dynamic> buildingData = json.decode(content);
      List<dynamic> rooms = buildingData['rooms'] ?? [];

      for (var room in rooms) {
        if (room['image'] != null) {
          final relativeImagePath = room['image'];
          final imagePath = p.join(buildingDir.path, relativeImagePath);
          if (await File(imagePath).exists()) {
            images.add(
              ImageSourceInfo(
                imagePath,
                room['name'] ?? 'Tanpa Nama',
                buildingPath: buildingDir.path,
              ),
            );
          }
        }
      }
    } catch (_) {}

    return images;
  }

  // --- BARU: Memuat semua gambar ruangan dari sebuah Distrik ---
  static Future<List<ImageSourceInfo>> loadRoomImagesFromDistrict(
    Directory districtDir,
  ) async {
    final List<ImageSourceInfo> allImages = [];

    try {
      await for (final buildingEntity in districtDir.list()) {
        if (buildingEntity is Directory) {
          // Gunakan fungsi existing untuk memuat ruangan dari bangunan ini
          final buildingImages = await loadRoomImagesFromBuilding(
            buildingEntity,
          );
          allImages.addAll(buildingImages);
        }
      }
    } catch (_) {}

    return allImages;
  }
}
