import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { customerApi } from "@/services/api";

export interface CustomerData {
  id: number;
  kode: string;
  nama: string;
  email: string;
  no_tlp: string;
  status: string;
  tanggal_daftar: Date;
  nama_lengkap?: string;
  tempat_lahir?: string;
  tanggal_lahir?: string;
  jenis_kelamin?: string;
  nik?: string;
  alamat?: string;
}

interface CustomerContextType {
  customers: CustomerData[];
  loading: boolean;
  error: string | null;
  fetchCustomers: () => Promise<void>;
  getCustomer: (id: string) => Promise<CustomerData | undefined>;
  createCustomer: (data: Partial<CustomerData>) => Promise<void>;
  updateCustomer: (id: string, data: Partial<CustomerData>) => Promise<void>;
  deleteCustomer: (id: string) => Promise<void>;
  blockCustomer: (id: string) => Promise<void>;
  unblockCustomer: (id: string) => Promise<void>;
}

const CustomerContext = createContext<CustomerContextType | undefined>(undefined);

export function CustomerProvider({ children }: { children: ReactNode }) {
  const [customers, setCustomers] = useState<CustomerData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchCustomers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await customerApi.getAll();
      setCustomers(response.data);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch customers';
      setError(message);
      console.error('Error fetching customers:', err);
    } finally {
      setLoading(false);
    }
  };

  const getCustomer = async (id: string): Promise<CustomerData | undefined> => {
    try {
      const response = await customerApi.getById(id);
      return response.data;
    } catch (err) {
      console.error('Error fetching customer:', err);
      return undefined;
    }
  };

  const createCustomer = async (data: Partial<CustomerData>) => {
    try {
      await customerApi.create(data);
      await fetchCustomers();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create customer';
      setError(message);
      console.error('Error creating customer:', err);
    }
  };

  const updateCustomer = async (id: string, data: Partial<CustomerData>) => {
    try {
      await customerApi.update(id, data);
      await fetchCustomers();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update customer';
      setError(message);
      console.error('Error updating customer:', err);
    }
  };

  const deleteCustomer = async (id: string) => {
    try {
      await customerApi.delete(id);
      await fetchCustomers();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete customer';
      setError(message);
      console.error('Error deleting customer:', err);
    }
  };

  const blockCustomer = async (id: string) => {
    try {
      await customerApi.block(id);
      await fetchCustomers();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to block customer';
      setError(message);
      console.error('Error blocking customer:', err);
    }
  };

  const unblockCustomer = async (id: string) => {
    try {
      await customerApi.unblock(id);
      await fetchCustomers();
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to unblock customer';
      setError(message);
      console.error('Error unblocking customer:', err);
    }
  };

  useEffect(() => {
    // Fetch customers on mount - uncomment to enable
    // fetchCustomers();
  }, []);

  return (
    <CustomerContext.Provider
      value={{
        customers,
        loading,
        error,
        fetchCustomers,
        getCustomer,
        createCustomer,
        updateCustomer,
        deleteCustomer,
        blockCustomer,
        unblockCustomer,
      }}
    >
      {children}
    </CustomerContext.Provider>
  );
}

export function useCustomer() {
  const context = useContext(CustomerContext);
  if (context === undefined) {
    throw new Error("useCustomer must be used within a CustomerProvider");
  }
  return context;
}
