# Integrasi Frontend dengan Backend API

## Langkah-Langkah Integrasi

### 1. Setup Environment Variable

File `.env.local` di root project:
```
VITE_API_URL=http://localhost:3001/api
```

### 2. Import API Service

Di komponen Anda:
```typescript
import { customerApi, mitraApi, pesananApi } from '@/services/api';
```

### 3. Gunakan dalam Komponen

#### Fetch Data
```typescript
import { useEffect, useState } from 'react';
import { customerApi } from '@/services/api';

export function MyComponent() {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      try {
        const response = await customerApi.getAll();
        setCustomers(response.data);
      } catch (error) {
        console.error('Error:', error);
      }
      setLoading(false);
    };
    loadData();
  }, []);

  return <div>{/* render customers */}</div>;
}
```

#### Create Data
```typescript
const handleCreateCustomer = async (formData) => {
  try {
    await customerApi.create(formData);
    // Refresh list atau show success
  } catch (error) {
    // Show error
  }
};
```

#### Update Data
```typescript
const handleUpdateCustomer = async (id, updatedData) => {
  try {
    await customerApi.update(id, updatedData);
    // Refresh list
  } catch (error) {
    // Show error
  }
};
```

#### Block/Unblock Customer
```typescript
const handleBlock = async (id) => {
  try {
    await customerApi.block(id);
    // Refresh list
  } catch (error) {
    // Show error
  }
};

const handleUnblock = async (id) => {
  try {
    await customerApi.unblock(id);
    // Refresh list
  } catch (error) {
    // Show error
  }
};
```

### 4. Contoh Lengkap - Customer List Page

```typescript
import { useEffect, useState } from 'react';
import { customerApi } from '@/services/api';
import { Button } from '@/components/ui/button';
import { 
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function DaftarCustomer() {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    loadCustomers();
  }, []);

  const loadCustomers = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await customerApi.getAll();
      setCustomers(response.data);
    } catch (err) {
      setError('Failed to load customers');
      console.error(err);
    }
    setLoading(false);
  };

  const handleBlock = async (id) => {
    try {
      await customerApi.block(id);
      loadCustomers(); // Refresh
    } catch (err) {
      console.error('Error blocking customer:', err);
    }
  };

  const handleUnblock = async (id) => {
    try {
      await customerApi.unblock(id);
      loadCustomers(); // Refresh
    } catch (err) {
      console.error('Error unblocking customer:', err);
    }
  };

  if (loading) return <div>Loading...</div>;
  if (error) return <div>{error}</div>;

  return (
    <div>
      <h1>Customer List</h1>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Nama</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {customers.map((customer) => (
            <TableRow key={customer.id}>
              <TableCell>{customer.nama}</TableCell>
              <TableCell>{customer.email}</TableCell>
              <TableCell>{customer.status}</TableCell>
              <TableCell>
                {customer.status !== 'DIBLOCK' ? (
                  <Button onClick={() => handleBlock(customer.id)}>Block</Button>
                ) : (
                  <Button onClick={() => handleUnblock(customer.id)}>Unblock</Button>
                )}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
```

### 5. Ganti Data Mock dengan API

Lihat file `src/contexts/CustomerContext-API.tsx` untuk contoh context dengan API integration.

**Replace the old context:**
```typescript
// Old: Ganti dari CustomerContext.tsx
import { CustomerProvider } from '@/contexts/CustomerContext-API';

// Di App.tsx atau main.tsx:
<CustomerProvider>
  <App />
</CustomerProvider>
```

### 6. Error Handling

```typescript
import axios from 'axios';

try {
  const response = await customerApi.getAll();
} catch (error) {
  if (axios.isAxiosError(error)) {
    if (error.response?.status === 404) {
      console.error('Not found');
    } else if (error.response?.status === 500) {
      console.error('Server error');
    }
  }
}
```

### 7. Loading State

```typescript
const [loading, setLoading] = useState(false);
const [error, setError] = useState('');

const fetchData = async () => {
  setLoading(true);
  setError('');
  try {
    // API call
  } catch (err) {
    setError('Failed to fetch');
  } finally {
    setLoading(false);
  }
};
```

## API Endpoints Reference

### Customers
- `GET /api/customers` - List all
- `GET /api/customers/:id` - Get one
- `POST /api/customers` - Create
- `PUT /api/customers/:id` - Update
- `DELETE /api/customers/:id` - Delete
- `POST /api/customers/:id/block` - Block
- `POST /api/customers/:id/unblock` - Unblock

### Mitra
- `GET /api/mitra` - List all
- `GET /api/mitra/:id` - Get one
- `POST /api/mitra` - Create
- `PUT /api/mitra/:id` - Update
- `DELETE /api/mitra/:id` - Delete
- `GET /api/mitra/:id/kendaraan` - Get vehicles
- `POST /api/mitra/:id/kendaraan` - Add vehicle

### Pesanan
- `GET /api/pesanan` - List all
- `GET /api/pesanan/:id` - Get one
- `POST /api/pesanan` - Create

### Laporan
- `GET /api/laporan` - List all
- `GET /api/laporan/:id` - Get one
- `POST /api/laporan` - Create

### Refund
- `GET /api/refund` - List all
- `GET /api/refund/:id` - Get one
- `POST /api/refund` - Create

Lihat `SETUP_GUIDE.md` untuk dokumentasi backend lengkap.
