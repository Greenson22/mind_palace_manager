// lib/app_shell.dart
import 'package:flutter/material.dart';
import 'package:mind_palace_manager/features/building/presentation/management/building_management_page.dart';
import 'package:mind_palace_manager/features/settings/settings_page.dart';
import 'package:mind_palace_manager/app_settings.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui'; // Import untuk ImageFilter
import 'package:path/path.dart' as p;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder untuk mendengarkan perubahan ThemeMode
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

    // Akses path melalui AppSettings
    final buildingPath = AppSettings.slideshowBuildingPath;

    if (buildingPath == null) {
      _slideshowTimer?.cancel();
      setState(() => _isLoadingSlideshow = false);
      return;
    }

    final buildingDir = Directory(buildingPath);
    final buildingDataFile = File(p.join(buildingDir.path, 'data.json'));

    if (!await buildingDataFile.exists()) {
      _slideshowTimer?.cancel();
      AppSettings.clearWallpaper();
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

    if (_roomImagePaths.length <= 1) {
      _slideshowTimer?.cancel();
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

  Widget _buildImageBackground(
    BuildContext context, {
    bool isSlideshow = false,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: AppSettings.containmentBackgroundColor,
      builder: (context, containmentColorValue, child) {
        return ValueListenableBuilder<double>(
          valueListenable: AppSettings.blurStrength,
          builder: (context, blur, child) {
            final BoxFit imageFit = _getBoxFit(AppSettings.wallpaperFit);
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

            Widget foregroundImage = Image.file(
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

            if (imageFit == BoxFit.contain) {
              final Color containmentColor = Color(containmentColorValue);
              Widget paddingBackground;

              if (blur > 0.0) {
                paddingBackground = Stack(
                  children: [
                    Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    ),
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                        child: Container(color: Colors.black.withOpacity(0.2)),
                      ),
                    ),
                  ],
                );
              } else {
                paddingBackground = Container(color: containmentColor);
              }

              return Stack(
                children: [
                  Positioned.fill(child: paddingBackground),
                  foregroundImage,
                ],
              );
            }

            if (blur > 0.0) {
              return Stack(
                children: [
                  foregroundImage,
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: Container(color: Colors.black.withOpacity(0)),
                    ),
                  ),
                ],
              );
            }
            return foregroundImage;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget backgroundWidget;
    final String mode = AppSettings.wallpaperMode;

    if (mode == 'solid') {
      backgroundWidget = Container(color: Color(AppSettings.solidColor.value));
    } else if (mode == 'gradient') {
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
      final transitionDuration = Duration(
        milliseconds: (AppSettings.slideshowTransitionDurationSeconds * 1000)
            .toInt(),
      );

      backgroundWidget = AnimatedSwitcher(
        duration: transitionDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _buildImageBackground(context, isSlideshow: true),
      );
    } else if (mode == 'static' && AppSettings.wallpaperPath != null) {
      backgroundWidget = _buildImageBackground(context);
    } else {
      backgroundWidget = Container(
        color: Theme.of(context).colorScheme.surface,
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Ikon Aplikasi di AppBar ---
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology, // Ikon representasi "Mind Palace"
                size: 24,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            // --- Teks Judul ---
            const Text(
              'Mind Palace Manager',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [],
      ),

      body: Stack(
        children: [
          // 1. Background (Wallpaper/Solid/Gradient)
          Positioned.fill(child: backgroundWidget),

          // 2. Overlay (Cover) Transparan dengan Opacity yang Bisa Diatur
          Positioned.fill(
            child: Container(
              // Menggunakan setting opacity dari AppSettings
              color:
                  (Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white)
                      .withOpacity(AppSettings.backgroundOverlayOpacity),
            ),
          ),

          // 3. Foreground Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
