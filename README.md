# 🏛️ Mind Palace Manager

Selamat datang di **Mind Palace Manager**! Sebuah aplikasi Flutter yang dirancang untuk membantu Anda membangun, mengelola, dan menjelajahi "Istana Pikiran" (Mind Palace) Anda sendiri.

Aplikasi ini mengubah konsep kuno *Method of Loci* menjadi pengalaman digital, memungkinkan Anda membuat "Bangunan" virtual yang diisi dengan "Ruangan", lengkap dengan gambar isometrik dan navigasi yang terhubung.

[Video/GIF Demo Aplikasi Anda Sedang Beraksi Di Sini]
*(Sangat disarankan untuk menambahkan GIF singkat yang menunjukkan alur penggunaan dari editor ke viewer)*

---

## ✨ Fitur Utama

* **Manajemen Bangunan:** Buat, edit, dan hapus "Bangunan" (proyek) dengan mudah.
* **Editor Ruangan Visual:**
    * Buat ruangan tak terbatas di dalam setiap bangunan.
    * Unggah **gambar kustom** (seperti seni isometrik) untuk setiap ruangan.
    * Atur **urutan ruangan** dengan mudah menggunakan mode "Pindah" (drag-and-drop).
* **Navigasi Cerdas:**
    * Buat "Pintu" (koneksi) antar ruangan.
    * **Label Otomatis:** Jika label pintu tidak diisi, nama ruangan tujuan akan digunakan secara otomatis.
    * **Navigasi Balik:** Aplikasi akan secara otomatis menawarkan untuk membuat pintu kembali ke ruangan asal, menghemat waktu Anda.
* **Penjelajah Imersif (Viewer):**
    * Masuk ke mode "Lihat" untuk menjelajahi istana pikiran Anda.
    * Gambar ruangan ditampilkan **penuh** dan dapat di-**zoom** (`InteractiveViewer`).
    * Navigasi antar ruangan dilakukan secara instan melalui **menu dropdown** yang intuitif.
* **Penyimpanan Lokal:**
    * Lokasi penyimpanan folder utama **disimpan secara permanen** (menggunakan `shared_preferences`).
    * Semua data bangunan, ruangan, dan gambar disimpan secara lokal di perangkat Anda dalam struktur folder dan file `data.json` yang rapi.

---

## 🚀 Alur Penggunaan (Penting!)

Untuk memulai, ikuti langkah-langkah berikut:

1.  **Pengaturan Awal (Hanya Sekali):**
    * Buka aplikasi dan pergi ke menu **"Buka Pengaturan"**.
    * Pilih lokasi folder utama di perangkat Anda. Aplikasi akan membuat folder `buildings` di sana. (Contoh: `.../Documents/buildings`).
    * *Path ini akan diingat selamanya (atau sampai diubah lagi).*

2.  **Buat Bangunan:**
    * Kembali ke Dashboard, pilih **"Kelola Bangunan"**.
    * Tekan tombol `+` untuk membuat "Bangunan" baru (misal: "Rumah").

3.  **Edit Ruangan (Ikon Pensil ✏️):**
    * Tekan tombol `+` untuk **membuat Ruangan** baru (misal: "Ruang Tamu") dan unggah gambar.
    * **Mode Navigasi (Default):** Tekan ikon **link (🔗)** pada ruangan untuk mengatur pintu keluar.
    * **Mode Pindah:** Tekan ikon **pindah (↕️)** di AppBar untuk mengaktifkan mode urutkan. Geser ruangan ke urutan yang Anda inginkan.

4.  **Jelajahi (Ikon Mata 👁️):**
    * Kembali ke daftar bangunan, tekan ikon "Lihat" (mata) pada bangunan Anda.
    * Aplikasi akan memulai di ruangan pertama.
    * Gunakan **gambar** untuk melihat (dan zoom) dan **dropdown "Pintu"** untuk berpindah.

---

## 📁 Struktur Data & Proyek

Aplikasi ini mengelola file secara langsung di perangkat Anda. Saat Anda membuat bangunan bernama **"Rumah"**:

```

Lokasi\_Pilihan\_Anda/
└── buildings/
└── Rumah/                \<-- Ini adalah 'buildingDirectory'
├── data.json         \<-- File JSON yang berisi semua data ruangan & koneksi
├── ruang\_tamu.png    \<-- Gambar yang Anda unggah disalin ke sini
└── kamar\_tidur.png   \<-- Gambar lain

````

Struktur `data.json` terlihat seperti ini:

```json
{
  "rooms": [
    {
      "id": "1678886400000",
      "name": "Ruang Tamu",
      "image": "ruang_tamu.png",
      "connections": [
        {
          "id": "1678886450000",
          "label": "Ke Kamar Tidur",
          "targetRoomId": "1678886430000"
        }
      ]
    },
    {
      "id": "1678886430000",
      "name": "Kamar Tidur",
      "image": "kamar_tidur.png",
      "connections": [
        {
          "id": "1678886460000",
          "label": "Ruang Tamu",
          "targetRoomId": "1678886400000"
        }
      ]
    }
  ]
}
````

-----

## 🔧 Cara Menjalankan Secara Lokal

Proyek ini adalah aplikasi Flutter murni.

1.  Pastikan Anda memiliki [Flutter SDK](https://flutter.dev/docs/get-started/install) terinstal.
2.  Clone repositori ini:
    ```bash
    git clone [URL_REPO_ANDA]
    cd mind_palace_manager
    ```
3.  Instal dependensi:
    ```bash
    flutter pub get
    ```
4.  Jalankan aplikasi:
    ```bash
    flutter run
    ```

### Dependensi Utama

  * `flutter`
  * `file_picker` (Untuk memilih gambar & folder)
  * `path` (Untuk manajemen path file)
  * `shared_preferences` (Untuk menyimpan path pengaturan utama)

-----

Dibuat dengan ❤️ dan Flutter.

```
```