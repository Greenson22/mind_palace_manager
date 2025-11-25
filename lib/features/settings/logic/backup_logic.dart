import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:mind_palace_manager/app_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BackupInfo {
  final String fileName;
  final String path;
  final DateTime date;
  final int regionCount;
  final int buildingCount;
  final String appVersion;
  final int sizeBytes;

  BackupInfo({
    required this.fileName,
    required this.path,
    required this.date,
    required this.regionCount,
    required this.buildingCount,
    required this.appVersion,
    required this.sizeBytes,
  });
}

class BackupLogic {
  // Folder khusus untuk menyimpan backup di dalam root .buildings
  static const String _backupFolderName = '_INTERNAL_BACKUPS_';

  Future<Directory> _getBackupDir() async {
    if (AppSettings.baseBuildingsPath == null) {
      throw Exception("Folder penyimpanan utama belum diatur.");
    }
    final dir = Directory(
      p.join(AppSettings.baseBuildingsPath!, _backupFolderName),
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // --- READ: Ambil Daftar Backup ---
  Future<List<BackupInfo>> loadBackups() async {
    final dir = await _getBackupDir();
    final List<BackupInfo> backups = [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.zip'))
        .toList();

    for (var file in files) {
      try {
        // Kita coba baca metadata dari nama file atau (opsional) unzip header
        // Untuk performa, kita parse dari nama file jika formatnya sesuai,
        // atau baca atribut file.

        // Format nama file: backup_YYYYMMDD_HHMMSS.zip
        // Namun, metadata detail ada DI DALAM zip (backup_info.json).
        // Membuka zip setiap load list itu berat.
        // Jadi kita baca basic info dari FileSystemEntity,
        // detailnya kita tampilkan saat user klik "Info" atau kita simpan sidecar json.

        // Untuk solusi "Very Good", kita baca metadata ringan.
        final stat = await file.stat();

        // Cek apakah ada file sidecar .json dengan nama sama
        // Contoh: backup_abc.zip dan backup_abc.json
        final metaFile = File(file.path.replaceAll('.zip', '.meta.json'));
        int rCount = 0;
        int bCount = 0;
        String ver = "Unknown";

        if (await metaFile.exists()) {
          final content = await metaFile.readAsString();
          final json = jsonDecode(content);
          rCount = json['regions'] ?? 0;
          bCount = json['buildings'] ?? 0;
          ver = json['version'] ?? "Unknown";
        }

        backups.add(
          BackupInfo(
            fileName: p.basename(file.path),
            path: file.path,
            date: stat.modified,
            regionCount: rCount,
            buildingCount: bCount,
            appVersion: ver,
            sizeBytes: stat.size,
          ),
        );
      } catch (e) {
        debugPrint("Error reading backup file: $e");
      }
    }

    // Urutkan terbaru paling atas
    backups.sort((a, b) => b.date.compareTo(a.date));
    return backups;
  }

  // --- CREATE: Buat Backup Baru ---
  Future<void> createBackup() async {
    if (AppSettings.baseBuildingsPath == null) return;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    final backupDir = await _getBackupDir();

    // 1. Kumpulkan Statistik & File
    int regions = 0;
    int buildings = 0;
    final List<File> filesToZip = [];

    // Scan folder
    await for (var entity in rootDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File) {
        // SKIP folder backup itu sendiri agar tidak rekursif
        if (entity.path.contains(_backupFolderName)) continue;
        // Skip file sistem/hidden
        if (p.basename(entity.path).startsWith('.')) continue;

        filesToZip.add(entity);

        // Hitung statistik sederhana
        if (p.basename(entity.path) == 'region_data.json') regions++;
        if (p.basename(entity.path) == 'data.json')
          buildings++; // Building data
      }
    }

    // 2. Siapkan Metadata
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final metadata = {
      'created_at': DateTime.now().toIso8601String(),
      'version': packageInfo.version,
      'build': packageInfo.buildNumber,
      'regions': regions,
      'buildings': buildings,
      'device': Platform.operatingSystem,
    };

    // 3. Proses Zipping (Menggunakan package 'archive')
    final archive = Archive();

    // Tambahkan file metadata ke dalam zip
    final metaBytes = utf8.encode(jsonEncode(metadata));
    archive.addFile(
      ArchiveFile('backup_info.json', metaBytes.length, metaBytes),
    );

    // Tambahkan semua file user
    for (var file in filesToZip) {
      final filename = p.relative(file.path, from: rootDir.path);
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(filename, bytes.length, bytes));
    }

    // 4. Encode ke Zip
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    if (zipData == null) throw Exception("Gagal melakukan encoding zip.");

    // 5. Simpan File Zip
    final now = DateTime.now();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'backup_mpm_$timestamp.zip';
    final zipFile = File(p.join(backupDir.path, fileName));
    await zipFile.writeAsBytes(zipData);

    // 6. Simpan Sidecar Metadata (agar cepat dibaca saat load list)
    final metaFile = File(
      p.join(backupDir.path, 'backup_mpm_$timestamp.meta.json'),
    );
    await metaFile.writeAsString(jsonEncode(metadata));
  }

  // --- IMPORT: Ambil dari luar ---
  Future<void> importExternalBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final sourceFile = File(result.files.single.path!);
      final backupDir = await _getBackupDir();

      // Copy ke folder internal backup
      final fileName = p.basename(sourceFile.path);
      final destPath = p.join(backupDir.path, fileName);

      // Hindari duplikat nama
      if (await File(destPath).exists()) {
        final newName =
            "imported_${DateTime.now().millisecondsSinceEpoch}_$fileName";
        await sourceFile.copy(p.join(backupDir.path, newName));
      } else {
        await sourceFile.copy(destPath);
      }

      // Kita tidak membuat .meta.json di sini, loadBackups akan menanganinya (field kosong)
      // Atau bisa kita extract info.json sebentar untuk generate meta.
    }
  }

  // --- RESTORE: Kembalikan Data ---
  Future<void> restoreBackup(String zipPath) async {
    if (AppSettings.baseBuildingsPath == null) return;
    final rootDir = Directory(AppSettings.baseBuildingsPath!);
    final backupDir =
        await _getBackupDir(); // Kita butuh path ini untuk dikecualikan

    // 1. BACA ZIP
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // 2. BERSIHKAN DATA LAMA (Dangerous Zone!)
    // Kita hapus semua isi rootDir KECUALI folder _INTERNAL_BACKUPS_
    final entities = rootDir.listSync();
    for (var entity in entities) {
      if (entity.path.contains(_backupFolderName))
        continue; // JANGAN HAPUS BACKUP

      if (entity is File) {
        await entity.delete();
      } else if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    }

    // 3. EKSTRAK FILE BARU
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        // Skip metadata json internal
        if (filename == 'backup_info.json') continue;

        final data = file.content as List<int>;
        final outFile = File(p.join(rootDir.path, filename));

        // Pastikan direktori ada
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
      }
    }
  }

  // --- DELETE ---
  Future<void> deleteBackup(String zipPath) async {
    final file = File(zipPath);
    if (await file.exists()) {
      await file.delete();
      // Hapus juga sidecar meta jika ada
      final metaPath = zipPath.replaceAll('.zip', '.meta.json');
      final metaFile = File(metaPath);
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
    }
  }

  // --- SHARE / EXPORT FILE (Salin ke folder Download/Dokumen) ---
  Future<String> exportBackupToDevice(String zipPath) async {
    // Gunakan FilePicker untuk save file (jika didukung) atau copy ke direktori umum
    // Untuk Android/iOS yang strict, cara termudah adalah share_plus,
    // tapi karena user minta "import", kita asumsikan file management manual.
    // Kita akan gunakan permission helper untuk copy ke folder Download/Public.

    // Sederhana: Kita minta user pilih folder tujuan export
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final source = File(zipPath);
      final fileName = p.basename(zipPath);
      final dest = p.join(selectedDirectory, fileName);
      await source.copy(dest);
      return dest;
    }
    throw Exception("Export dibatalkan.");
  }
}
