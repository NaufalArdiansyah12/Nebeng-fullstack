import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { TransactionHeader } from "@/components/ui/transaction-detail/transaction-header";
import { CustomerCard } from "@/components/ui/transaction-detail/customer-card";
import { MitraCard } from "@/components/ui/transaction-detail/mitra-card";
import { JourneyCard } from "@/components/ui/transaction-detail/journey-card";
import { PaymentCard } from "@/components/ui/transaction-detail/payment-card";
import api from "@/lib/api";
import { toast } from "sonner";

interface TransactionDetail {
    id: string;
    booking_number: string;
    status: string;
    tanggal: string;
    jenis: string;
    service_type: string;
    customer: {
        name: string;
        phone: string;
        photo: string;
        notes: string;
    };
    mitra: {
        id: string;
        name: string;
        phone: string;
        photo: string;
        vehicle_type: string;
        vehicle_brand: string;
        vehicle_plate: string;
    };
    journey: {
        date: string;
        distance: string;
        duration: string;
        pickup_location: string;
        pickup_time: string;
        pickup_address: string;
        destination_location: string;
        destination_time: string;
        destination_address: string;
    };
    payment: {
        type: string;
        date: string;
        transaction_number: string;
        base_price: number;
        admin_fee: number;
        total: number;
        passengers: number;
    };
    passengers?: {
        count: number;
        weight: string;
    };
    goods?: {
        description: string;
        weight: string;
        photo: string | null;
    };
    penumpang_list?: Array<{
        nama: string;
        nik: string;
        no_telepon: string;
        jenis_kelamin: string;
    }>;
}

export default function DetailTransaksi() {
    const { id } = useParams();
    const navigate = useNavigate();
    const [transaction, setTransaction] = useState<TransactionDetail | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (id) {
            fetchTransactionDetail();
        }
    }, [id]);

    const fetchTransactionDetail = async () => {
        try {
            const response = await api.get(`/bookings/transactions/${id}`);
            setTransaction(response.data);
        } catch (error) {
            console.error("Error fetching transaction:", error);
            toast.error("Gagal memuat detail transaksi");
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <DashboardLayout title="Detail Transaksi">
                <div className="flex items-center justify-center h-64">
                    <p>Loading...</p>
                </div>
            </DashboardLayout>
        );
    }

    if (!transaction) {
        return (
            <DashboardLayout title="Detail Transaksi">
                <div className="flex items-center justify-center h-64">
                    <p>Transaksi tidak ditemukan</p>
                </div>
            </DashboardLayout>
        );
    }

    return (
        <DashboardLayout title="Detail Transaksi">
            {/* Header dengan Back Button */}
            <div className="mb-6 flex items-center gap-4">
                <Button
                    variant="ghost"
                    size="icon"
                    onClick={() => navigate(-1)}
                    className="rounded-full"
                >
                    <ArrowLeft className="h-5 w-5" />
                </Button>
                <h1 className="text-2xl font-semibold">Detail Transaksi</h1>
            </div>

            <TransactionHeader bookingNumber={transaction.booking_number} />

            {/* Customer dan Mitra Cards */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
                <CustomerCard
                    customer={transaction.customer}
                    serviceType={transaction.service_type}
                    jenis={transaction.jenis}
                    passengers={transaction.passengers}
                    goods={transaction.goods}
                    penumpangList={transaction.penumpang_list}
                />
                <MitraCard mitra={transaction.mitra} />
            </div>

            {/* Rincian Perjalanan dan Pembayaran */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                <JourneyCard journey={transaction.journey} />
                <PaymentCard 
                    payment={transaction.payment} 
                    bookingNumber={transaction.booking_number}
                />
            </div>
        </DashboardLayout>
    );
}
