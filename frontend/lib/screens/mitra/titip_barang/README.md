# Struktur Refactoring - Mitra Titip Barang

## Struktur Folder

```
titip_barang/
├── pages/
│   ├── create_titip_barang_page.dart      # Main page (cleaned up)
│   └── create_titip_barang_page_old.dart  # Backup file lama
├── widgets/
│   ├── location_section.dart              # Widget untuk section lokasi (awal & tujuan)
│   ├── selection_card.dart                # Reusable card untuk tanggal, jam, dll
│   └── transportation_dialog.dart         # Dialog pemilihan transportasi
└── utils/
    └── helpers.dart                       # Helper functions (format, label)
```

## Komponen yang Dibuat

### 1. **LocationSection Widget**
- Menangani tampilan lokasi awal dan tujuan
- Includes garis pemisah vertikal dan horizontal
- Props: originLocationName, destinationLocationName, callbacks

### 2. **TitipBarangSelectionCard Widget**
- Reusable card untuk semua selection (tanggal, jam, bagasi, transportasi)
- Props: icon, iconColor, title, subtitle, onTap

### 3. **TransportationDialog Widget**
- Dialog khusus untuk memilih transportasi
- Static method `show()` untuk mudah dipanggil
- Menampilkan 3 pilihan: Kereta, Pesawat, Bus

### 4. **TitipBarangHelpers Class**
- `getTransportationLabel()` - Convert value ke label
- `getBagasiLabel()` - Convert capacity ke label
- `formatDate()` - Format tanggal
- `formatTime()` - Format waktu

## Manfaat Refactoring

✅ **Kode lebih pendek** - Main page dari ~640 lines → ~350 lines
✅ **Mudah maintain** - Setiap komponen terpisah
✅ **Reusable** - Widget bisa dipakai di tempat lain
✅ **Terorganisir** - Folder structure yang jelas
✅ **Testable** - Setiap komponen bisa di-test terpisah

## Cara Menerapkan ke Halaman Lain

Struktur yang sama bisa diterapkan ke:
- `create_tebengan_motor/`
- `create_tebengan_mobil/`
- `create_tebengan_barang/`

Dengan membuat folder widgets, utils, dan memecah komponen yang sama.
