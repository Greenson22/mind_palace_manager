// lib/permission_helper.dart
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Memeriksa dan meminta izin penyimpanan yang diperlukan
/// berdasarkan versi Android.
Future<bool> checkAndRequestPermissions() async {
  // Hanya jalankan di Android
  if (Platform.isAndroid) {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    // Android 11 (SDK 30) atau lebih baru
    if (deviceInfo.version.sdkInt >= 30) {
      // Meminta izin MANAGE_EXTERNAL_STORAGE
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Pengguna menolak.
          return false;
        }
      }
    } else {
      // Android 10 (SDK 29) atau lebih lama
      // Meminta izin STORAGE (Read/Write)
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          return false;
        }
      }
    }
    return true; // Izin sudah didapat
  }
  return true; // Bukan Android, asumsikan OK (mis. Windows/Linux)
}
