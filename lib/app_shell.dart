// lib/app_shell.dart
import 'package:flutter/material.dart';
// Ganti 'nama_proyek_anda' dengan nama proyek Anda di pubspec.yaml
import 'package:mind_palace_manager/features/building/presentation/management/building_management_page.dart';
import 'package:mind_palace_manager/features/settings/settings_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp sekarang ada di sini
    return const MaterialApp(home: DashboardPage());
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Utama')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Arahkan ke halaman manajemen yang baru
                    builder: (context) => const BuildingManagementPage(),
                  ),
                );
              },
              child: const Text('Kelola Bangunan'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Arahkan ke halaman pengaturan yang baru
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      ),
    );
  }
}
