# 🧠 Mind Palace Manager

**Mind Palace Manager** adalah aplikasi Flutter yang dirancang untuk membantu Anda membangun, memvisualisasikan, dan mengelola "Istana Pikiran" (Memory Palace) digital Anda.

Aplikasi ini mengimplementasikan teknik *Method of Loci* secara terstruktur dan mendalam, memungkinkan Anda menyimpan memori atau informasi dalam hierarki spasial—mulai dari Peta Dunia, Wilayah, hingga ke dalam objek spesifik di dalam ruangan secara rekursif.

## ✨ Fitur Utama

### 🌍 Hierarki Spasial & Manajemen

Kelola memori Anda dengan struktur yang mendalam:

1.  **Dunia:** Peta global yang memuat berbagai wilayah.
2.  **Wilayah (Region):** Area besar yang berisi distrik-distrik.
3.  **Distrik (District):** Area lokal yang berisi bangunan.
4.  **Bangunan (Building):** Tempat yang berisi ruangan-ruangan.
5.  **Ruangan (Room):** Lokasi visual utama tempat navigasi terjadi.
6.  **Objek (Recursive Objects):** Item di dalam ruangan yang bisa berupa **Wadah** (Container) atau **Lokasi Imersif** (bisa dimasuki lagi hingga kedalaman tak terbatas).

### 🏭 Bank Bangunan (Factory/Warehouse)

  * **Sistem Template:** Buat bangunan di "Gudang" (Bank) tanpa harus menempatkannya langsung di peta.
  * **Deploy & Retract:** Tempatkan (*Deploy*) bangunan dari Bank ke Distrik mana saja, atau tarik kembali (*Retract*) bangunan dari peta ke Bank untuk disimpan.
  * **Salin & Pindah:** Fitur untuk menyalin atau memindahkan bangunan antar Distrik dengan mudah.

### 🗺️ Editor Peta & Visualisasi

  * **Peta Interaktif:** Unggah gambar peta sendiri untuk Dunia, Wilayah, dan Distrik.
  * **Pin Kustom:** Tempatkan lokasi dengan sistem *Drag & Drop*. Kustomisasi bentuk Pin (Bulat/Kotak/Tanpa Latar), warna, ketebalan garis, hingga ikon (Teks/Emoji atau Gambar).
  * **Zoom & Pan:** Navigasi peta yang mulus dengan fitur zoom in/out.

### 🏠 Editor Ruangan & Navigasi Imersif

  * **Navigasi Visual:** Hubungkan ruangan satu dengan lainnya menggunakan sistem **Panah Navigasi** yang dapat diatur posisi dan arahnya (Atas, Bawah, Kiri, Kanan, Diagonal).
  * **Transisi Awan (Cloud Transition):** Efek transisi visual yang unik (membuka/menutup awan) saat berpindah antar peta atau ruangan untuk pengalaman yang lebih halus.
  * **Objek Interaktif:** Letakkan objek di atas gambar ruangan. Objek dapat disembunyikan atau dibuat transparan namun tetap dapat diklik.

### 🎨 Personalisasi Tampilan

  * **Wallpaper Dashboard:** Atur latar belakang menggunakan Warna Solid, Gradien, Gambar Statis, atau **Slideshow Otomatis**.
  * **Slideshow Cerdas:** Putar gambar ruangan secara otomatis dari Bangunan tertentu atau seluruh Distrik sebagai wallpaper dashboard.
  * **Efek Blur & Overlay:** Atur tingkat keburaman (blur) dan kegelapan overlay untuk kenyamanan visual.
  * **Tema Aplikasi:** Dukungan penuh untuk Mode Terang (Light) dan Gelap (Dark).

### 🔒 Privasi & Penyimpanan Lokal

  * **Sepenuhnya Offline:** Semua data (gambar, JSON, struktur folder) disimpan secara lokal di perangkat Anda. Anda memiliki kendali penuh atas folder penyimpanan.
  * **Export Data:** Ekspor tampilan peta (Screenshot PNG), gambar asli, atau ikon bangunan langsung ke folder pilihan Anda.

## 📱 Tangkapan Layar (Screenshots)

| Dashboard | Peta Distrik | Viewer Ruangan | Editor Objek |
|:---------:|:------------:|:--------------:|:------------:|
| *(Gambar)* | *(Gambar)* | *(Gambar)* | *(Gambar)* |

## 🛠️ Teknologi yang Digunakan

Aplikasi ini dibangun menggunakan **Flutter** dan memanfaatkan berbagai *package* ekosistem Dart:

  * **State Management:** `setState` & `ValueNotifier` untuk performa yang ringan.
  * **File System:**
      * `path_provider` & `path`: Manipulasi path file.
      * `file_picker`: Pemilihan gambar dan direktori sistem.
      * `permission_handler`: Manajemen izin Android yang kompleks.
  * **UI & UX:**
      * `device_info_plus`: Penyesuaian logika berdasarkan versi Android SDK.
      * `package_info_plus`: Menampilkan informasi versi aplikasi.
      * `url_launcher`: Membuka tautan eksternal.
      * **Custom Painters:** Digunakan untuk efek *Cloud Transition*.

## 🚀 Cara Instalasi & Menjalankan

1.  **Prasyarat:** Pastikan Anda telah menginstal [Flutter SDK](https://flutter.dev/docs/get-started/install).

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

### ⚠️ Catatan Penting: Izin Penyimpanan (Android)

Aplikasi ini didesain untuk memanipulasi file secara intensif. Pada saat pertama kali dijalankan, aplikasi akan meminta izin akses penyimpanan.

  * **Android 10 ke bawah:** Memerlukan izin `READ/WRITE_EXTERNAL_STORAGE`.
  * **Android 11 ke atas:** Memerlukan izin **Akses Semua File** (`MANAGE_EXTERNAL_STORAGE`) agar aplikasi dapat membaca dan menulis di folder `.buildings` yang Anda pilih di luar penyimpanan internal aplikasi (Scoped Storage).

## 📂 Struktur Folder Utama

  * `lib/main.dart`: Entry point.
  * `lib/app_shell.dart`: UI Dashboard utama & Slideshow logic.
  * `lib/app_settings.dart`: Singleton pengaturan global.
  * `lib/permission_helper.dart`: Logika permintaan izin Android.
  * `lib/features/`:
      * `world/`: Logika Peta Dunia.
      * `region/`: Manajemen Wilayah.
      * `building/`: Manajemen Distrik, Bangunan, Factory, dan Viewer.
      * `objects/`: Logika Objek Rekursif.
      * `settings/`: Pengaturan, About, dan Dialogs (Wallpaper, Warna, dll).

## 🤝 Kontribusi

Kontribusi sangat diterima\! Jika Anda menemukan bug atau memiliki ide fitur baru:

1.  Fork repositori ini.
2.  Buat branch fitur baru (`git checkout -b fitur-keren`).
3.  Commit perubahan Anda (`git commit -m 'Menambahkan fitur transisi awan'`).
4.  Push ke branch (`git push origin fitur-keren`).
5.  Buat Pull Request.

## 👨‍💻 Pengembang

**Frendy Rikal Gerung, S.Kom.**

  * Lulusan Universitas Negeri Manado.
  * [LinkedIn](https://linkedin.com/in/frendy-rikal-gerung-bb450b38a/)
  * Email: frendydev1@gmail.com

-----

Dibuat dengan ❤️ menggunakan Flutter.