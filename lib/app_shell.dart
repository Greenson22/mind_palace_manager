// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/building/presentation/management/building_management_page.dart';
import 'package:mind_palace_manager/features/settings/settings_page.dart';
// --- BARU: Import AppSettings ---
import 'package:mind_palace_manager/app_settings.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart' as p; // Tambahkan import path
// --- SELESAI BARU ---

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- BARU: Bungkus dengan ValueListenableBuilder ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, currentThemeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mind Palace Manager',

          // --- Konfigurasi Tema ---
          themeMode: currentThemeMode,

          // Tema Terang (Light)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: Colors.blue,
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          ),

          // Tema Gelap (Dark)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed:
                Colors.blue, // Warna dasar tetap biru agar konsisten
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
          ),

          home: const DashboardPage(),
        );
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // --- SLIDESHOW STATE ---
  Timer? _slideshowTimer;
  List<String> _roomImagePaths = [];
  int _currentImageIndex = 0;
  bool _isLoadingSlideshow = false;
  // --- SELESAI SLIDESHOW STATE ---

  @override
  void initState() {
    super.initState();
    _checkAndStartSlideshow();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    super.dispose();
  }

  // Metode ini diperlukan untuk memicu rebuild DashboardPage saat kembali dari SettingsPage
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    ).then((_) {
      // Rebuild untuk memuat wallpaper baru
      setState(() {
        _checkAndStartSlideshow();
      });
    });
  }

  void _checkAndStartSlideshow() {
    _slideshowTimer?.cancel();

    if (AppSettings.wallpaperType == 'slideshow' &&
        AppSettings.slideshowBuildingPath != null) {
      _startSlideshowLogic();
    }
  }

  // --- LOGIKA SLIDESHOW ---
  Future<void> _loadSlideshowImages() async {
    setState(() {
      _isLoadingSlideshow = true;
    });

    _roomImagePaths.clear();
    _currentImageIndex = 0;

    // --- PERBAIKAN ERROR: Akses path melalui AppSettings ---
    final buildingPath = AppSettings.slideshowBuildingPath;

    if (buildingPath == null) {
      _slideshowTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Data bangunan slideshow tidak ditemukan."),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoadingSlideshow = false);
      return;
    }
    // --- SELESAI PERBAIKAN ---

    final buildingDir = Directory(buildingPath);
    final buildingDataFile = File(p.join(buildingDir.path, 'data.json'));

    if (!await buildingDataFile.exists()) {
      _slideshowTimer?.cancel();
      // Atur wallpaper kembali ke default jika file data bangunan hilang
      AppSettings.clearWallpaper();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: Data bangunan slideshow tidak ditemukan."),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoadingSlideshow = false);
      return;
    }

    try {
      final content = await buildingDataFile.readAsString();
      Map<String, dynamic> buildingData = json.decode(content);
      List<dynamic> rooms = buildingData['rooms'] ?? [];

      for (var room in rooms) {
        if (room['image'] != null) {
          final relativeImagePath = room['image'];
          final imagePath = p.join(buildingPath, relativeImagePath);
          if (await File(imagePath).exists()) {
            _roomImagePaths.add(imagePath);
          }
        }
      }
    } catch (e) {
      print("Error loading slideshow images: $e");
    }

    // Jika hanya ada satu atau tidak ada gambar, batalkan slideshow
    if (_roomImagePaths.length <= 1) {
      _slideshowTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Slideshow dibatalkan. Hanya ditemukan 1 gambar atau kurang.",
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      _isLoadingSlideshow = false;
      _currentImageIndex = 0;
    });
  }

  void _startSlideshowLogic() async {
    await _loadSlideshowImages();

    if (_roomImagePaths.length <= 1) return;

    final slideDuration = Duration(
      seconds: AppSettings.slideshowSpeedSeconds.toInt(),
    );

    _slideshowTimer?.cancel();
    _slideshowTimer = Timer.periodic(slideDuration, (timer) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _roomImagePaths.length;
      });
    });
  }
  // --- SELESAI LOGIKA SLIDESHOW ---

  // --- BARU: Helper untuk konversi string ke BoxFit ---
  BoxFit _getBoxFit(String fitString) {
    switch (fitString) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }
  // --- SELESAI BARU ---

  @override
  Widget build(BuildContext context) {
    Widget backgroundWidget;

    // --- BARU: Ambil setting BoxFit ---
    final BoxFit imageFit = _getBoxFit(AppSettings.wallpaperFit);
    // --- SELESAI BARU ---

    if (AppSettings.wallpaperType == 'slideshow' &&
        _roomImagePaths.isNotEmpty) {
      // 1. Slideshow Wallpaper
      final transitionDuration = Duration(
        seconds: AppSettings.slideshowTransitionDurationSeconds.toInt(),
      );

      backgroundWidget = AnimatedSwitcher(
        duration: transitionDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Fade Transition
          return FadeTransition(opacity: animation, child: child);
        },
        child: Image.file(
          // Gunakan ValueKey untuk memastikan AnimatedSwitcher mengenali perubahan
          File(_roomImagePaths[_currentImageIndex]),
          key: ValueKey<int>(_currentImageIndex),
          // --- UBAH: Gunakan imageFit ---
          fit: imageFit,
          // --- SELESAI UBAH ---
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            key: const ValueKey<int>(-1),
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
      );
    } else if (AppSettings.wallpaperType == 'static' &&
        AppSettings.wallpaperPath != null) {
      // 2. Static Wallpaper
      backgroundWidget = Image.file(
        File(AppSettings.wallpaperPath!),
        // --- UBAH: Gunakan imageFit ---
        fit: imageFit,
        // --- SELESAI UBAH ---
        height: double.infinity,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: Theme.of(context).colorScheme.surface),
      );
    } else {
      // 3. Default (Solid Color)
      backgroundWidget = Container(
        color: Theme.of(context).colorScheme.surface,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Utama'),
        actions: const [], // Tombol Wallpaper dipindahkan ke Settings
      ),
      // Susun konten di atas latar belakang
      body: Stack(
        children: [
          // 1. Background (Wallpaper)
          Positioned.fill(child: backgroundWidget),

          // 2. Overlay untuk keterbacaan
          Positioned.fill(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(
                      0.5,
                    ) // Overlay gelap untuk dark mode
                  : Colors.white.withOpacity(
                      0.7,
                    ), // Overlay terang untuk light mode
            ),
          ),

          // 3. Foreground Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon besar dekoratif
                Icon(
                  Icons.castle_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.business),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BuildingManagementPage(),
                      ),
                    );
                  },
                  label: const Text('Kelola Distrik & Bangunan'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  onPressed:
                      _openSettings, // Panggil metode dengan setState after pop
                  label: const Text('Buka Pengaturan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
