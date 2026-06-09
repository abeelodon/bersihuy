# Roadmap Pengerjaan Project Bersihuy

## Status Progress Saat Ini

Project Bersihuy sudah berhasil masuk tahap awal pengembangan Flutter.

### Progress yang Sudah Selesai

- [x] Flutter SDK sudah ter-install di `C:\src\flutter`
- [x] Flutter sudah bisa dicek menggunakan `flutter --version`
- [x] Project Flutter berhasil dibuat di folder:

```
C:\Users\ASUS\Documents\Bersihuy
```

- Folder bawaan Flutter sudah muncul:

```
android/
ios/
lib/
linux/
macos/
test/
web/
windows/
pubspec.yaml
```

- Aplikasi default Flutter sudah berhasil dijalankan di Chrome
- Project sudah siap untuk mulai dibuat struktur frontend Bersihuy

---

## Tahap 1 — Setup Project Flutter

### 1. Cek Flutter

```powershell
flutter --version
```

Jika Flutter belum terbaca, jalankan sementara:

```powershell
$env:Path += ";C:\src\flutter\bin"
```

Lalu cek lagi:

```powershell
flutter --version
```

### 2. Masuk ke Folder Project

```powershell
cd C:\Users\ASUS\Documents\Bersihuy
```

### 3. Jalankan Project di Chrome

```powershell
flutter run -d chrome
```

Jika aplikasi Flutter demo muncul di Chrome, berarti setup project sudah aman.

---

## Tahap 2 — Membuat Struktur Folder Frontend

Sebelum membuat folder, hentikan aplikasi yang sedang berjalan di terminal dengan menekan:

```
q
```

atau:

```
Ctrl + C
```

### 1. Buat Folder Utama

```powershell
mkdir lib\core, lib\shared, lib\features
mkdir lib\core\constants, lib\core\routes, lib\core\utils, lib\core\services
mkdir lib\shared\widgets
mkdir lib\features\auth, lib\features\customer, lib\features\staff, lib\features\admin, lib\features\payment
```

### 2. Buat Subfolder Auth

```powershell
mkdir lib\features\auth\models, lib\features\auth\providers, lib\features\auth\repositories, lib\features\auth\views
```

### 3. Buat Subfolder Customer

```powershell
mkdir lib\features\customer\booking, lib\features\customer\tracking, lib\features\customer\reviews, lib\features\customer\complaints, lib\features\customer\subscription, lib\features\customer\notifications
```

### 4. Buat Subfolder Staff

```powershell
mkdir lib\features\staff\tasks, lib\features\staff\execution
```

### 5. Buat Subfolder Admin

```powershell
mkdir lib\features\admin\dashboard, lib\features\admin\operations, lib\features\admin\reports, lib\features\admin\complaints
```

### 6. Buat Subfolder Payment

```powershell
mkdir lib\features\payment\repositories, lib\features\payment\views
```

### Struktur Folder Target

Setelah semua folder dibuat, struktur frontend Bersihuy akan menjadi seperti ini:

```
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   ├── routes/
│   ├── utils/
│   └── services/
│
├── shared/
│   └── widgets/
│
└── features/
    ├── auth/
    │   ├── models/
    │   ├── providers/
    │   ├── repositories/
    │   └── views/
    │
    ├── customer/
    │   ├── booking/
    │   ├── tracking/
    │   ├── reviews/
    │   ├── complaints/
    │   ├── subscription/
    │   └── notifications/
    │
    ├── staff/
    │   ├── tasks/
    │   └── execution/
    │
    ├── admin/
    │   ├── dashboard/
    │   ├── operations/
    │   ├── reports/
    │   └── complaints/
    │
    └── payment/
        ├── repositories/
        └── views/
```

---

## Tahap 3 — Membuat File Awal Frontend

Setelah folder selesai, langkah berikutnya adalah membuat file awal.

### File Core

```
lib/core/constants/app_colors.dart
lib/core/constants/app_text_styles.dart
lib/core/routes/app_routes.dart
lib/core/utils/currency_formatter.dart
lib/core/utils/date_helper.dart
lib/core/services/dummy_auth_service.dart
```

### File Shared Widgets

```
lib/shared/widgets/custom_button.dart
lib/shared/widgets/custom_text_field.dart
lib/shared/widgets/status_badge.dart
```

### File Auth

```
lib/features/auth/views/login_screen.dart
lib/features/auth/views/register_screen.dart
```

### File Customer

```
lib/features/customer/booking/views/service_list_screen.dart
lib/features/customer/booking/views/checkout_screen.dart
lib/features/customer/tracking/views/tracking_screen.dart
lib/features/customer/reviews/views/rating_screen.dart
lib/features/customer/complaints/views/complaint_screen.dart
lib/features/customer/subscription/views/subscription_screen.dart
lib/features/customer/notifications/views/notification_screen.dart
```

### File Staff

```
lib/features/staff/tasks/views/task_list_screen.dart
lib/features/staff/tasks/views/task_detail_screen.dart
lib/features/staff/execution/views/upload_proof_screen.dart
```

### File Admin

```
lib/features/admin/dashboard/views/admin_dashboard_screen.dart
lib/features/admin/operations/views/assign_staff_screen.dart
lib/features/admin/operations/views/manage_services_screen.dart
lib/features/admin/reports/views/operational_report_screen.dart
lib/features/admin/complaints/views/complaint_management_screen.dart
```

### File Payment

```
lib/features/payment/views/payment_screen.dart
lib/features/payment/views/invoice_screen.dart
```

---

## Tahap 4 — Fokus Pengerjaan UI

Urutan halaman yang dikerjakan:

1. Login Screen
2. Register Screen
3. Customer Home / Service List
4. Checkout Order
5. Payment / Invoice Dummy
6. Tracking Order
7. Rating dan Review
8. Complaint Screen
9. Subscription Screen
10. Staff Task List
11. Staff Task Detail
12. Upload Proof Screen
13. Admin Dashboard
14. Assign Staff
15. Manage Services
16. Operational Report
17. Complaint Management

---

## Tahap 5 — Gunakan Dummy Data Dulu

Untuk tahap frontend awal, backend Supabase belum perlu dibuat. Data sementara menggunakan dummy repository.

Contoh file dummy data:

```
lib/features/customer/booking/repositories/dummy_service_data.dart
lib/features/staff/tasks/repositories/dummy_task_data.dart
lib/features/admin/operations/repositories/dummy_order_data.dart
```

Tujuannya agar UI bisa berjalan dulu tanpa database. Nanti ketika Supabase sudah siap, data dummy tinggal diganti menjadi query Supabase.

---

## Tahap 6 — Testing Tampilan Mobile dari Laptop

Karena belum memakai HP Android, tampilan mobile bisa dites lewat Chrome. Saat aplikasi Flutter berjalan di Chrome:

```
F12
Ctrl + Shift + M
```

Lalu pilih ukuran device seperti:

```
Pixel 7
Samsung Galaxy S20
iPhone 12 Pro
```

Dengan cara ini, UI bisa dibuat menyerupai tampilan HP.

---

## Tahap 7 — Setup Backend Supabase

Tahap backend dilakukan setelah UI dasar selesai. Backend Supabase nantinya berisi:

```
Supabase Auth
Supabase PostgreSQL
Supabase Storage
Supabase Realtime
Supabase Edge Functions
Supabase Cron / pg_cron
RLS Policy
```

Struktur backend nanti:

```
supabase/
├── functions/
│   ├── payment-webhook/
│   └── push-notification/
├── migrations/
├── seed.sql
└── config.toml
```

> Backend tidak perlu dibuat di awal jika fokus utama sekarang adalah frontend.

---

## Tahap 8 — Integrasi Frontend dengan Supabase

Setelah UI dummy selesai, baru mulai integrasi Supabase. Urutan integrasi:

1. Login dan register menggunakan Supabase Auth
2. Ambil daftar layanan dari tabel `services`
3. Buat order ke tabel `orders`
4. Buat data pembayaran ke tabel `payments`
5. Generate invoice ke tabel `invoices`
6. Tracking status order secara realtime
7. Admin assign petugas ke tabel `order_tasks`
8. Petugas update status pekerjaan
9. Petugas upload foto before-after ke Supabase Storage
10. Customer memberi review
11. Customer membuat complaint
12. Admin menangani complaint
13. Subscription kos berjalan dengan scheduler

---

## Tahap 9 — Build APK untuk Tes Android

Jika aplikasi sudah siap dites di HP Android teman:

```powershell
flutter build apk
```

Hasil file APK biasanya berada di:

```
build/app/outputs/flutter-apk/app-release.apk
```

File tersebut bisa dikirim ke HP teman untuk di-install.

---

## Catatan Penting

### ❌ Jangan Dihapus

Folder bawaan Flutter ini jangan dihapus:

```
android/
ios/
web/
windows/
linux/
macos/
pubspec.yaml
```

### ✅ Yang Boleh Diedit

Folder utama yang akan sering dikerjakan:

```
lib/
```

File utama yang nanti akan diganti:

```
lib/main.dart
```

### ⏳ Backend Belakangan

Untuk saat ini tidak perlu membuat folder:

```
supabase/
```

Folder tersebut dibuat nanti ketika backend mulai dikerjakan.

---

## Posisi Saat Ini

Saat ini project berada di tahap:

```
✅ Flutter project berhasil dibuat
✅ Flutter berhasil dijalankan di Chrome
➡️ Langkah berikutnya: membuat struktur folder frontend
```

### Next Action

```powershell
mkdir lib\core, lib\shared, lib\features
```