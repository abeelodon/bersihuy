<div align="center">

# 🧹 Bersihuy

**Aplikasi Jasa Kebersihan Berbasis Flutter & Supabase**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white)
![TypeScript](https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)
![Midtrans](https://img.shields.io/badge/Midtrans-003366?style=for-the-badge&logo=data:image/png;base64,&logoColor=white)

Sistem layanan kebersihan end-to-end yang menghubungkan **Customer**, **Petugas**, dan **Admin** dalam satu platform terpadu.

</div>

---

## 📋 Daftar Isi

- [Gambaran Umum](#-gambaran-umum)
- [Role Pengguna](#-role-pengguna)
- [Teknologi](#-teknologi)
- [Fitur Utama](#-fitur-utama)
- [Struktur Folder](#-struktur-folder)
- [Database](#-database)
- [Instalasi & Setup](#-instalasi--setup)
- [Setup Midtrans Sandbox](#-setup-midtrans-sandbox)
- [Admin Web](#-admin-web)
- [Akun Demo](#-akun-demo)
- [Alur Demo](#-alur-demo)
- [Status Pengembangan](#-status-pengembangan)
- [Catatan Keamanan](#-catatan-keamanan)

---

## 🌟 Gambaran Umum

Bersihuy adalah aplikasi jasa kebersihan end-to-end dengan alur kerja:

```
Customer memilih layanan
  → Membuat pesanan & melakukan pembayaran (Midtrans Sandbox)
  → Admin melihat order masuk & assign petugas
  → Petugas menerima tugas & mulai pekerjaan
  → Petugas upload bukti before-after & checklist
  → Pesanan selesai
  → Customer melihat bukti, invoice & memberi review
```

> Project ini mendukung integrasi penuh dengan Supabase (Auth, Database, Storage, Realtime), pembayaran Midtrans Sandbox, dan role-based access control.

---

## 👥 Role Pengguna

### 🧑 Customer
- Register & login akun
- Melihat dan memesan layanan kebersihan
- Mengisi jadwal, alamat, dan catatan tambahan
- Pembayaran via Midtrans Sandbox
- Melacak status pesanan secara real-time
- Melihat invoice & bukti pekerjaan (before-after)
- Chat dengan petugas
- Memberikan rating & review setelah pekerjaan selesai
- Mengelola profil, nomor WhatsApp, dan alamat utama

### 👷 Petugas
- Login & melihat dashboard tugas
- Melihat detail tugas, info customer, dan alamat
- Navigasi Google Maps langsung dari aplikasi
- Chat dengan customer
- Mengubah status tugas (assigned → in_progress → completed)
- Upload foto bukti sebelum & sesudah pekerjaan
- Mengisi checklist pekerjaan

### 🛠️ Admin (Dashboard Web Next.js)
- Login ke dashboard admin berbasis web
- Melihat semua order masuk beserta status pembayaran & pekerjaan
- Assign petugas ke order
- Melihat detail order & bukti pekerjaan
- Melihat data petugas, layanan, produk/add-on, dan statistik operasional

---

## 🛠️ Teknologi

| Bagian | Teknologi |
|---|---|
| Mobile App (Customer & Petugas) | Flutter, Dart, Supabase Flutter SDK |
| Admin Web | Next.js, TypeScript, Tailwind CSS, Supabase JS |
| Backend & Database | Supabase PostgreSQL, Supabase Auth, Supabase Storage, Supabase Realtime |
| Serverless | Supabase Edge Functions (Deno) |
| Pembayaran | Midtrans Sandbox Snap |
| Navigasi | Google Maps URL via `url_launcher` |
| Upload Media | `image_picker` + Supabase Storage |

---

## ✨ Fitur Utama

### 🔐 Auth & Role Redirect
Login otomatis mengarahkan user sesuai role:

| Role | Redirect |
|---|---|
| `customer` | Customer App |
| `staff` | Petugas App |
| `admin` | Admin Dashboard |

> Register publik hanya untuk customer. Petugas & admin dibuat manual via Supabase Auth dan diatur melalui tabel `profiles`.

---

### 📦 Status Order

```
pending_payment → scheduled → assigned → in_progress → completed
                                                      ↘ cancelled
```

Setelah pembayaran berhasil: `payments.status = paid` & `orders.status = scheduled`

---

### 💳 Alur Pembayaran Midtrans Sandbox

```
Customer klik Bayar
  → Flutter memanggil Edge Function create-midtrans-transaction
  → Midtrans Snap terbuka
  → Customer menyelesaikan pembayaran sandbox
  → Midtrans mengirim webhook ke midtrans-notification
  → Supabase update payment & order
  → Customer diarahkan ke invoice/tracking
```

Edge Functions yang digunakan:
- `create-midtrans-transaction`
- `check-midtrans-payment`
- `midtrans-notification`

---

### 💬 Chat Customer ↔ Petugas

- Satu chat room per order
- Dukungan pesan teks, gambar, dan link Google Maps
- Realtime via Supabase Realtime
- Read receipt: `✓` terkirim · `✓✓` sudah dibaca

---

### 📸 Upload Bukti Pekerjaan

Foto disimpan di Supabase Storage bucket `task-proofs`.

Syarat penyelesaian tugas oleh petugas:
- [x] Upload foto **sebelum** pekerjaan
- [x] Upload foto **sesudah** pekerjaan
- [x] Checklist lengkap (area dibersihkan, lantai dipel, perabot dirapikan, sampah dibuang)

---

## 📁 Struktur Folder

```
bersihuy/
├── lib/
│   ├── core/
│   │   ├── config/          # Konfigurasi Supabase, environment
│   │   ├── constants/
│   │   ├── routes/
│   │   ├── services/
│   │   └── utils/
│   ├── features/
│   │   ├── auth/
│   │   ├── customer/
│   │   ├── staff/
│   │   ├── chat/
│   │   ├── payment/
│   │   └── admin/
│   ├── shared/
│   │   └── widgets/
│   └── main.dart
│
├── supabase/
│   ├── functions/
│   │   ├── create-midtrans-transaction/
│   │   ├── check-midtrans-payment/
│   │   ├── midtrans-notification/
│   │   └── _shared/
│   └── migrations/
│
├── admin_web/               # Dashboard Admin (Next.js)
│   ├── app/
│   ├── components/
│   ├── lib/
│   └── package.json
│
├── assets/images/
├── android/ · ios/ · web/ · windows/ · linux/ · macos/
├── pubspec.yaml
└── README.md
```

---

## 🗄️ Database

Tabel utama yang digunakan:

| Tabel | Fungsi |
|---|---|
| `profiles` | Data semua user (customer, staff, admin) |
| `services` | Daftar layanan kebersihan |
| `products` | Add-on layanan |
| `orders` | Pesanan customer |
| `order_items` | Item dalam pesanan |
| `payments` | Data & status pembayaran |
| `tasks` | Tugas petugas |
| `task_status_history` | Riwayat perubahan status tugas |
| `reviews` | Rating & ulasan dari customer |
| `complaints` | Keluhan customer |
| `chat_rooms` | Room chat per order |
| `chat_messages` | Pesan dalam chat |

Storage buckets: `task-proofs` · `chat-attachments`

---

## 🚀 Instalasi & Setup

### Prasyarat

Pastikan sudah menginstall:
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Dart SDK (sudah termasuk Flutter)
- Git
- VS Code / Android Studio
- Node.js (untuk admin web)
- Akun [Supabase](https://supabase.com)

```bash
# Cek instalasi Flutter
flutter doctor
```

---

### 1. Clone Repository

```bash
git clone https://github.com/abeelodon/bersihuy.git
cd bersihuy
```

### 2. Install Dependency Flutter

```bash
flutter pub get
```

### 3. Konfigurasi Supabase

Edit file konfigurasi Supabase:

```
lib/core/config/supabase_config.dart
```

Isi dengan **Supabase URL** dan **anon key** dari project Supabase kamu.

### 4. Jalankan Migration

Jalankan file SQL di folder `supabase/migrations/` melalui **Supabase SQL Editor** atau **Supabase CLI**.

Migration mencakup: staff operations, customer profile fields, chat tables, storage policies, dan RLS policies.

### 5. Setup Storage Bucket

Buat dua bucket di Supabase Storage:
- `task-proofs` — untuk foto bukti pekerjaan
- `chat-attachments` — untuk gambar dalam chat

### 6. Aktifkan Supabase Realtime

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
```

### 7. Jalankan Aplikasi

```bash
# Web
flutter run -d chrome

# Android emulator/device
flutter run
```

---

## 💰 Setup Midtrans Sandbox

### 1. Siapkan Akun Midtrans

1. Login ke [Midtrans Sandbox](https://sandbox.midtrans.com)
2. Ambil **Server Key** dan **Client Key**
3. Masukkan key ke Supabase Edge Function secrets

### 2. Deploy Edge Functions

```bash
supabase functions deploy create-midtrans-transaction --project-ref <PROJECT_REF>
supabase functions deploy check-midtrans-payment --project-ref <PROJECT_REF>
supabase functions deploy midtrans-notification --project-ref <PROJECT_REF> --no-verify-jwt
```

> ⚠️ `midtrans-notification` wajib di-deploy dengan flag `--no-verify-jwt` agar webhook Midtrans bisa masuk.

### 3. Set Notification URL

Di dashboard Midtrans → **Settings → Payment → Notification URL**, isi dengan:

```
https://<PROJECT_REF>.supabase.co/functions/v1/midtrans-notification
```

---

## 🖥️ Admin Web

Admin web berada di folder `admin_web/`.

```bash
cd admin_web

# Install dependency
npm install

# Buat file environment
cp .env.example .env.local
# Isi variabel Supabase di .env.local

# Jalankan
npm run dev
```

Admin web berjalan di: `http://localhost:3000`

---

## 👤 Akun Demo

| Role | Email | Password |
|---|---|---|
| Admin | admin@bersihuy.com | *(sesuaikan)* |
| Customer | customer@bersihuy.com | *(sesuaikan)* |
| Petugas | petugas@bersihuy.com | *(sesuaikan)* |
| Petugas 2 | petugas2@bersihuy.com | *(sesuaikan)* |

> Customer bisa register langsung dari aplikasi. Petugas & admin dibuat via Supabase Authentication, lalu role diatur di tabel `profiles`.

---

## 🎯 Alur Demo

<details>
<summary><b>Demo Customer</b></summary>

1. Register customer baru → Login
2. Lengkapi profil (nama, nomor WA, alamat)
3. Pilih layanan → Isi jadwal & alamat
4. Lanjut ke pembayaran → Bayar via Midtrans Sandbox
5. Lihat invoice & status pesanan

</details>

<details>
<summary><b>Demo Admin</b></summary>

1. Login ke admin web
2. Lihat order masuk → Buka detail order
3. Assign petugas ke order
4. Pantau status order & lihat bukti pekerjaan

</details>

<details>
<summary><b>Demo Petugas</b></summary>

1. Login sebagai petugas → Lihat tugas masuk
2. Buka detail tugas → Mulai tugas
3. Chat dengan customer & buka navigasi alamat
4. Upload foto before-after → Centang checklist
5. Selesaikan tugas

</details>

<details>
<summary><b>Demo Customer (Setelah Selesai)</b></summary>

1. Lihat tracking & bukti pekerjaan
2. Berikan rating & review
3. Lihat riwayat pesanan

</details>

---

## 📊 Status Pengembangan

**Status: Functional End-to-End MVP** ✅

| Fitur | Status |
|---|---|
| Supabase Auth berbasis role | ✅ |
| Customer register & login | ✅ |
| Customer order flow | ✅ |
| Midtrans Sandbox payment | ✅ |
| Auto payment status update | ✅ |
| Admin web dashboard | ✅ |
| Admin assign petugas | ✅ |
| Staff task workflow | ✅ |
| Upload bukti pekerjaan | ✅ |
| Customer tracking & invoice | ✅ |
| Review & rating | ✅ |
| Chat customer ↔ petugas | ✅ |
| Profile real data (Supabase) | ✅ |

---

## 🔒 Catatan Keamanan

File yang **JANGAN** di-push ke repository:

```
.env
.env.local
supabase/functions/.env
admin_web/.env.local
```

Pastikan `.gitignore` sudah mengabaikan semua file environment asli. Hanya `.env.example` yang boleh di-push sebagai referensi.

---

<div align="center">

Dibuat dengan ❤️ menggunakan Flutter & Supabase

</div>