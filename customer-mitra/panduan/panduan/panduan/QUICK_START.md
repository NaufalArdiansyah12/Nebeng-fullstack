# ⚡ Quick Start - Frontend & Backend Integration

## 🚀 Start Here

### 1. Terminal 1 - Start Backend
```bash
cd backend
npm install
npm run dev
```

✅ Backend running at `http://localhost:3001`

### 2. Terminal 2 - Start Frontend  
```bash
npm install
npm run dev
```

✅ Frontend running at `http://localhost:5173`

---

## ✨ What Changed

**Before**: Hardcoded mock data in contexts
```typescript
const initialCustomerList = [
  { id: "1", nama: "...", ... },
  { id: "2", nama: "...", ... },
];
```

**Now**: Real-time data from backend
```typescript
useEffect(() => {
  const fetchCustomers = async () => {
    const response = await customerApi.getAll();
    setCustomerList(response.data);
  };
  fetchCustomers();
}, []);
```

---

## 📚 Updated Contexts

All these now fetch real data from backend:

| Context | Endpoint | Auto-Fetch |
|---------|----------|-----------|
| CustomerContext | `/api/customers` | ✅ Yes |
| MitraContext | `/api/mitra` | ✅ Yes |
| PesananContext | `/api/pesanan` | ✅ Yes |
| LaporanContext | `/api/laporan` | ✅ Yes |
| RefundContext | `/api/refund` | ✅ Yes |
| AdminContext | `/api/admin/profile` | ✅ Yes |

---

## 🎯 How to Use

Use contexts the same way, but now with real data:

```typescript
import { useCustomer } from "../contexts/CustomerContext";

export function MyComponent() {
  const { customerList, loading, error } = useCustomer();

  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error}</div>;

  return (
    <div>
      {customerList.map(c => <div key={c.id}>{c.nama}</div>)}
    </div>
  );
}
```

---

## 🔍 Check It Works

### Test Customers
Go to Dashboard → Daftar Customer
- Should show customers from database
- Data loads automatically
- Block/Unblock buttons work with backend

### Test Drivers  
Go to Dashboard → Daftar Mitra
- Should show drivers from database
- Data loads automatically

### Test Orders
Go to Dashboard → Pesanan
- Should show orders from database
- Includes customer and driver details

---

## ⚙️ Configuration

**Frontend** - `.env`
```
VITE_API_URL=http://localhost:3001/api
```

**Backend** - `backend/.env`
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=nebeng_admin
PORT=3001
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Cannot GET /api/customers" | Backend not running. Run `npm run dev` in backend folder |
| "Network Error" | Check backend is on port 3001 and .env has correct URL |
| Data not showing | Open DevTools → Network tab → check API responses |
| "Database not found" | Run `cd backend && npm run setup-db` |

---

## 📖 Learn More

- [Full Integration Guide](./BACKEND_INTEGRATION_GUIDE.md)
- [Complete Summary](./INTEGRATION_SUMMARY.md)
- Backend API routes: `backend/src/routes/`
- Frontend services: `src/services/api.ts`

---

## 💡 Key Features

✅ **Auto-fetch** - Data loads automatically on component mount
✅ **Real-time** - Changes reflect immediately in UI
✅ **Error handling** - Graceful error messages
✅ **Loading states** - Know when data is being fetched
✅ **Type-safe** - Full TypeScript support

---

## 🎉 Done!

Your frontend now pulls all data from the backend API. Everything works together!

Run both servers and start using the app with real data from the database.

```bash
# Terminal 1
cd backend && npm run dev

# Terminal 2  
npm run dev
```

**That's it!** 🚀
