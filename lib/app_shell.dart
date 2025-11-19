// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/building/presentation/management/building_management_page.dart';
import 'package:mind_palace_manager/features/settings/settings_page.dart';
// --- BARU: Import AppSettings ---
import 'package:mind_palace_manager/app_settings.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Import untuk ImageFilter
import 'package:path/path.dart' as p;
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

    // Hanya aktifkan slideshow jika mode yang dipilih adalah 'slideshow'
    if (AppSettings.wallpaperMode == 'slideshow' &&
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
      // ... (snackbar error handling) ...
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
      // ... (snackbar error handling) ...
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
      // ... (snackbar cancellation handling) ...
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

  // --- BARU: Fungsi untuk menghasilkan widget background image (termasuk blur) ---
  Widget _buildImageBackground(
    BuildContext context, {
    bool isSlideshow = false,
  }) {
    final BoxFit imageFit = _getBoxFit(AppSettings.wallpaperFit);
    final double blur = AppSettings.blurStrength;
    final File? imageFile = isSlideshow
        ? (_roomImagePaths.isNotEmpty
              ? File(_roomImagePaths[_currentImageIndex])
              : null)
        : (AppSettings.wallpaperPath != null
              ? File(AppSettings.wallpaperPath!)
              : null);

    if (imageFile == null || !imageFile.existsSync()) {
      return Container(color: Theme.of(context).colorScheme.surface);
    }

    Widget imageWidget = Image.file(
      imageFile,
      key: isSlideshow
          ? ValueKey<int>(_currentImageIndex)
          : const ValueKey<String>('static_wallpaper'),
      fit: imageFit,
      height: double.infinity,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: Theme.of(context).colorScheme.surface),
    );

    if (blur > 0.0) {
      // Jika blur aktif, bungkus dengan BackdropFilter
      return Stack(
        children: [
          imageWidget,
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                color: Colors.black.withOpacity(0),
              ), // Kontainer transparan
            ),
          ),
        ],
      );
    }
    return imageWidget;
  }
  // --- SELESAI BARU ---

  @override
  Widget build(BuildContext context) {
    Widget backgroundWidget;
    final String mode = AppSettings.wallpaperMode;

    // --- UBAH: Logika Background berdasarkan Mode Baru ---
    if (mode == 'solid') {
      // 1. Solid Color
      backgroundWidget = Container(color: Color(AppSettings.solidColor));
    } else if (mode == 'gradient') {
      // 2. Gradient
      backgroundWidget = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppSettings.gradientColor1),
              Color(AppSettings.gradientColor2),
            ],
          ),
        ),
      );
    } else if (mode == 'slideshow' && _roomImagePaths.length > 1) {
      // 3. Slideshow Wallpaper (dengan dukungan blur)
      final transitionDuration = Duration(
        milliseconds: (AppSettings.slideshowTransitionDurationSeconds * 1000)
            .toInt(),
      );

      backgroundWidget = AnimatedSwitcher(
        duration: transitionDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        // Panggil helper image background (isSlideshow=true)
        child: _buildImageBackground(context, isSlideshow: true),
      );
    } else if (mode == 'static' && AppSettings.wallpaperPath != null) {
      // 4. Static Wallpaper (dengan dukungan blur)
      backgroundWidget = _buildImageBackground(context);
    } else {
      // 5. Default (Solid Color, mengikuti tema)
      backgroundWidget = Container(
        color: Theme.of(context).colorScheme.surface,
      );
    }
    // --- SELESAI UBAH ---

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Utama'), actions: const []),
      // Susun konten di atas latar belakang
      body: Stack(
        children: [
          // 1. Background (Wallpaper/Solid/Gradient)
          Positioned.fill(child: backgroundWidget),

          // 2. Overlay untuk keterbacaan (tetap dipertahankan untuk semua mode)
          Positioned.fill(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
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
                  onPressed: _openSettings,
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
