# 🧠 Mind Palace Manager

**Mind Palace Manager** adalah aplikasi Flutter yang dirancang untuk membantu Anda membangun, memvisualisasikan, dan mengelola "Istana Pikiran" (Memory Palace) digital Anda secara offline dan aman.

Aplikasi ini mengimplementasikan teknik *Method of Loci* secara terstruktur, memungkinkan Anda menyimpan memori dalam hierarki spasial yang mendalam—mulai dari Peta Dunia, Wilayah, Distrik, hingga masuk ke dalam objek spesifik di dalam ruangan secara rekursif.

## ✨ Fitur Unggulan

### 🌍 Hierarki Spasial & Manajemen Memori

Kelola struktur ingatan Anda dengan kedalaman tanpa batas:

1.  **Dunia:** Peta global yang memuat berbagai wilayah.
2.  **Wilayah (Region):** Area besar yang berisi distrik-distrik.
3.  **Distrik (District):** Area lokal yang berisi bangunan.
4.  **Bangunan (Building):** Struktur yang berisi ruangan-ruangan.
5.  **Ruangan (Room):** Lokasi visual utama tempat navigasi terjadi.
6.  **Objek Rekursif:** Item di dalam ruangan yang bisa berupa **Wadah** (Container) atau **Lokasi Imersif** (bisa dimasuki lagi menjadi ruangan baru).

### ☁️ Visualisasi & Transisi Canggih

  * **Cloud Transition (Transisi Awan):** Efek transisi visual prosedural (membuka/menutup awan) saat berpindah antar peta atau ruangan, menciptakan pengalaman navigasi yang mulus.
  * **Kustomisasi Pin & Ikon:** Ubah bentuk Pin (Bulat/Kotak/Tanpa Latar), atur ketebalan outline, warna, hingga penggunaan Emoji atau Gambar kustom sebagai penanda lokasi.
  * **Animasi Navigasi:** Panah navigasi di dalam ruangan dilengkapi animasi denyut (*pulse*) untuk memudahkan identifikasi jalur.

### 🏭 Bank Bangunan (Gudang)

  * **Sistem Template:** Buat bangunan di "Gudang" (Bank) tanpa harus menempatkannya langsung di peta.
  * **Deploy & Retract:** Tempatkan (*Deploy*) bangunan dari Bank ke Distrik mana saja, atau tarik kembali (*Retract*) bangunan dari peta ke Bank untuk disimpan.
  * **Kloning:** Fitur untuk menyalin atau memindahkan bangunan dan seluruh isinya antar Distrik dengan mudah.

### 🎨 Personalisasi Dashboard

  * **Slideshow Cerdas:** Jadikan dashboard Anda hidup dengan slideshow gambar ruangan yang diambil dari **Bangunan tertentu** atau seluruh **Distrik**.
  * **Mode Wallpaper:** Pilihan latar belakang Warna Solid, Gradien, Gambar Statis, atau Slideshow.
  * **Efek Visual:** Atur tingkat *Blur* pada wallpaper dan *Opacity* overlay agar teks tetap mudah dibaca.

### 🛠️ Editor Peta & Ruangan (WYSIWYG)

  * **Peta Interaktif:** Unggah gambar peta sendiri. Tempatkan lokasi dengan sistem *Drag & Drop*.
  * **Editor Navigasi:** Hubungkan ruangan menggunakan sistem Panah Navigasi. Atur posisi (X,Y) dan rotasi panah secara visual langsung di layar.
  * **Preset Sudut:** Simpan sudut rotasi panah favorit Anda untuk mempercepat proses editing.

### 🔒 Privasi & Ekspor Data

  * **100% Offline:** Semua data (gambar, JSON, struktur folder) disimpan secara lokal di perangkat Anda dalam folder `.buildings`.
  * **Ekspor Fleksibel:** Fitur untuk mengekspor tampilan peta (screenshot PNG), file gambar asli, atau ikon bangunan ke penyimpanan eksternal.

## 📱 Izin & Penyimpanan (Penting)

Aplikasi ini memerlukan akses penuh ke penyimpanan untuk memanipulasi struktur folder yang kompleks.

  * **Lokasi Penyimpanan:** Aplikasi akan meminta Anda memilih folder induk, lalu membuat folder sistem bernama `.buildings` di dalamnya.
  * **Android 11+ (API 30+):** Wajib memberikan izin **"All Files Access"** (Manage External Storage) agar aplikasi dapat membaca, menulis, dan memindahkan folder bangunan secara bebas.
  * **Android 10 ke bawah:** Memerlukan izin standar `READ/WRITE_EXTERNAL_STORAGE`.

## 🛠️ Teknologi yang Digunakan

Aplikasi ini dibangun menggunakan **Flutter** dengan pemanfaatan paket ekosistem Dart:

  * **Manajemen State:** `setState` & `ValueNotifier` (Native approach).
  * **File System:** `path_provider`, `file_picker` untuk manajemen direktori intensif.
  * **Grafis:** `CustomPainter` untuk efek *Cloud Transition* dan *Canvas* rendering.
  * **Permissions:** `permission_handler` & `device_info_plus` untuk logika izin Android yang kompleks.
  * **Interaktivitas:** `InteractiveViewer` & `GestureDetector` untuk zoom/pan peta dan ruangan.

## 🚀 Cara Instalasi

1.  **Prasyarat:** Pastikan [Flutter SDK](https://flutter.dev/docs/get-started/install) sudah terinstal.
2.  **Clone Repository:**
    ```bash
    git clone [URL_REPOSITORY_ANDA]
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

## 📂 Struktur Folder Proyek

  * `lib/main.dart`: Entry point aplikasi.
  * `lib/app_shell.dart`: UI Dashboard & Logika Slideshow.
  * `lib/app_settings.dart`: Singleton pengaturan global & Shared Preferences.
  * `lib/permission_helper.dart`: Helper khusus izin Android 11+.
  * `lib/features/`:
      * `world/`: Logika Peta Dunia.
      * `region/`: Manajemen Wilayah & Peta Wilayah.
      * `building/`: Manajemen Distrik, Bangunan, Gudang, dan Viewer Ruangan.
      * `objects/`: Logika Objek Rekursif & Editor Objek.
      * `settings/`: Pengaturan, Wallpaper Manager, dan Transisi Awan.

## 🤝 Kontribusi

Kontribusi sangat diterima\! Jika Anda menemukan *bug* atau memiliki ide fitur baru:

1.  Fork repositori ini.
2.  Buat branch fitur baru (`git checkout -b fitur-baru`).
3.  Commit perubahan Anda (`git commit -m 'Menambahkan fitur X'`).
4.  Push ke branch (`git push origin fitur-baru`).
5.  Buat Pull Request.

-----

Dibuat dengan ❤️ menggunakan Flutter.