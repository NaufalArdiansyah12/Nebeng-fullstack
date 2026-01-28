# Frontend Backend Integration - Summary

## 🎯 What Was Done

Your frontend has been successfully integrated with the backend API. Instead of using hardcoded mock data, all data now comes from the backend in real-time.

---

## 📝 Files Modified

### Context Files (Updated to fetch from backend)
1. **`src/contexts/CustomerContext.tsx`** ✅
   - Fetches customers from `/api/customers`
   - Automatically loads on component mount
   
2. **`src/contexts/MitraContext.tsx`** ✅
   - Fetches drivers from `/api/mitra`
   - Automatically loads on component mount
   
3. **`src/contexts/PesananContext.tsx`** ✅
   - Fetches orders from `/api/pesanan`
   - Automatically loads on component mount
   
4. **`src/contexts/LaporanContext.tsx`** ✅
   - Fetches complaints from `/api/laporan`
   - Automatically loads on component mount
   
5. **`src/contexts/RefundContext.tsx`** ✅
   - Fetches refunds from `/api/refund`
   - Automatically loads on component mount
   
6. **`src/contexts/AdminContext.tsx`** ✅
   - Fetches admin profile from `/api/admin/profile`
   - Automatically loads on component mount

### Environment Files (Created)
- **`.env`** - Frontend API configuration
- **`backend/.env`** - Backend database configuration

### API Service (Already in place)
- **`src/services/api.ts`** - Handles all API communication

---

## 🚀 How to Run

### Step 1: Start Backend
```bash
cd backend
npm install
npm run dev
```

Backend will run on: `http://localhost:3001`

### Step 2: Start Frontend
```bash
npm install
npm run dev
```

Frontend will run on: `http://localhost:5173`

---

## 📊 Data Flow

```
Frontend Component
       ↓
React Context (e.g., useCustomer())
       ↓
useEffect() hook
       ↓
API Service (customerApi.getAll())
       ↓
Axios HTTP Request
       ↓
Backend API (GET /api/customers)
       ↓
Express Route Handler
       ↓
Database Query
       ↓
Response back to Frontend
       ↓
Context State Updated
       ↓
Component Re-renders
```

---

## 🔄 Auto Data Loading

Each context automatically fetches data when the application loads:

```typescript
useEffect(() => {
  const fetchData = async () => {
    try {
      const response = await apiFunction.getAll();
      setDataList(transformedData);
    } catch (error) {
      setError(error.message);
    } finally {
      setLoading(false);
    }
  };
  
  fetchData();
}, []); // Runs once on mount
```

---

## 📦 What's Available in Each Context

### CustomerContext
```typescript
const { 
  customerList,           // Array of all customers
  customerDetail,         // Object with detailed customer info
  loading,               // boolean - true while fetching
  error,                 // string | null - any errors
  updateCustomerStatus,  // function
  updateCustomerInfo,    // function
  blockCustomer,         // function
  unblockCustomer        // function
} = useCustomer();
```

### MitraContext
```typescript
const { 
  mitraList,            // Array of all drivers
  mitraDetail,          // Object with detailed driver info
  loading,              // boolean - true while fetching
  error,                // string | null - any errors
  blockMitra,           // function
  unblockMitra,         // function
  updateMitraStatus     // function
} = useMitra();
```

### PesananContext
```typescript
const { 
  pesananList,          // Array of all orders
  pesananDetail,        // Object with detailed order info
  loading,              // boolean - true while fetching
  error,                // string | null - any errors
  getPesananDetail      // function(id)
} = usePesanan();
```

### LaporanContext
```typescript
const { 
  laporanList,          // Array of all complaints
  loading,              // boolean - true while fetching
  error,                // string | null - any errors
  getLaporanDetail,     // function(id)
  updateLaporan         // function(id, laporan)
} = useLaporan();
```

### RefundContext
```typescript
const { 
  refundList,           // Array of all refunds
  loading,              // boolean - true while fetching
  error,                // string | null - any errors
  getRefundDetail,      // function(id)
  updateRefundStatus    // function(id, status)
} = useRefund();
```

### AdminContext
```typescript
const { 
  profile,              // AdminProfile object
  loading,              // boolean - true while fetching
  error,                // string | null - any errors
  updateProfile         // function(data)
} = useAdmin();
```

---

## ✨ New Features Added

### 1. **Loading States**
All contexts now have `loading` state to show loading indicators

### 2. **Error Handling**
All contexts have `error` state for error messages

### 3. **Automatic Data Fetch**
Data is automatically fetched when components mount

### 4. **API Integration**
All operations (block, unblock, update, etc.) call the backend API

### 5. **Real-time Sync**
Changes in the backend are reflected in the frontend

---

## 🔧 Example: Using Customer Data

```typescript
import { useCustomer } from "../contexts/CustomerContext";

export function CustomerList() {
  const { customerList, loading, error } = useCustomer();

  if (loading) return <div>Loading customers...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {customerList.map(customer => (
        <div key={customer.id}>
          <h3>{customer.nama}</h3>
          <p>{customer.email}</p>
          <p>Status: {customer.status}</p>
        </div>
      ))}
    </div>
  );
}
```

---

## 🗄️ Database Setup

Before running the backend, make sure to setup the database:

```bash
cd backend
npm run setup-db
```

This runs the SQL schema from `backend/database/schema.sql`

---

## ⚙️ Configuration

### Frontend Environment
Edit `.env` in root folder:
```
VITE_API_URL=http://localhost:3001/api
```

### Backend Environment
Edit `backend/.env`:
```
NODE_ENV=development
PORT=3001
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=nebeng_admin
```

---

## 🎓 Key Concepts

### API Service Pattern
The `src/services/api.ts` file exports API methods for each entity:
- `customerApi.getAll()`
- `customerApi.getById(id)`
- `customerApi.create(data)`
- `customerApi.update(id, data)`
- `customerApi.delete(id)`
- `customerApi.block(id)`
- `customerApi.unblock(id)`

### Automatic Data Transformation
Backend uses snake_case, frontend uses camelCase. Contexts handle the transformation automatically.

### Lazy Loading Details
Customer detail views can fetch specific customer data when needed instead of loading all details upfront.

---

## 📋 Checklist

- ✅ All contexts updated to fetch from backend
- ✅ API service properly configured
- ✅ Environment variables set
- ✅ Error handling implemented
- ✅ Loading states added
- ✅ Auto-fetch on mount implemented
- ✅ Type safety maintained
- ✅ CORS enabled on backend
- ✅ Database configuration ready

---

## 🆘 Common Issues & Solutions

### Backend not starting
**Solution**: Check database credentials in `backend/.env`

### Frontend can't connect to backend
**Solution**: Ensure backend runs on port 3001 and check `VITE_API_URL` in `.env`

### Data not appearing
**Solution**: Check browser DevTools Network tab to see API responses

### Type errors
**Solution**: Ensure you're using correct context hooks (useCustomer, useMitra, etc.)

---

## 📚 Files Reference

| File | Purpose |
|------|---------|
| `src/services/api.ts` | Axios instance and API methods |
| `src/contexts/*.tsx` | React contexts with auto-fetch |
| `backend/server.ts` | Express server setup |
| `backend/src/routes/*.ts` | API route handlers |
| `backend/src/db.ts` | Database connection |
| `.env` | Frontend config |
| `backend/.env` | Backend config |

---

## 🎉 You're All Set!

Your frontend is now fully integrated with the backend. All data flows from the database through the API to your React components in real-time.

Start both servers and enjoy real-time data synchronization! 🚀
