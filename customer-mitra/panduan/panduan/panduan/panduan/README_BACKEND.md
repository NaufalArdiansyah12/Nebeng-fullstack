# 🚀 Nebeng Admin - Full Backend Setup Complete

Saya sudah membuat **backend lengkap dengan MySQL database** untuk aplikasi Anda. Sekarang Anda tinggal membuat database di MySQL!

## 📦 Apa yang Sudah Dibuat

### 1. **Backend Server** (Node.js + Express + TypeScript)
- ✅ Server API lengkap di `backend/src/`
- ✅ 6 API routes (admin, customer, mitra, pesanan, laporan, refund)
- ✅ Error handling & CORS configuration
- ✅ TypeScript untuk type safety

### 2. **MySQL Database Schema** 
Siap pakai di `backend/database/schema.sql`:
- ✅ 10 tables lengkap dengan relasi
- ✅ Sample data untuk testing
- ✅ Indexes untuk performance
- ✅ Foreign keys untuk integrity

### 3. **Frontend API Service**
- ✅ `src/services/api.ts` - Axios client configured
- ✅ Semua API functions sudah siap pakai
- ✅ Example usage di `src/services/api.examples.tsx`
- ✅ Updated context dengan API integration

### 4. **Documentation**
- ✅ `SETUP_GUIDE.md` - Panduan setup lengkap
- ✅ `INTEGRATION_GUIDE.md` - Cara integrasi ke frontend
- ✅ `backend/README.md` - Quick reference

## ⚡ Quick Start (3 Langkah)

### Step 1: Setup MySQL Database

**Di MySQL Workbench atau CLI:**

```bash
mysql -u root -p < backend/database/schema.sql
```

atau manual:
1. Buka MySQL Workbench
2. Copy isi `backend/database/schema.sql`
3. Run di MySQL

**Default Data:**
- Admin: Abdul000@gmail.com
- 3 Sample Customers
- 3 Sample Mitra dengan Kendaraan

### Step 2: Configure Backend

```bash
cd backend
npm install

# Buat file .env (copy dari .env.example)
cp .env.example .env

# Edit .env dengan MySQL credentials:
# DB_USER=root
# DB_PASSWORD=your_password
# DB_NAME=nebeng_admin
```

### Step 3: Start Backend

```bash
npm run dev
```

Server akan jalan di `http://localhost:3001` ✅

## 📁 Folder Structure

```
project-root/
├── backend/                      # Backend Baru! 🆕
│   ├── src/
│   │   ├── routes/              # API endpoints
│   │   │   ├── admin.routes.ts
│   │   │   ├── customer.routes.ts
│   │   │   ├── mitra.routes.ts
│   │   │   ├── pesanan.routes.ts
│   │   │   ├── laporan.routes.ts
│   │   │   └── refund.routes.ts
│   │   └── server.ts            # Express server
│   ├── database/
│   │   └── schema.sql           # MySQL schema
│   ├── .env.example
│   ├── package.json
│   └── tsconfig.json
│
├── src/
│   ├── services/
│   │   ├── api.ts              # ✨ Updated! API client
│   │   └── api.examples.tsx    # ✨ New! Examples
│   ├── contexts/
│   │   └── CustomerContext-API.tsx  # ✨ New! API context
│   └── ... (existing files)
│
├── SETUP_GUIDE.md              # 📖 Setup documentation
├── INTEGRATION_GUIDE.md        # 📖 Integration guide
└── .env.example               # ✨ Updated
```

## 🔌 API Features

Semua ready to use:

```typescript
// Customers
await customerApi.getAll()           // Get semua
await customerApi.getById(id)        // Get one
await customerApi.create(data)       // Buat baru
await customerApi.update(id, data)   // Update
await customerApi.block(id)          // Block
await customerApi.unblock(id)        // Unblock

// Mitra/Driver
await mitraApi.getAll()              // Get semua
await mitraApi.getKendaraan(id)      // Get vehicles
await mitraApi.addKendaraan(id, data) // Add vehicle

// Pesanan (Orders)
await pesananApi.getAll()
await pesananApi.create(data)
await pesananApi.updateStatus(id, status)

// Laporan (Reports)
await laporanApi.getAll()
await laporanApi.create(data)

// Refund
await refundApi.getAll()
await refundApi.create(data)
```

## 🗄️ Database Tables

```sql
1. admin              -- Admin users
2. customer          -- Customer profiles
3. mitra             -- Driver/Partner profiles
4. kendaraan_mitra   -- Driver vehicles
5. pesanan           -- Orders
6. perjalanan        -- Trip details
7. pembayaran        -- Payments
8. laporan           -- Reports
9. refund            -- Refunds
10. pengaturan       -- Settings
```

## 🚀 Next Steps

### 1. Ganti Mock Data dengan API

Dari yang sebelumnya menggunakan `localStorage`, sekarang pakai API:

**Before (Mock):**
```typescript
const [customers] = useState(mockData);
```

**After (API):**
```typescript
const [customers, setCustomers] = useState([]);

useEffect(() => {
  customerApi.getAll().then(res => setCustomers(res.data));
}, []);
```

### 2. Contoh Implementasi

Lihat `INTEGRATION_GUIDE.md` untuk contoh lengkap:
- List data dari API
- Create/Update/Delete
- Error handling
- Loading states

### 3. Update Existing Components

Update semua halaman untuk pakai API:
- `DaftarCustomer.tsx` 
- `DaftarMitra.tsx`
- `Pesanan.tsx`
- `Laporan.tsx`
- `Refund.tsx`

## 🛠️ Troubleshooting

**Backend tidak jalan:**
```bash
# Check MySQL running
# Check .env credentials
# Check port 3001 tidak dipakai: netstat -ano | findstr :3001
```

**CORS error:**
- Backend harus running
- .env VITE_API_URL harus sesuai

**Database error:**
- Run schema.sql lagi
- Check MySQL connection

## 📊 Sample Queries Tersedia

Database sudah include:
- ✅ 1 Admin user
- ✅ 3 Customers (berbagai status)
- ✅ 3 Mitra dengan vehicles
- ✅ Data relationships sudah setup

## 💡 Pro Tips

1. **Development Mode** - Backend dengan `npm run dev` (auto-reload)
2. **Database Reset** - Run `schema.sql` lagi untuk fresh data
3. **API Testing** - Gunakan Postman/Thunder Client untuk test
4. **Debugging** - Semua routes log ke console

## 🎯 Saat Production

```bash
# Build backend
npm run build

# Run production
npm start

# Atau gunakan PM2
pm2 start dist/server.js --name "nebeng-api"
```

## 📚 Dokumentasi Lengkap

- **Setup & Installation** → `SETUP_GUIDE.md`
- **API Integration** → `INTEGRATION_GUIDE.md`  
- **Backend Readme** → `backend/README.md`

---

## ✅ Checklist Sebelum Deploy

- [ ] MySQL database sudah dibuat
- [ ] `.env` sudah dikonfigurasi
- [ ] Backend running di `http://localhost:3001`
- [ ] API endpoints bisa diakses
- [ ] Frontend menunjuk ke backend API
- [ ] Test semua CRUD operations
- [ ] Test block/unblock features
- [ ] Check error handling

---

**Sekarang Anda hanya perlu:**
1. Run `mysql ... < schema.sql` untuk create database
2. Set `.env` credentials
3. `npm run dev` untuk start backend
4. Frontend siap pakai API! 🎉

Ada pertanyaan atau issue? Lihat file dokumentasi atau check console logs untuk error details.
