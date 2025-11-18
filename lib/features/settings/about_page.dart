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
          _version = 'Versi ${info.version} (Build ${info.buildNumber})';
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
            Tab(text: 'Fitur Utama'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeaturesTab(context),
          _buildAppInfoTab(context, textTheme),
        ],
      ),
    );
  }

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

  Widget _buildAppInfoTab(BuildContext context, TextTheme textTheme) {
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
            // --- PERUBAHAN DI SINI ---
            // Menggunakan aset gambar profil
            child: const CircleAvatar(
              radius: 60, // Ukuran radius disesuaikan
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/pictures/profile.jpg'),
            ),
            // -------------------------
          ),
          const SizedBox(height: 24),
          Text(
            'Mind Palace Manager',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola Istana Pikiran Anda',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Text(
            'Aplikasi ini dirancang untuk membantu Anda membangun, mengelola, dan memvisualisasikan teknik "Method of Loci" atau Istana Pikiran secara digital. Tingkatkan daya ingat Anda dengan struktur spasial yang terorganisir.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          Text('Hubungi Pengembang', style: textTheme.titleSmall),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.email_outlined),
                label: const Text('Email'),
                onPressed: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'developer@example.com', // Ganti dengan email Anda
                    query: 'subject=Feedback Mind Palace App',
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  }
                },
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
