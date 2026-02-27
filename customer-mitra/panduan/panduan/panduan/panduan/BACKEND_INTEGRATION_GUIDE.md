# Backend Integration Guide - Frontend & Backend Connection

## ✅ Integration Complete

All frontend contexts have been successfully updated to fetch data from the backend API instead of using hardcoded mock data.

---

## 🏗️ Architecture Overview

### Backend Structure
The backend is built with **Express.js** and **TypeScript** and provides RESTful API endpoints:

```
Backend (localhost:3001/api)
├── /admin           - Admin profile management
├── /customers       - Customer management
├── /mitra           - Mitra (driver) management
├── /pesanan         - Orders management
├── /laporan         - Complaints management
└── /refund          - Refunds management
```

### Frontend Structure
The frontend uses **React Context API** for state management with automatic data fetching:

```
Frontend (localhost:5173)
├── CustomerContext  - Fetches from /api/customers
├── MitraContext     - Fetches from /api/mitra
├── PesananContext   - Fetches from /api/pesanan
├── LaporanContext   - Fetches from /api/laporan
├── RefundContext    - Fetches from /api/refund
└── AdminContext     - Fetches from /api/admin
```

---

## 🚀 Getting Started

### 1. Start the Backend

```bash
cd backend
npm install
npm run dev
```

The backend will run on `http://localhost:3001`

Expected output:
```
✅ Server running at http://localhost:3001
📦 Environment: development
🗄️  Database: nebeng_admin
```

### 2. Start the Frontend

```bash
npm install
npm run dev
```

The frontend will run on `http://localhost:5173`

---

## 📋 Updated Contexts

### 1. **CustomerContext.tsx**
- **Purpose**: Manage customer data
- **API Endpoint**: GET `/api/customers`
- **Features**:
  - Auto-fetch customers on mount
  - Block/Unblock customers with API calls
  - Update customer status
  - Lazy-load customer details
  - Loading and error states

### 2. **MitraContext.tsx**
- **Purpose**: Manage mitra (driver) data
- **API Endpoint**: GET `/api/mitra`
- **Features**:
  - Auto-fetch mitra on mount
  - Block/Unblock mitra with API calls
  - Update mitra status
  - Supports vehicle information
  - Loading and error states

### 3. **PesananContext.tsx**
- **Purpose**: Manage orders (pesanan)
- **API Endpoint**: GET `/api/pesanan`
- **Features**:
  - Auto-fetch orders on mount
  - Complete order details with customer and driver info
  - Perjalanan (journey) information
  - Pembayaran (payment) information
  - Loading and error states

### 4. **LaporanContext.tsx**
- **Purpose**: Manage complaints (laporan)
- **API Endpoint**: GET `/api/laporan`
- **Features**:
  - Auto-fetch complaints on mount
  - Linked to customers and mitra
  - Complaint description and status tracking
  - Loading and error states

### 5. **RefundContext.tsx**
- **Purpose**: Manage refunds
- **API Endpoint**: GET `/api/refund`
- **Features**:
  - Auto-fetch refunds on mount
  - Refund status management
  - Transaction tracking
  - Loading and error states

### 6. **AdminContext.tsx**
- **Purpose**: Manage admin profile
- **API Endpoint**: GET/PUT `/api/admin/profile`
- **Features**:
  - Auto-fetch admin profile from backend
  - Update profile with API calls
  - Replace localStorage with backend source of truth
  - Loading and error states

---

## 🔧 API Service Layer

The API service is located at `src/services/api.ts`:

```typescript
// Example usage in components
import { customerApi } from "../services/api";

// Fetch customers
const response = await customerApi.getAll();

// Block a customer
await customerApi.block(customerId);

// Update customer
await customerApi.update(customerId, data);
```

All API calls use Axios with:
- Base URL: `http://localhost:3001/api`
- Content-Type: `application/json`
- CORS support enabled on backend

---

## 🔌 Environment Variables

### Frontend (.env)
```dotenv
VITE_API_URL=http://localhost:3001/api
```

### Backend (.env)
```dotenv
NODE_ENV=development
PORT=3001

# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=nebeng_admin
```

---

## 📊 Data Transformation

Frontend and backend use different field naming conventions:

| Frontend | Backend |
|----------|---------|
| `namaLengkap` | `nama_lengkap` |
| `noTlp` | `no_tlp` |
| `tempatLahir` | `tempat_lahir` |
| `tanggalLahir` | `tanggal_lahir` |
| `jenisKelamin` | `jenis_kelamin` |

The contexts handle these transformations automatically.

---

## 🎯 Component Integration Example

### Using CustomerContext in a Component

```typescript
import { useCustomer } from "../contexts/CustomerContext";

export function DaftarCustomer() {
  const { customerList, loading, error, blockCustomer } = useCustomer();

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {customerList.map(customer => (
        <div key={customer.id}>
          {customer.nama}
          <button onClick={() => blockCustomer(customer.id)}>
            Block
          </button>
        </div>
      ))}
    </div>
  );
}
```

---

## ⚡ Features Added to All Contexts

### 1. Auto-fetch on Mount
- `useEffect` hook fetches data automatically when component mounts
- Proper error handling and loading states

### 2. API Integration
- All CRUD operations call backend API
- Changes are reflected in state immediately
- API errors are logged to console

### 3. Error Handling
- `loading` state for UI feedback
- `error` state for displaying error messages
- Graceful fallbacks on API failures

### 4. Type Safety
- Full TypeScript support
- Proper type definitions for all API responses

---

## 🐛 Troubleshooting

### Backend Connection Issues

**Problem**: `Failed to fetch customers: Network Error`

**Solution**:
1. Verify backend is running on `http://localhost:3001`
2. Check `.env` file has correct `VITE_API_URL`
3. Verify CORS is enabled on backend (it is by default)

### Database Issues

**Problem**: Backend crashes or cannot connect to database

**Solution**:
1. Verify MySQL is running
2. Check database credentials in `backend/.env`
3. Run database setup: `npm run setup-db` (in backend folder)

### API Response Format Issues

**Problem**: Data doesn't appear in UI

**Solution**:
1. Check browser DevTools Network tab
2. Verify API response matches expected structure
3. Check console for transformation errors
4. Compare API response field names with transformation logic

---

## 📝 Next Steps

1. **Setup Database**: Run `npm run setup-db` in backend folder
2. **Start Both Servers**: Follow the Getting Started section
3. **Test Endpoints**: Use Postman or curl to verify API responses
4. **Monitor**: Check browser console for any API errors

---

## 📚 Additional Resources

- [Backend API Routes](../backend/src/routes/)
- [Frontend Service Layer](../src/services/api.ts)
- [Context Hooks](../src/contexts/)

---

## ✨ Summary of Changes

- ✅ Customer data now fetches from backend
- ✅ Mitra data now fetches from backend
- ✅ Orders (Pesanan) data now fetches from backend
- ✅ Complaints (Laporan) data now fetches from backend
- ✅ Refunds data now fetches from backend
- ✅ Admin profile now fetches from backend
- ✅ All contexts have loading and error states
- ✅ All API operations include error handling
- ✅ Environment variables properly configured
- ✅ Type safety maintained throughout

The frontend now pulls all data from the backend API in real-time! 🎉
