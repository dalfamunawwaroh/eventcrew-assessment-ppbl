# 📋 PANDUAN INTEGRASI PROFILE PAGE

## 📌 File yang Dibuat
- **`lib/screens/profile_page.dart`** - Halaman profil panitia dengan CRUD lengkap

---

## 🔌 CARA MENGHUBUNGKAN IKON PROFIL DI HOME SCREEN

### Langkah 1: Tambahkan Import di `home_screen.dart`

Buka file [home_screen.dart](lib/screens/home_screen.dart) dan tambahkan import berikut di paling atas (sebelum class HomeScreen):

```dart
import 'profile_page.dart';  // ← Tambahkan baris ini
```

**Contoh lokasi import:**
```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../helpers/prefs_helper.dart';
import 'event_detail_screen.dart';
import 'profile_page.dart';  // ← TAMBAHKAN DI SINI
```

---

### Langkah 2: Ganti Fungsi Avatar di Header

Cari bagian kode di `_buildCustomHeader()` yang berisi **`GestureDetector` dengan `CircleAvatar` untuk avatar**.

**Kode lama (baris ~320):**
```dart
GestureDetector(
  onTap: () {
    String newRole = _role == 'Ketuplak' ? 'Anggota' : 'Ketuplak';
    PrefsHelper.setUserRole(newRole);
    setState(() { _role = newRole; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Switched to $newRole mode'), duration: const Duration(seconds: 1)));
  },
  child: CircleAvatar(
    radius: 24,
    backgroundColor: Colors.white,
    child: Icon(Icons.person, color: headerColor, size: 30),
  ),
),
```

**Ganti dengan (kode baru):**
```dart
GestureDetector(
  onTap: () {
    /// Navigasi ke ProfilePage saat ikon profil ditekan
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) {
      /// Ketika kembali dari ProfilePage, refresh data dari SharedPreferences
      setState(() {
        _userName = PrefsHelper.userName;
        _role = PrefsHelper.userRole;
      });
    });
  },
  child: CircleAvatar(
    radius: 24,
    backgroundColor: Colors.white,
    child: Icon(Icons.person, color: headerColor, size: 30),
  ),
),
```

---

### Langkah 3: Verifikasi Perubahan

Setelah mengganti kode, **struktur header akan menjadi seperti ini:**
- ✅ Nama pengguna ditampilkan dari `_userName` (dari SharedPreferences)
- ✅ Status role ditampilkan dari `_role` (dari SharedPreferences)  
- ✅ Ikon profil di pojok kanan atas dapat diklik
- ✅ Saat diklik, akan membuka `ProfilePage`
- ✅ Setelah ditutup, data otomatis ter-refresh

---

## 🎯 FITUR PROFILE PAGE

### READ (Membaca Data)
Saat halaman ProfilePage dibuka, data akan otomatis dibaca dari **SharedPreferences**:
- **Nama Pengguna**: `PrefsHelper.userName`
- **Role/Jabatan**: `PrefsHelper.userRole`

```dart
void _loadUserData() {
  _nameController = TextEditingController(text: PrefsHelper.userName);
  _selectedRole = PrefsHelper.userRole;
}
```

### CREATE & UPDATE (Menyimpan Data)
Tombol **"Simpan Perubahan"** akan:
1. Validasi nama tidak kosong
2. Simpan ke SharedPreferences: `PrefsHelper.setUserName()`
3. Simpan role ke SharedPreferences: `PrefsHelper.setUserRole()`
4. Tampilkan konfirmasi berhasil
5. Kembali ke home screen → data otomatis ter-update

```dart
Future<void> _saveUserProfile() async {
  await PrefsHelper.setUserName(_nameController.text);
  await PrefsHelper.setUserRole(_selectedRole);
  // Kembali dan trigger refresh di home screen
  Navigator.pop(context);
}
```

### DELETE (Menghapus Data)
Tombol **"Hapus Data Profil"** akan:
1. Tampilkan dialog konfirmasi
2. Reset nama ke 'Pengguna'
3. Reset role ke 'Anggota'
4. Kembali ke home screen → data ter-reset

```dart
Future<void> _performDelete() async {
  await PrefsHelper.setUserName('Pengguna');
  await PrefsHelper.setUserRole('Anggota');
  Navigator.pop(context);
}
```

---

## 🎨 DESAIN & VISUAL

### Header Section (Bagian Atas)
- ✅ Gradient biru tua ke biru cerah (Deep Blue theme)
- ✅ Avatar lingkaran besar dengan inisial nama dan gradient amber-orange
- ✅ Badge status "Workspace Ketuplak" atau "Workspace Anggota"

### Content Section (Bagian Tengah)
- ✅ Form input nama dengan ikon person
- ✅ Dropdown role dengan opsi: "Ketuplak" / "Anggota"
- ✅ Card foto profil dengan tombol pilih/hapus
- ✅ Semua card memiliki rounded corners dan shadow lembut

### Action Buttons (Bagian Bawah)
- ✅ **Tombol Simpan Perubahan** - Biru (sesuai theme)
- ✅ **Tombol Hapus Data Profil** - Merah soft (#EF6B6B)

---

## 📸 FITUR FOTO PROFIL (OPTIONAL - Untuk Pengembangan Lebih Lanjut)

Saat ini, fitur foto profil menampilkan **avatar dengan inisial dan gradient**. 

Jika ingin menambahkan fitur upload foto dari galeri/kamera, Anda perlu:

### 1. Tambahkan Package di `pubspec.yaml`
```yaml
dev_dependencies:
  image_picker: ^1.0.0
  path_provider: ^2.1.1
```

Jalankan: `flutter pub get`

### 2. Update Profile Page

Tambahkan di bagian atas `profile_page.dart`:
```dart
import 'package:image_picker/image_picker.dart';
import 'dart:io';
```

Ubah `_showPhotoActionDialog()` untuk menggunakan ImagePicker:
```dart
void _showPhotoActionDialog() {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pilih Sumber Foto'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _pickImage(ImageSource.camera);
          },
          child: const Text('Kamera'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            _pickImage(ImageSource.gallery);
          },
          child: const Text('Galeri'),
        ),
      ],
    ),
  );
}

Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source);
  
  if (pickedFile != null) {
    // Simpan path ke SharedPreferences
    await PrefsHelper.setUserProfilePhoto(pickedFile.path);
    setState(() {});
    _showSuccessSnackBar('Foto profil berhasil diperbarui!');
  }
}
```

---

## ✅ CHECKLIST INTEGRASI

- [ ] Import `profile_page.dart` di `home_screen.dart`
- [ ] Ganti kode GestureDetector avatar dengan Navigator.push
- [ ] Test: Klik ikon profil di home screen
- [ ] Test: Form input nama berfungsi
- [ ] Test: Dropdown role dapat dipilih
- [ ] Test: Tombol simpan mengupdate SharedPreferences
- [ ] Test: Kembali ke home screen → nama & role ter-update
- [ ] Test: Tombol hapus mereset data dengan benar

---

## 🐛 TROUBLESHOOTING

### Data tidak ter-update di home screen setelah kembali dari ProfilePage?
**Solusi**: Pastikan Anda menggunakan `.then()` setelah `Navigator.push()`:
```dart
Navigator.push(...).then((_) {
  setState(() {
    _userName = PrefsHelper.userName;
    _role = PrefsHelper.userRole;
  });
});
```

### Avatar tidak menampilkan inisial dengan benar?
**Solusi**: Fungsi `_getInitials()` akan otomatis ambil huruf pertama setiap kata:
- "Esa Putri" → "EP"
- "John Doe" → "JD"
- Jika kosong → "?"

### Foto profil tidak tersimpan?
**Solusi**: Fitur foto saat ini bersifat placeholder/demo. Untuk implementasi penuh, tambahkan package `image_picker` (lihat section FOTO PROFIL di atas).

---

## 📝 RINGKASAN LOGIKA CRUD

| Operasi | File | Fungsi | Simpan Ke |
|---------|------|--------|-----------|
| **READ** | profile_page.dart | `_loadUserData()` | Baca dari SharedPreferences |
| **CREATE/UPDATE** | profile_page.dart | `_saveUserProfile()` | Simpan ke SharedPreferences |
| **DELETE** | profile_page.dart | `_performDelete()` | Reset ke default |

---

## 🎓 BEST PRACTICES

1. **Jangan ubah logika database (DatabaseHelper, tugas, budget)** - ProfilePage hanya handle user profile
2. **Selalu validasi input** - Nama tidak boleh kosong
3. **Gunakan SharedPreferences** - Sudah ada helper class `PrefsHelper`
4. **Reactive Update** - Gunakan `.then()` setelah Navigator.push agar data ter-refresh
5. **User Feedback** - Gunakan SnackBar untuk notifikasi sukses/error

---

Selamat! 🎉 Profile page siap diintegrasikan!
