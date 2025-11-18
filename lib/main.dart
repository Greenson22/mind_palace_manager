import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Kita ganti halaman home dari 'Hello World' ke BuildingViewPage baru
      home: BuildingViewPage(),
    );
  }
}

// Ini adalah halaman baru yang Anda minta
class BuildingViewPage extends StatelessWidget {
  const BuildingViewPage({super.key});

  // Teks deskripsi panjang sebagai contoh
  final String longDescription =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. "
      "Sed euismod, nisl eget aliquam ultricies, nunc nisl ultricies "
      "nunc, quis aliquam nisl nisl sit amet nisl. Sed euismod, nisl "
      "eget aliquam ultricies, nunc nisl ultricies nunc, quis aliquam "
      "nisl nisl sit amet nisl. Praesent vitae nisl eget nunc "
      "aliquam ultricies. Sed euismod, nisl eget aliquam ultricies, "
      "nunc nisl ultricies nunc, quis aliquam nisl nisl sit amet nisl. "
      "Donec nec nisl eget nunc aliquam ultricies. Sed euismod, nisl "
      "eget aliquam ultricies, nunc nisl ultricies nunc, quis aliquam "
      "nisl nisl sit amet nisl. \n\n"
      "Pellentesque habitant morbi tristique senectus et netus et "
      "malesuada fames ac turpis egestas. Vestibulum tortor quam, "
      "feugiat vitae, ultricies eget, tempor sit amet, ante. "
      "Donec eu libero sit amet quam egestas semper. Aenean "
      "ultricies mi vitae est. Mauris placerat eleifend leo.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tampilan Bangunan')),
      body: SingleChildScrollView(
        // Memastikan konten bisa di-scroll jika deskripsi terlalu panjang
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Gambar
              // Saya menggunakan gambar placeholder dari network.
              // Ganti URL ini dengan URL gambar Anda.
              Image.network(
                'https://via.placeholder.com/600x400.png?text=Gambar+Bangunan',
                width: double.infinity, // Lebar penuh
                height: 250,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16.0), // Spasi antara gambar dan teks
              // 2. Deskripsi Panjang
              Text(
                'Deskripsi Bangunan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8.0),
              Text(
                longDescription,
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24.0), // Spasi sebelum tombol
            ],
          ),
        ),
      ),
      // 3. Dua Tombol Navigasi (di bagian bawah)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tombol Kiri
            FloatingActionButton(
              onPressed: () {
                // Tambahkan logika navigasi 'kiri' di sini
                print('Tombol Kiri Ditekan');
              },
              child: const Icon(Icons.arrow_back),
            ),
            // Tombol Kanan
            FloatingActionButton(
              onPressed: () {
                // Tambahkan logika navigasi 'kanan' di sini
                print('Tombol Kanan Ditekan');
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
