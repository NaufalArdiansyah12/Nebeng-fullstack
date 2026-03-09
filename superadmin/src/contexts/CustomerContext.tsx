import { createContext, useContext, useState, ReactNode, useEffect } from "react";
import { customerApi } from "@/services/api";

// ==========================================
// INTERFACE - Sesuai dengan Database Mapping
// ==========================================

export interface CustomerData {
  id: number;
  
  // Data dari verifikasi_ktp_customers & users
  nama: string;              // dari verifikasi_ktp_customers.nama_lengkap
  email: string;             // dari users.email
  no_tlp: string;            // dari users.phone
  jenis_kelamin: string;     // dari users.gender
  alamat: string;            // dari verifikasi_ktp_customers.alamat
  tanggal_lahir: string;     // dari verifikasi_ktp_customers.tanggal_lahir
  nik: string;               // dari verifikasi_ktp_customers.nik
  status: string;            // dari verifikasi_ktp_customers.status (display format)
  tanggal_daftar: Date;      // dari users.created_at
  
  // Additional fields dari detail
  nama_lengkap_ktp?: string;      // dari verifikasi_ktp_customers.nama_lengkap
  jenis_kelamin_ktp?: string;     // dari users.gender
  photo_wajah?: string;           // dari verifikasi_ktp_customers.photo_wajah
  photo_ktp?: string;             // dari verifikasi_ktp_customers.photo_ktp
  verifikasi_id?: number;
}

// ==========================================
// CONTEXT TYPE
// ==========================================

interface CustomerContextType {
  customers: CustomerData[];
  loading: boolean;
  error: string | null;
  
  // Read operations
  fetchCustomers: () => Promise<void>;
  getCustomer: (id: string) => Promise<CustomerData | undefined>;
  
  // Create operation
  createCustomer: (data: Partial<CustomerData>) => Promise<void>;
  
  // Update operations
  updateCustomer: (id: string, data: Partial<CustomerData>) => Promise<void>;
  updateCustomerFields: (id: string, fields: any) => Promise<void>;
  updateStatus: (id: string, status: string) => Promise<void>;
  
  // Delete operation
  deleteCustomer: (id: string) => Promise<void>;
  
  // Block/Unblock operations
  blockCustomer: (id: string) => Promise<void>;
  unblockCustomer: (id: string) => Promise<void>;
}

// ==========================================
// CONTEXT CREATION
// ==========================================

const CustomerContext = createContext<CustomerContextType | undefined>(undefined);

// ==========================================
// PROVIDER COMPONENT
// ==========================================

export function CustomerProvider({ children }: { children: ReactNode }) {
  const [customers, setCustomers] = useState<CustomerData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ------------------------------------------------
  // HELPER: Status mapping (database → display)
  // ------------------------------------------------
  const mapStatusToDisplay = (dbStatus: string | null): string => {
    if (!dbStatus) return 'PENGAJUAN';
    
    const statusMap: Record<string, string> = {
      'pending': 'PENGAJUAN',
      'approved': 'TERVERIFIKASI',
      'rejected': 'DITOLAK',
      'suspended': 'DIBLOCK',
      'diblock': 'DIBLOCK',
      'blocked': 'DIBLOCK',
    };
    
    return statusMap[dbStatus.toLowerCase()] || dbStatus.toUpperCase();
  };

  // ------------------------------------------------
  // HELPER: Safe date conversion
  // ------------------------------------------------
  const safeDate = (dateValue: any): Date => {
    if (!dateValue) return new Date();
    const date = new Date(dateValue);
    return isNaN(date.getTime()) ? new Date() : date;
  };

  // ------------------------------------------------
  // HELPER: Safe number conversion
  // ------------------------------------------------
  const safeNumber = (value: any): number => {
    if (value === undefined || value === null) return 0;
    const num = Number(value);
    return isNaN(num) ? 0 : num;
  };

  // ------------------------------------------------
  // FETCH ALL CUSTOMERS
  // ------------------------------------------------
  const fetchCustomers = async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await customerApi.getAll();
      
      const rawData = Array.isArray(response.data)
        ? response.data
        : response.data?.data ?? [];

      // ✅ Backend sudah mengirim data dalam format yang benar
      // Tidak perlu transform besar-besaran, hanya perlu ensure type safety
      // Transform API response to include fields compatible with Mitra frontend
      const transformedData = rawData.map((c: any) => ({
        id: String(safeNumber(c.id)),
        nama: c.nama || '-',
        email: c.email || '-',
        // provide both snake_case and camelCase phone fields
        no_tlp: c.no_tlp || c.noTlp || '-',
        noTlp: c.no_tlp || c.noTlp || '-',
        // gender intentionally omitted: take all fields except gender
        alamat: c.alamat || '',
        tanggal_lahir: c.tanggal_lahir || '',
        nik: c.nik || '',
        // normalize status using helper
        status: mapStatusToDisplay(c.status),
        // date fields for filter/export compatibility
        tanggal_daftar: safeDate(c.tanggal_daftar || c.created_at),
        tanggal: safeDate(c.tanggal_daftar || c.created_at),
        created_at: c.created_at,
        updated_at: c.updated_at,
        // compatibility fields used by Mitra frontend
        layanan: c.layanan || 'Customer',
        kode: c.kode || `#${c.id}`,
        // Additional fields
        nama_lengkap_ktp: c.nama_lengkap_ktp,
        jenis_kelamin_ktp: c.jenis_kelamin_ktp,
        photo_wajah: c.photo_wajah,
        photo_ktp: c.photo_ktp,
        verifikasi_id: c.verifikasi_id,
      }));

      setCustomers(transformedData);
      console.log('✅ Customers fetched:', transformedData.length);
      console.log('📊 Sample customer:', transformedData[0]);
      console.log('🕐 Fetch timestamp:', new Date().toISOString());
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch customers';
      setError(message);
      console.error('❌ Error fetching customers:', err);
    } finally {
      setLoading(false);
    }
  };

  // ------------------------------------------------
  // GET SINGLE CUSTOMER
  // ------------------------------------------------
  const getCustomer = async (id: string): Promise<CustomerData | undefined> => {
    try {
      const response = await customerApi.getById(id);
      const customer = {
        ...response.data,
        id: safeNumber(response.data.id),
        status: mapStatusToDisplay(response.data.status),
        tanggal_daftar: safeDate(response.data.tanggal_daftar)
      };
      
      console.log('✅ Customer detail fetched:', customer);
      return customer;
    } catch (err) {
      console.error('❌ Error fetching customer:', err);
      return undefined;
    }
  };

  // ------------------------------------------------
  // CREATE CUSTOMER
  // ------------------------------------------------
  const createCustomer = async (data: Partial<CustomerData>) => {
    try {
      await customerApi.create(data);
      await fetchCustomers();
      console.log('✅ Customer created');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create customer';
      setError(message);
      console.error('❌ Error creating customer:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // UPDATE CUSTOMER (Full Update)
  // ------------------------------------------------
  const updateCustomer = async (id: string, data: Partial<CustomerData>) => {
    try {
      // Transform data ke format yang diharapkan backend
      await customerApi.updateCustomer(id, {
        nama: data.nama,
        email: data.email,
        noTlp: data.no_tlp,
        jenisKelamin: data.jenis_kelamin,
        tanggalLahir: data.tanggal_lahir,
        alamat: data.alamat,
        nik: data.nik,
        namaLengkapKtp: data.nama_lengkap_ktp,
        jenisKelaminKtp: data.jenis_kelamin_ktp,
        photoWajah: data.photo_wajah,
        photoKtp: data.photo_ktp,
      });
      
      await fetchCustomers();
      console.log('✅ Customer updated');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update customer';
      setError(message);
      console.error('❌ Error updating customer:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // UPDATE CUSTOMER FIELDS (Partial Update)
  // ------------------------------------------------
  const updateCustomerFields = async (id: string, fields: any) => {
    try {
      await customerApi.updateFields(id, fields);
      await fetchCustomers();
      console.log('✅ Customer fields updated:', Object.keys(fields));
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update customer fields';
      setError(message);
      console.error('❌ Error updating customer fields:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // DELETE CUSTOMER
  // ------------------------------------------------
  const deleteCustomer = async (id: string) => {
    try {
      await customerApi.delete(id);
      await fetchCustomers();
      console.log('✅ Customer deleted');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete customer';
      setError(message);
      console.error('❌ Error deleting customer:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // UPDATE STATUS
  // ------------------------------------------------
  const updateStatus = async (id: string, displayStatus: string) => {
    try {
      // Backend expects display format (PENGAJUAN, TERVERIFIKASI, etc.)
      await customerApi.updateStatus(id, displayStatus);
      await fetchCustomers();
      console.log(`✅ Customer ${id} status updated to ${displayStatus}`);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update status';
      setError(message);
      console.error('❌ Error updating status:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // BLOCK CUSTOMER - INSTANTLY UPDATE STATE
  // ------------------------------------------------
  const blockCustomer = async (id: string) => {
    try {
      console.log(`🔒 Blocking customer ${id}...`);
      const response = await customerApi.block(id);
      console.log('🔁 blockCustomer response:', response?.data);
      
      // ✅ PENTING: Update state LANGSUNG tanpa menunggu fetchCustomers
      if (response.data) {
        const updatedCustomer: CustomerData = {
          ...response.data,
          id: safeNumber(response.data.id),
          status: mapStatusToDisplay(response.data.status),
          tanggal_daftar: safeDate(response.data.tanggal_daftar),
        };

        // Update customers array
        setCustomers(prevCustomers =>
          prevCustomers.map(c =>
            Number(c.id) === Number(id) ? updatedCustomer : c
          )
        );

        console.log(`✅ Customer ${id} blocked. Status: ${updatedCustomer.status}`);
      } else {
        // Fallback: jika API tidak return data lengkap, fetch ulang
        console.warn('⚠️ API tidak return data lengkap, melakukan fetchCustomers...');
        await fetchCustomers();
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to block customer';
      setError(message);
      console.error('❌ Error blocking customer:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // UNBLOCK CUSTOMER - INSTANTLY UPDATE STATE
  // ------------------------------------------------
  const unblockCustomer = async (id: string) => {
    try {
      console.log(`🔓 Unblocking customer ${id}...`);
      const response = await customerApi.unblock(id);
      console.log('🔁 unblockCustomer response:', response?.data);
      
      // ✅ PENTING: Update state LANGSUNG tanpa menunggu fetchCustomers
      if (response.data) {
        const updatedCustomer: CustomerData = {
          ...response.data,
          id: safeNumber(response.data.id),
          status: mapStatusToDisplay(response.data.status),
          tanggal_daftar: safeDate(response.data.tanggal_daftar),
        };

        // Update customers array
        setCustomers(prevCustomers =>
          prevCustomers.map(c =>
            Number(c.id) === Number(id) ? updatedCustomer : c
          )
        );

        console.log(`✅ Customer ${id} unblocked. Status: ${updatedCustomer.status}`);
      } else {
        // Fallback: jika API tidak return data lengkap, fetch ulang
        console.warn('⚠️ API tidak return data lengkap, melakukan fetchCustomers...');
        await fetchCustomers();
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to unblock customer';
      setError(message);
      console.error('❌ Error unblocking customer:', err);
      throw err;
    }
  };

  // ------------------------------------------------
  // AUTO FETCH ON MOUNT
  // ------------------------------------------------
  useEffect(() => {
    fetchCustomers();
  }, []);

  // ==========================================
  // PROVIDER VALUE
  // ==========================================

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
        updateCustomerFields,
        deleteCustomer,
        updateStatus,
        blockCustomer,
        unblockCustomer,
      }}
    >
      {children}
    </CustomerContext.Provider>
  );
}

// ==========================================
// CUSTOM HOOK
// ==========================================

export function useCustomer() {
  const context = useContext(CustomerContext);
  if (context === undefined) {
    throw new Error("useCustomer must be used within a CustomerProvider");
  }
  return context;
}

// ==========================================
// USAGE EXAMPLES
// ==========================================

/*
// 1. Get all customers
const { customers, loading, error } = useCustomer();

// 2. Get single customer
const { getCustomer } = useCustomer();
const customer = await getCustomer('123');

// 3. Update full customer data
const { updateCustomer } = useCustomer();
await updateCustomer('123', {
  nama: 'John Doe',
  email: 'john@example.com',
  no_tlp: '081234567890',
  alamat: 'Jl. Contoh No. 123'
});

// 4. Update specific fields only
const { updateCustomerFields } = useCustomer();
await updateCustomerFields('123', {
  email: 'newemail@example.com',
  no_tlp: '089876543210'
});

// 5. Update status
const { updateStatus } = useCustomer();
await updateStatus('123', 'TERVERIFIKASI');

// 6. Block/Unblock
const { blockCustomer, unblockCustomer } = useCustomer();
await blockCustomer('123');
await unblockCustomer('123');
*/