# Kontrak Endpoint Backend — `POST /devices`

Modul meminta endpoint `POST /devices` **didokumentasikan**. Dokumen ini adalah
kontrak yang dipakai aplikasi Campus Notify untuk mendaftarkan *registration
token* FCM per pengguna.

> **Status saat ini:** backend belum ada, jadi pengiriman diarahkan ke
> `MockDeviceApi` (`lib/data/device_api.dart`) yang mencatat token terpotong dan
> membalas `200`. Begitu backend tersedia, cukup mengganti binding provider ke
> `RemoteDeviceApi` — kontrak di bawah ini tidak berubah.

---

## 1. Mendaftarkan token

```
POST /devices
Content-Type: application/json
Authorization: Bearer <access_token>
```

**Body:**

```json
{
  "fcm_token": "fcm_sim_a1b2c3_lz9k2p_abcd…",
  "platform": "android"
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `fcm_token` | `string` | ✅ | Registration token FCM **penuh** (hanya dikirim ke backend, tidak pernah ditampilkan ke UI/log) |
| `platform` | `string` | ✅ | `android` \| `ios` \| `web` |

**Respons sukses:**

```
HTTP/1.1 200 OK
Content-Type: application/json

{ "status": "registered", "platform": "android" }
```

**Aturan backend:**

- **Idempoten** atas `fcm_token`: token yang sama dikirim ulang (mis. saat
  `onTokenRefresh` atau login di perangkat yang sama) harus **memperbarui**
  baris lama, bukan membuat duplikat.
- Simpan relasi `user_id ↔ fcm_token ↔ platform ↔ updated_at`.
- Sebelum mengirim, backend sebaiknya membuang token yang sudah mati (respons
  FCM `UNREGISTERED` / `NOT_FOUND`).

## 2. Menghapus token (logout / akun dihapus)

```
DELETE /devices?fcm_token=<token>
Authorization: Bearer <access_token>
```

Agar pengguna yang keluar tidak lagi menerima notifikasi.

---

## 3. Kapan aplikasi memanggil endpoint ini

| Peristiwa | Pemanggilan | Bukti |
|---|---|---|
| `getToken()` berhasil | `POST /devices` | screenshot `04` |
| `onTokenRefresh` (token berubah) | `POST /devices` lagi dengan token baru | screenshot `05` |
| Logout | `DELETE /devices` | — |

**Penting:** `onTokenRefresh` **wajib** mengirim ke backend, bukan sekadar
mencetak ke log. FCM memutakhirkan token saat aplikasi di-reinstall, data
dihapus, atau rotasi keamanan berkala — tanpa listener ini backend menyimpan
token basi dan notifikasi berhenti tanpa error yang terlihat.

---

## 4. Keamanan

- Akses token dikirim sebagai header `Authorization: Bearer <access_token>`.
- **Refresh token tidak pernah** dikirim lewat query URL (tercatat di log
  server/proksi) — hanya lewat body POST HTTPS.
- Backend wajib memverifikasi access token sebelum menerima pendaftaran token,
  agar satu pengguna tidak bisa mendaftarkan token milik orang lain.
- Aplikasi menampilkan token **hanya 12 karakter pertama + `…`** di UI dan log
  (`shortToken()`); token penuh tidak pernah muncul di screenshot laporan.

---

## 5. Contoh implementasi sisi klien

```dart
// lib/data/device_api.dart
abstract class DeviceApi {
  Future<void> registerDevice({required String fcmToken});
}

class RemoteDeviceApi implements DeviceApi {
  RemoteDeviceApi(this._dio);
  final Dio _dio;

  @override
  Future<void> registerDevice({required String fcmToken}) => _dio
      .post<void>(
        '/devices',
        data: {'fcm_token': fcmToken, 'platform': defaultTargetPlatform.name},
      )
      .then((_) {});
}
```

## 6. Contoh implementasi sisi backend (referensi)

```js
// Node/Express — idempoten atas fcm_token
app.post('/devices', requireAuth, async (req, res) => {
  const { fcm_token, platform } = req.body;
  if (!fcm_token || !platform) return res.status(400).json({ error: 'invalid_body' });

  await db.device.upsert({
    where:  { fcmToken: fcm_token },
    update: { userId: req.user.id, platform, updatedAt: new Date() },
    create: { userId: req.user.id, fcmToken: fcm_token, platform },
  });
  res.status(200).json({ status: 'registered', platform });
});
```

---

## 7. Mengirim pesan dari backend (FCM HTTP v1)

Setelah token terdaftar, backend mengirim pesan gabungan `notification` + `data`:

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": { "route": "/pengumuman/3", "id": "3" }
  }
}
```

Aturan pemakaian:

- **Topik** (`topic`) → broadcast: semua mahasiswa, satu angkatan, satu UKM.
- **Token perangkat** (`token`) → pesan personal: nilai akhir, tagihan UKT,
  presensi — tidak boleh memakai topik karena topik bersifat publik bagi siapa
  pun yang Subscribe.
- Selalu kirim **gabungan** `notification` + `data`: `notification` untuk teks
  yang dibaca manusia, `data.route` untuk tujuan deep link saat diklik.
