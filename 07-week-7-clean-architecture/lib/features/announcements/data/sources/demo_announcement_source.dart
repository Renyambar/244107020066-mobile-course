/// Sumber data pengumuman contoh (pengganti API eksternal).
///
/// Mengembalikan **JSON mentah** seolah respons `GET /announcements`, sehingga
/// pemetaan JSON -> entity terjadi di `AnnouncementModel` (lapisan data), bukan
/// di domain maupun widget. Nanti tinggal mengganti kelas ini dengan sumber
/// berbasis Dio tanpa menyentuh use case / presentation.
class DemoAnnouncementSource {
  /// Delay agar state loading terlihat nyata di UI.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': '1',
        'title': 'Kuliah Pengganti Minggu Ini',
        'body': 'Kelas Mobile Development dipindah ke Ruang A2, Rabu 13.00 WIB.',
      },
      <String, dynamic>{
        'id': '2',
        'title': 'Uts Praktikum',
        'body':
            'UTS praktikum dilaksanakan di lab komputer Lt.3, bawa laptop sendiri.',
      },
      <String, dynamic>{
        'id': '3',
        'title': 'Jadwal Kuliah Berubah',
        'body': 'Kelas Mobile pindah ke Ruang A2 jam 13.00.',
      },
    ];
  }
}
