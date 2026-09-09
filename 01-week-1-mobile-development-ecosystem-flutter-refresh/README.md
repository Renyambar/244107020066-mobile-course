### NAMA: RENY AMBARWATI
### NIM: 244107020066
### KELAS: TI-3F

### flutter --version
![](screenshots/default.png) 

<details>
<summary><h3> 1. Mini Assignment: Aplikasi Profil Mahasiswa</h3></summary>
<br>
<blockquote>

Aplikasi ini merupakan modifikasi dari *starter code* Flutter (Counter App) menjadi sebuah halaman profil sederhana menggunakan widget dasar seperti `Scaffold`, `AppBar`, `Column`, `Icon`, dan `Text`.

### Screenshot Tampilan Aplikasi
![](screenshots/modif.png)  

### Kendala Setup & Solusi
Selama proses konfigurasi awal, saya menemui beberapa kendala karena saya memilih untuk menggunakan Android SDK (Command Line Tools) tanpa menginstal Android Studio secara penuh guna menghemat RAM (kapasitas 8GB).

**Kendala:**
1. `flutter doctor` mendeteksi versi SDK yang terinstal (34.0.0) tidak sesuai dengan yang dibutuhkan oleh Flutter (meminta versi 36 dan BuildTools 28.0.3).
2. Terjadi error `BUILD FAILED` (exit value 1) saat proses merakit aplikasi ke HP (`assembleDebug`). Proses terhenti di bagian *Unzipping NDK*, kemungkinan akibat *timeout* atau terhalang persetujuan lisensi NDK.

**Solusi:**
1. Mengunduh komponen SDK spesifik yang diminta Flutter secara manual menggunakan command prompt PowerShell:  
   `.\sdkmanager.bat "platforms;android-36" "build-tools;28.0.3"`
2. Untuk mengatasi *build failed*, saya menyetujui ulang lisensi (`flutter doctor --android-licenses`), lalu membersihkan *cache build* yang macet menggunakan `flutter clean` dan `flutter pub get`. Setelah itu, proses `flutter run` dieksekusi kembali menggunakan koneksi internet yang lebih stabil hingga 100% berhasil masuk ke perangkat fisik.

</blockquote>
</details>

<br>

<details>
<summary><h3>2. Refleksi </h3></summary>
<br>
<blockquote>

**1. Kapan native lebih tepat dipilih daripada cross-platform?**
Pengembangan *native* (seperti Kotlin untuk Android atau Swift untuk iOS) lebih tepat dipilih ketika aplikasi sangat bergantung pada integrasi *hardware* tingkat rendah (seperti sensor khusus, Bluetooth tingkat lanjut, atau kamera dengan kustomisasi mendalam). *Native* juga unggul untuk aplikasi yang membutuhkan komputasi dan performa maksimal (misal: game 3D berat) atau ketika ukuran file aplikasi dituntut untuk sekecil mungkin.

**2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?**
Flutter menggunakan paradigma *Declarative UI*, yang berarti tampilan UI adalah representasi dari *state* pada waktu tertentu. Ketika ada perubahan *state* (data berubah), Flutter tidak memodifikasi komponen UI satu per satu secara manual. Sebaliknya, framework akan membangun ulang (*rebuild*) bagian *widget tree* yang terpengaruh oleh *state* tersebut sehingga UI yang baru secara otomatis mencerminkan kondisi data terkini.

**3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?**
Bagi tim, *commit* yang kecil dan spesifik sangat mempermudah proses *Code Review* dan pelacakan *bug*. Jika terjadi *error*, kita dapat melakukan *rollback* ke versi sebelumnya tanpa memengaruhi fitur lain yang sudah berjalan baik. Bagi *portfolio*, riwayat *commit* yang rapi menunjukkan profesionalitas, pemahaman *version control* yang matang, dan alur kerja (workflow) yang terstruktur, yang sangat dicari di industri *Software Engineering*.

</blockquote>
</details>

<br>


