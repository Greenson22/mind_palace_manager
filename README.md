# 🧠 Mind Palace Manager

**Mind Palace Manager** adalah aplikasi Flutter canggih yang dirancang untuk membantu Anda membangun, memvisualisasikan, dan mengelola "Istana Pikiran" (Memory Palace) digital Anda secara offline, aman, dan kini dilengkapi dengan **alat kreatifitas bawaan**.

Aplikasi ini tidak hanya mengimplementasikan teknik *Method of Loci* melalui hierarki spasial (Dunia -> Wilayah -> Distrik -> Bangunan -> Ruangan), tetapi juga memberikan Anda kebebasan untuk **mendesain sendiri** denah lantai dan **menggambar** aset visual tanpa perlu keluar dari aplikasi.

## ✨ Fitur Baru (Update Terkini)

### 🏠 Plan Architect (Arsitek Denah)
Editor vektor *powerful* untuk membuat denah lantai dan struktur bangunan yang presisi.
* **Alat Struktur Lengkap:** Gambar Tembok (*Walls*), Pintu, dan Jendela dengan pengukuran otomatis (meter).
* **Pustaka Bentuk & Simbol:** Akses puluhan bentuk siap pakai (Panah, Simbol Flowchart, Furnitur, Poligon) untuk memperkaya visual denah.
* **Manajemen Objek:** Dukungan *Multi-select*, *Grouping/Ungrouping*, Rotasi, Flip (Cermin), dan pengaturan Layer.
* **Kustomisasi Tampilan:** Ubah warna kanvas, aktifkan *Grid/Snap*, dan atur background denah (Solid, Gradien, atau Gambar dengan efek Blur).
* **Ekspor:** Simpan hasil desain denah Anda sebagai gambar PNG berkualitas tinggi.

### 🎨 Pixel Studio
Kanvas *pixel art* terintegrasi untuk membuat ikon atau aset visual unik Anda sendiri.
* **Alat Gambar:** Pensil, Penghapus, dan *Hand tool* untuk navigasi.
* **Shape Tools:** Buat Garis, Kotak, dan Lingkaran dengan presisi piksel.
* **Kontrol Penuh:** *Zoom* mendalam, *Undo/Redo*, dan pemilih warna (Color Picker).

### 🏢 Manajemen Multi-Lantai (Multi-Plan)
Bangunan tipe "Denah" kini mendukung struktur bertingkat yang kompleks.
* **Banyak Lantai:** Satu bangunan dapat menampung banyak file denah (Lantai 1, Lantai 2, Atap, dll).
* **Manajemen Fleksibel:** Buat baru, duplikasi (*copy*) denah yang sudah ada, ganti nama, dan atur urutan lantai (*Reorder*).
* **Navigasi Antar Denah:** Hubungkan objek di satu lantai untuk melompat ke lantai lain secara interaktif.

---

## 🌍 Fitur Utama Lainnya

### Hierarki Spasial Mendalam
Kelola memori Anda dalam struktur yang logis:
1.  **Dunia & Wilayah:** Peta global yang memuat area-area besar.
2.  **Distrik:** Area lokal tempat Anda menata bangunan.
3.  **Bangunan & Ruangan:** Lokasi visual utama.
4.  **Objek Rekursif:** Item dalam ruangan bisa berupa **Wadah** (Container) atau **Lokasi Imersif** yang bisa dimasuki lagi tanpa batas kedalaman.

### 🏭 Bank Bangunan (Gudang)
* **Sistem Template:** Buat bangunan di "Gudang" tanpa harus menempatkannya langsung di peta.
* **Deploy & Retract:** Tempatkan bangunan dari Bank ke Distrik mana saja, atau tarik kembali bangunan dari peta untuk disimpan.
* **Kloning:** Salin bangunan beserta seluruh isinya antar Distrik dengan mudah.

### ☁️ Visualisasi & Transisi
* **Cloud Transition:** Efek transisi prosedural (awan membuka/menutup) saat berpindah lokasi.
* **Personalisasi Dashboard:** Atur wallpaper dengan mode Warna Solid, Gradien, Gambar Statis, atau **Slideshow** otomatis dari galeri ruangan Anda.
* **Kustomisasi Pin:** Ubah bentuk Pin peta, warna, outline, hingga penggunaan ikon kustom.

### 🛠️ Editor Peta & Navigasi (WYSIWYG)
* **Peta Interaktif:** Unggah gambar peta sendiri dan tempatkan lokasi (*Pin*) dengan sistem *Drag & Drop*.
* **Editor Navigasi Ruangan:** Hubungkan ruangan menggunakan panah navigasi. Atur posisi dan rotasi panah secara visual.
* **Preset Rotasi:** Simpan sudut rotasi favorit Anda untuk mempercepat penataan navigasi.

### 🔒 Privasi & Keamanan Data
* **100% Offline:** Seluruh data (gambar, JSON, struktur folder) disimpan lokal di perangkat Anda dalam folder `.buildings`.
* **Izin Penyimpanan:** Aplikasi memerlukan akses penuh ke penyimpanan (*Manage External Storage* pada Android 11+) untuk mengelola struktur folder yang kompleks secara real-time.

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

* `lib/main.dart`: Entry point.
* `lib/features/`:
    * `plan_architect/`: Editor denah vektor (Logic, Mixins, Painters, Widgets).
    * `pixel_studio/`: Editor pixel art.
    * `world/` & `region/`: Logika peta makro.
    * `building/`: Manajemen bangunan, editor ruangan, dan viewer.
    * `objects/`: Logika objek rekursif.
    * `settings/`: Pengaturan aplikasi dan wallpaper.
* `lib/app_settings.dart`: Singleton pengaturan global.

## 🤝 Kontribusi

Kontribusi sangat diterima! Jika Anda menemukan *bug* atau memiliki ide fitur baru, silakan buat *Pull Request* atau laporkan *Issue*.

-----
Dibuat dengan ❤️ menggunakan Flutter.