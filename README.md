# 🧠 Mind Palace Manager

**Mind Palace Manager** adalah aplikasi Flutter yang dirancang untuk membantu Anda membangun, memvisualisasikan, dan mengelola "Istana Pikiran" (Memory Palace) digital Anda.

Aplikasi ini mengimplementasikan teknik *Method of Loci* secara terstruktur, memungkinkan Anda menyimpan memori atau informasi dalam struktur hierarki spasial—mulai dari Peta Dunia hingga ke objek spesifik di dalam ruangan.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

## ✨ Fitur Utama

### 🌍 Hierarki Spasial Lengkap
Kelola memori Anda dengan struktur yang mendalam:
1.  **Dunia:** Peta global yang memuat berbagai wilayah.
2.  **Wilayah (Region):** Area besar yang berisi distrik-distrik.
3.  **Distrik (District):** Area lokal yang berisi bangunan.
4.  **Bangunan (Building):** Tempat yang berisi ruangan-ruangan.
5.  **Ruangan (Room):** Lokasi visual tempat menaruh informasi.
6.  **Objek & Wadah:** Item detail di dalam ruangan (mendukung struktur rekursif/objek di dalam objek).

### 🗺️ Editor Peta Visual
* **Peta Dunia & Distrik:** Unggah gambar peta Anda sendiri dan tempatkan "Pin" lokasi secara interaktif (Drag & Drop).
* **Zoom & Pan:** Navigasi peta dengan fitur *Interactive Viewer* (Zoom in/out).
* **Kustomisasi Pin:** Ubah bentuk pin (Bulat/Kotak/Tanpa Latar), warna, ukuran, dan ketebalan outline sesuai selera.

### 🏠 Editor Ruangan Imersif
* **Penempatan Objek:** Letakkan ikon atau gambar objek di atas gambar ruangan secara presisi.
* **Mode Navigasi:** Buat "Pintu" atau tautan antar ruangan untuk simulasi perjalanan memori (*Memory Journey*).
* **Dukungan Gambar:** Gunakan foto ruangan asli atau gambar isometri.

### 🎨 Personalisasi & Tampilan
* **Wallpaper Dashboard:** Dukungan untuk Warna Solid, Gradien, Gambar Statis, atau **Slideshow** otomatis dari koleksi ruangan Anda.
* **Tema Aplikasi:** Mode Terang (Light) dan Gelap (Dark).
* **Transparansi & Blur:** Atur opacity ikon dan efek blur pada background agar fokus terjaga.

### 🔒 Privasi & Penyimpanan Lokal
* **Sepenuhnya Offline:** Semua data (gambar, konfigurasi JSON) disimpan secara lokal di perangkat Anda.
* **Manajemen File:** Pilih lokasi folder penyimpanan utama secara manual.
* **Export:** Fitur untuk mengekspor tampilan peta atau ikon ke format gambar (PNG).

## 📱 Tangkapan Layar (Screenshots)

| Dashboard | Peta Distrik | Editor Ruangan | Objek Rekursif |
|:---------:|:------------:|:--------------:|:--------------:|
| *(Gambar)* | *(Gambar)* | *(Gambar)* | *(Gambar)* |

## 🛠️ Teknologi yang Digunakan

Aplikasi ini dibangun menggunakan **Flutter** dan memanfaatkan berbagai *package* untuk fungsionalitasnya:

* `provider` / `state management` (via `setState` & `ValueNotifier`): Manajemen state aplikasi.
* `shared_preferences`: Menyimpan pengaturan konfigurasi (tema, path folder, dll).
* `file_picker`: Memilih gambar dan lokasi folder.
* `permission_handler`: Menangani izin penyimpanan (terutama Android 11+).
* `path_provider` & `path`: Manajemen path file sistem.
* `device_info_plus`: Mendeteksi versi Android untuk manajemen izin.
* `package_info_plus`: Menampilkan versi aplikasi.
* `url_launcher`: Membuka tautan eksternal (profil pengembang).

## 🚀 Cara Instalasi & Menjalankan

1.  **Prasyarat:** Pastikan Anda telah menginstal [Flutter SDK](https://flutter.dev/docs/get-started/install).

2.  **Clone Repository:**
    ```bash
    git clone [https://github.com/username/mind-palace-manager.git](https://github.com/username/mind-palace-manager.git)
    cd mind-palace-manager
    ```

3.  **Instal Dependensi:**
    ```bash
    flutter pub get
    ```

4.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```

### ⚠️ Catatan Izin Penyimpanan (Android)
Aplikasi ini memerlukan akses penuh ke penyimpanan eksternal (*Manage External Storage*) untuk menyimpan dan memuat gambar/peta hierarki Anda secara persisten.
* Pada **Android 10 ke bawah**: Meminta izin `READ/WRITE_EXTERNAL_STORAGE`.
* Pada **Android 11 ke atas**: Meminta izin `MANAGE_EXTERNAL_STORAGE` agar dapat mengakses folder yang ditentukan pengguna.

## 📂 Struktur Proyek

Struktur folder utama di dalam `lib/`:

* `main.dart`: Entry point aplikasi.
* `app_shell.dart`: Halaman utama (Dashboard) dan navigasi dasar.
* `app_settings.dart`: Singleton untuk mengelola preferensi global.
* `features/`:
    * `world/`: Logika dan UI untuk Peta Dunia.
    * `region/`: Manajemen Wilayah dan detailnya.
    * `building/`: Manajemen Distrik, Bangunan, dan Editor Peta Distrik.
    * `objects/`: Halaman untuk objek rekursif.
    * `settings/`: Halaman pengaturan, about, dan dialog kustomisasi.

## 🤝 Kontribusi

Kontribusi sangat diterima! Jika Anda ingin meningkatkan fitur atau memperbaiki bug:

1.  Fork repositori ini.
2.  Buat branch fitur baru (`git checkout -b fitur-keren`).
3.  Commit perubahan Anda (`git commit -m 'Menambahkan fitur keren'`).
4.  Push ke branch (`git push origin fitur-keren`).
5.  Buat Pull Request.

## 👨‍💻 Pengembang

**Frendy Rikal Gerung, S.Kom.**
* Lulusan Universitas Negeri Manado.
* [LinkedIn](https://linkedin.com/in/frendy-rikal-gerung-bb450b38a/)
* Email: frendydev1@gmail.com

---
Dibuat dengan ❤️ menggunakan Flutter.