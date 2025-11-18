import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  String _version = 'Memuat versi...';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Tab Controller untuk 2 tab: Fitur dan Pengembang
    _tabController = TabController(length: 2, vsync: this);
    _initPackageInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = 'Versi ${info.version} (${info.buildNumber})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = 'Versi Aplikasi: 1.0.0';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Mind Palace'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Fitur Aplikasi'),
            Tab(text: 'Pengembang'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturesTab(context),
          _buildDeveloperTab(context, textTheme),
        ],
      ),
    );
  }

  // Tab 1: Fitur Aplikasi (Spesifik Mind Palace Manager)
  Widget _buildFeaturesTab(BuildContext context) {
    final features = [
      {
        'icon': Icons.public,
        'title': 'Peta Dunia Ingatan',
        'subtitle':
            'Visualisasikan seluruh wilayah memori Anda dalam satu peta global.',
      },
      {
        'icon': Icons.map_outlined,
        'title': 'Manajemen Distrik',
        'subtitle':
            'Atur tata letak bangunan dan landmark dalam setiap distrik secara bebas.',
      },
      {
        'icon': Icons.room_preferences,
        'title': 'Editor Ruangan',
        'subtitle':
            'Buat dan hubungkan ruangan untuk perjalanan memori (Memory Journey).',
      },
      {
        'icon': Icons.transform,
        'title': 'Kustomisasi Fleksibel',
        'subtitle':
            'Ubah ukuran, bentuk, dan gambar ikon bangunan sesuai imajinasi Anda.',
      },
      {
        'icon': Icons.zoom_in,
        'title': 'Navigasi Interaktif',
        'subtitle':
            'Zoom, Pan, dan tap untuk menjelajahi setiap sudut istana pikiran Anda.',
      },
      {
        'icon': Icons.save_alt,
        'title': 'Data Lokal',
        'subtitle':
            'Semua data gambar dan struktur tersimpan aman di perangkat Anda.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _AnimatedFeatureListItem(
          icon: feature['icon'] as IconData,
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          index: index,
        );
      },
    );
  }

  // Tab 2: Informasi Pengembang (Dari file yang diupload)
  Widget _buildDeveloperTab(BuildContext context, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              // Pastikan file ini ada di pubspec.yaml
              backgroundImage: AssetImage('assets/pictures/profile.jpg'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Frendy Rikal Gerung, S.Kom.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Lulusan Sarjana Komputer dari Universitas Negeri Manado',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Text(
            'Dibuat dengan semangat untuk menyediakan alat bantu belajar yang personal, cerdas, dan sepenuhnya offline untuk menjaga privasi data Anda.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Kontak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.link),
                label: const Text('LinkedIn'),
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://linkedin.com/in/frendy-rikal-gerung-bb450b38a/',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email'),
                onPressed: () =>
                    launchUrl(Uri.parse('mailto:frendydev1@gmail.com')),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text(_version, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AnimatedFeatureListItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String subtitle;

  const _AnimatedFeatureListItem({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AnimatedFeatureListItem> createState() =>
      __AnimatedFeatureListItemState();
}

class __AnimatedFeatureListItemState extends State<_AnimatedFeatureListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.subtitle),
          ),
        ),
      ),
    );
  }
}
