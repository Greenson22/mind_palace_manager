// lib/features/building/presentation/editor/logic/room_editor_logic.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';

class RoomEditorLogic {
  final Directory buildingDirectory;
  late File _jsonFile;

  List<dynamic> rooms = [];
  Map<String, dynamic> _buildingData = {};

  RoomEditorLogic(this.buildingDirectory) {
    _jsonFile = File(p.join(buildingDirectory.path, 'data.json'));
  }

  // --- DATA LOAD & SAVE ---

  Future<void> loadData() async {
    if (!await _jsonFile.exists()) {
      // Jika file tidak ada, inisialisasi data kosong
      _buildingData = {'rooms': []};
      await saveData();
    } else {
      try {
        final content = await _jsonFile.readAsString();
        _buildingData = json.decode(content);
      } catch (e) {
        debugPrint("Error parsing JSON: $e");
        _buildingData = {'rooms': []};
      }
    }

    rooms = _buildingData['rooms'] as List? ?? [];
    // Pastikan setiap room punya list connections
    for (var room in rooms) {
      room['connections'] ??= [];
    }
  }

  Future<void> saveData() async {
    _buildingData['rooms'] = rooms;
    await _jsonFile.writeAsString(json.encode(_buildingData));
  }

  // --- ROOM MANAGEMENT ---

  Future<void> addRoom(String name, String? sourceImagePath) async {
    String? relativePath;

    if (sourceImagePath != null) {
      final ext = p.extension(sourceImagePath);
      final fileName = 'room_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(
        sourceImagePath,
      ).copy(p.join(buildingDirectory.path, fileName));
      relativePath = fileName;
    }

    final newRoom = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'image': relativePath,
      'connections': [],
    };
    rooms.add(newRoom);
    await saveData();
  }

  Future<void> updateRoom(
    Map<String, dynamic> room,
    String newName,
    String? newImagePath,
  ) async {
    String? oldImage = room['image'];
    String? finalImage = oldImage;

    // Jika user memilih untuk menghapus gambar
    if (newImagePath == 'DELETE_IMAGE') {
      if (oldImage != null) {
        final f = File(p.join(buildingDirectory.path, oldImage));
        if (await f.exists()) await f.delete();
      }
      finalImage = null;
    }
    // Jika user memilih gambar baru
    else if (newImagePath != null) {
      // Hapus gambar lama jika ada
      if (oldImage != null) {
        final f = File(p.join(buildingDirectory.path, oldImage));
        if (await f.exists()) await f.delete();
      }
      // Copy gambar baru
      final ext = p.extension(newImagePath);
      final fileName = 'room_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(newImagePath).copy(p.join(buildingDirectory.path, fileName));
      finalImage = fileName;
    }

    room['name'] = newName;
    room['image'] = finalImage;
    await saveData();
  }

  Future<void> deleteRoom(String roomId) async {
    final index = rooms.indexWhere((r) => r['id'] == roomId);
    if (index == -1) return;

    final room = rooms[index];
    // Hapus file gambar
    if (room['image'] != null) {
      final f = File(p.join(buildingDirectory.path, room['image']));
      if (await f.exists()) await f.delete();
    }

    // Hapus navigasi dari ruangan lain yang mengarah ke ruangan ini
    for (var r in rooms) {
      if (r['connections'] != null) {
        (r['connections'] as List).removeWhere(
          (c) => c['targetRoomId'] == roomId,
        );
      }
    }

    rooms.removeAt(index);
    await saveData();
  }

  void reorderRooms(int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx -= 1;
    final item = rooms.removeAt(oldIdx);
    rooms.insert(newIdx, item);
    saveData();
  }

  Future<bool> exportRoomImage(Map<String, dynamic> room) async {
    if (room['image'] == null || AppSettings.exportPath == null) return false;

    final src = File(p.join(buildingDirectory.path, room['image']));
    if (await src.exists()) {
      final dest = p.join(
        AppSettings.exportPath!,
        'room_export_${p.basename(src.path)}',
      );
      await src.copy(dest);
      return true;
    }
    return false;
  }

  // --- NAVIGATION MANAGEMENT ---

  Future<void> addConnection(
    Map<String, dynamic> fromRoom,
    Map<String, dynamic> newConnection,
  ) async {
    (fromRoom['connections'] as List).add(newConnection);
    await saveData();
  }

  Future<void> removeConnection(
    Map<String, dynamic> fromRoom,
    Map<String, dynamic> connection,
  ) async {
    (fromRoom['connections'] as List).remove(connection);
    await saveData();
  }

  Future<void> updateConnectionLabel(
    Map<String, dynamic> connection,
    String newLabel,
  ) async {
    connection['label'] = newLabel;
    await saveData();
  }

  // Membuat navigasi balik otomatis (opsional)
  Future<void> createReturnConnection(
    String fromRoomId,
    String fromRoomName,
    String targetRoomId,
  ) async {
    final targetRoom = rooms.firstWhere(
      (r) => r['id'] == targetRoomId,
      orElse: () => null,
    );
    if (targetRoom != null) {
      targetRoom['connections'] ??= [];
      (targetRoom['connections'] as List).add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'label': fromRoomName,
        'targetRoomId': fromRoomId,
        'direction': 'down', // Default arah balik
        'x': 0.5,
        'y': 0.9,
      });
      await saveData();
    }
  }
}
