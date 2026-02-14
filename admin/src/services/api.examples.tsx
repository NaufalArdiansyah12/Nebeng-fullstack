// Contoh penggunaan API di komponen React

import { useEffect, useState } from 'react';
import { customerApi } from '@/services/api';
import { mitraApi } from '@/services/api';

// ========== CUSTOMER EXAMPLE ==========

export function CustomerListExample() {
  const [customers, setCustomers] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadCustomers();
  }, []);

  const loadCustomers = async () => {
    setLoading(true);
    try {
      const response = await customerApi.getAll();
      setCustomers(response.data);
    } catch (error) {
      console.error('Error loading customers:', error);
    }
    setLoading(false);
  };

  const handleBlockCustomer = async (id: string) => {
    try {
      await customerApi.block(id);
      await loadCustomers(); // Refresh data
    } catch (error) {
      console.error('Error blocking customer:', error);
    }
  };

  const handleUnblockCustomer = async (id: string) => {
    try {
      await customerApi.unblock(id);
      await loadCustomers(); // Refresh data
    } catch (error) {
      console.error('Error unblocking customer:', error);
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      {customers.map((customer) => (
        <div key={customer.id}>
          <h3>{customer.nama}</h3>
          <p>Status: {customer.status}</p>
          <button onClick={() => handleBlockCustomer(customer.id)}>Block</button>
          <button onClick={() => handleUnblockCustomer(customer.id)}>Unblock</button>
        </div>
      ))}
    </div>
  );
}

// ========== MITRA EXAMPLE ==========

export function MitraListExample() {
  const [mitra, setMitra] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    loadMitra();
  }, []);

  const loadMitra = async () => {
    setLoading(true);
    try {
      const response = await mitraApi.getAll();
      setMitra(response.data);
    } catch (error) {
      console.error('Error loading mitra:', error);
    }
    setLoading(false);
  };

  const handleAddKendaraan = async (mitraId: string) => {
    try {
      const newKendaraan = {
        jenisKendaraan: 'Motor',
        merkKendaraan: 'YAMAHA',
        platNomor: 'B 1234 XYZ',
        tahunPembuatan: 2023
      };
      await mitraApi.addKendaraan(mitraId, newKendaraan);
      // Show success message
    } catch (error) {
      console.error('Error adding kendaraan:', error);
    }
  };

  if (loading) return <div>Loading...</div>;

  return (
    <div>
      {mitra.map((m) => (
        <div key={m.id}>
          <h3>{m.nama}</h3>
          <p>Layanan: {m.layanan}</p>
          <p>Status: {m.status}</p>
          <button onClick={() => handleAddKendaraan(m.id)}>Add Vehicle</button>
        </div>
      ))}
    </div>
  );
}

// ========== USAGE IN YOUR COMPONENTS ==========

/*
// In your Dashboard.tsx or any component:

import { customerApi, mitraApi, pesananApi } from '@/services/api';

export default function Dashboard() {
  const [stats, setStats] = useState({
    customers: 0,
    mitra: 0,
    pesanan: 0,
  });

  useEffect(() => {
    const loadStats = async () => {
      const customersResponse = await customerApi.getAll();
      const mitraResponse = await mitraApi.getAll();
      const pesananResponse = await pesananApi.getAll();

      setStats({
        customers: customersResponse.data.length,
        mitra: mitraResponse.data.length,
        pesanan: pesananResponse.data.length,
      });
    };

    loadStats();
  }, []);

  return (
    <div>
      <h1>Dashboard</h1>
      <p>Customers: {stats.customers}</p>
      <p>Mitra: {stats.mitra}</p>
      <p>Pesanan: {stats.pesanan}</p>
    </div>
  );
}
*/
