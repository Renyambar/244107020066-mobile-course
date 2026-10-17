/// Model pesan push netral (domain murni Dart).
///
/// Dipakai baik oleh simulator maupun adapter FCM tanpa lapisan UI perlu tahu
/// sedang memakai backend yang mana.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, dynamic> data;
}

/// Backend push yang sedang aktif.
enum PushBackend { fcm, demo }

/// Status izin notifikasi.
enum PushPermission { unknown, granted, denied, provisional }
