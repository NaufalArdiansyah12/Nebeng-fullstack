import { Loader2 } from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { useEffect, useState } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { WithdrawalHeader } from "@/components/ui/withdrawal-detail/withdrawal-header";
import { UserInfoCard } from "@/components/ui/withdrawal-detail/user-info-card";
import { WithdrawalInfoCard } from "@/components/ui/withdrawal-detail/withdrawal-info-card";
import { BankInfoCard } from "@/components/ui/withdrawal-detail/bank-info-card";
import { WithdrawalSummaryCard } from "@/components/ui/withdrawal-detail/withdrawal-summary-card";
import { ProgressTimeline } from "@/components/ui/withdrawal-detail/progress-timeline";
import { ActionCard } from "@/components/ui/withdrawal-detail/action-card";
import { DurationInfoCard } from "@/components/ui/withdrawal-detail/duration-info-card";
import { ApproveDialog } from "@/components/ui/withdrawal-detail/approve-dialog";
import { RejectDialog } from "@/components/ui/withdrawal-detail/reject-dialog";
import { ProcessDialog } from "@/components/ui/withdrawal-detail/process-dialog";
import { formatCurrency, formatDate } from "@/lib/withdrawal-utils";

interface WithdrawalDetail {
  id: number;
  transaction_id: string;
  user_name: string;
  user_email: string;
  user_phone: string;
  kode_referral: string;
  amount: number;
  admin_fee: number;
  total_amount: number;
  bank_name: string;
  bank_account_number: string;
  bank_account_name: string;
  status: "pending" | "verifying" | "approved" | "processing" | "transferring" | "completed" | "rejected";
  rejection_reason: string | null;
  notes: string | null;
  submitted_at: string;
  verified_at: string | null;
  approved_at: string | null;
  processing_at: string | null;
  completed_at: string | null;
  rejected_at: string | null;
  created_at: string;
  type: "mitra" | "posmitra";
  progress?: Array<{
    title: string;
    description: string;
    date: string | null;
    status: "completed" | "pending" | "rejected";
  }>;
}

const DetailWithdrawal = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const type = searchParams.get("type") || "mitra";
  
  const [withdrawal, setWithdrawal] = useState<WithdrawalDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  
  const [approveDialogOpen, setApproveDialogOpen] = useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const [processDialogOpen, setProcessDialogOpen] = useState(false);
  const [adminFee, setAdminFee] = useState("0");
  const [rejectionReason, setRejectionReason] = useState("");

  useEffect(() => {
    if (id) {
      fetchWithdrawalDetail();
    }
  }, [id, type]);

  const fetchWithdrawalDetail = async () => {
    try {
      setLoading(true);
      const response = await api.get(`/withdrawals/${id}`, {
        params: { type }
      });
      setWithdrawal(response.data);
      setAdminFee(response.data.admin_fee.toString());
    } catch (error) {
      console.error("Error fetching withdrawal detail:", error);
      toast.error("Gagal mengambil detail penarikan");
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async () => {
    if (!withdrawal) return;
    
    try {
      setActionLoading(true);
      await api.post(`/withdrawals/${id}/approve`, {
        type: withdrawal.type,
        admin_fee: parseFloat(adminFee) || 0,
      });
      toast.success("Penarikan berhasil disetujui");
      setApproveDialogOpen(false);
      fetchWithdrawalDetail();
    } catch (error: any) {
      console.error("Error approving withdrawal:", error);
      toast.error(error.response?.data?.message || "Gagal menyetujui penarikan");
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!rejectionReason.trim()) {
      toast.error("Alasan penolakan harus diisi");
      return;
    }

    try {
      setActionLoading(true);
      await api.post(`/withdrawals/${id}/reject`, {
        type: withdrawal?.type,
        rejection_reason: rejectionReason,
      });
      toast.success("Penarikan berhasil ditolak");
      setRejectDialogOpen(false);
      fetchWithdrawalDetail();
    } catch (error: any) {
      console.error("Error rejecting withdrawal:", error);
      toast.error(error.response?.data?.message || "Gagal menolak penarikan");
    } finally {
      setActionLoading(false);
    }
  };

  const handleProcess = async () => {
    try {
      setActionLoading(true);
      await api.post(`/withdrawals/${id}/process`, {
        type: withdrawal?.type
      });
      toast.success("Penarikan sedang diproses");
      setProcessDialogOpen(false);
      fetchWithdrawalDetail();
    } catch (error: any) {
      console.error("Error processing withdrawal:", error);
      toast.error(error.response?.data?.message || "Gagal memproses penarikan");
    } finally {
      setActionLoading(false);
    }
  };

  const handleComplete = async () => {
    try {
      setActionLoading(true);
      await api.post(`/withdrawals/${id}/complete`, {
        type: withdrawal?.type
      });
      toast.success("Penarikan berhasil diselesaikan");
      fetchWithdrawalDetail();
    } catch (error: any) {
      console.error("Error completing withdrawal:", error);
      toast.error(error.response?.data?.message || "Gagal menyelesaikan penarikan");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout title="Detail Penarikan">
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        </div>
      </DashboardLayout>
    );
  }

  if (!withdrawal) {
    return (
      <DashboardLayout title="Detail Penarikan">
        <div className="flex items-center justify-center py-12">
          <p className="text-muted-foreground">Data tidak ditemukan</p>
        </div>
      </DashboardLayout>
    );
  }

  const calculatedTotal = withdrawal.amount - parseFloat(adminFee || "0");

  return (
    <DashboardLayout title="Detail Penarikan">
      <WithdrawalHeader
        withdrawalId={withdrawal.id}
        transactionId={withdrawal.transaction_id}
        status={withdrawal.status}
        onBack={() => navigate(-1)}
      />

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2 space-y-6">
          <UserInfoCard
            userName={withdrawal.user_name}
            userEmail={withdrawal.user_email}
            userPhone={withdrawal.user_phone}
            kodeReferral={withdrawal.kode_referral}
            type={withdrawal.type}
          />

          <WithdrawalInfoCard
            amount={withdrawal.amount}
            adminFee={withdrawal.status === 'pending' || withdrawal.status === 'verifying' ? adminFee : withdrawal.admin_fee.toString()}
            totalAmount={withdrawal.status === 'pending' || withdrawal.status === 'verifying' ? calculatedTotal : withdrawal.total_amount}
            calculatedTotal={calculatedTotal}
            status={withdrawal.status}
            rejectionReason={withdrawal.rejection_reason}
            notes={withdrawal.notes}
            onAdminFeeChange={setAdminFee}
            formatCurrency={formatCurrency}
          />

          <BankInfoCard
            bankName={withdrawal.bank_name}
            accountNumber={withdrawal.bank_account_number}
            accountHolderName={withdrawal.bank_account_name}
          />

          <WithdrawalSummaryCard
            amount={withdrawal.amount}
            adminFee={withdrawal.admin_fee}
            totalAmount={withdrawal.total_amount}
            formatCurrency={formatCurrency}
          />
        </div>

        <div className="space-y-6">
          {withdrawal.progress && (
            <ProgressTimeline progress={withdrawal.progress} formatDate={formatDate} />
          )}

          <ActionCard
            status={withdrawal.status}
            actionLoading={actionLoading}
            onApprove={() => setApproveDialogOpen(true)}
            onReject={() => setRejectDialogOpen(true)}
            onProcess={() => setProcessDialogOpen(true)}
            onComplete={handleComplete}
          />

          <DurationInfoCard />
        </div>
      </div>

      <ApproveDialog
        open={approveDialogOpen}
        onOpenChange={setApproveDialogOpen}
        adminFee={adminFee}
        onAdminFeeChange={setAdminFee}
        amount={withdrawal.amount}
        calculatedTotal={calculatedTotal}
        formatCurrency={formatCurrency}
        onConfirm={handleApprove}
        loading={actionLoading}
      />

      <RejectDialog
        open={rejectDialogOpen}
        onOpenChange={setRejectDialogOpen}
        rejectionReason={rejectionReason}
        onReasonChange={setRejectionReason}
        onConfirm={handleReject}
        loading={actionLoading}
      />

      <ProcessDialog
        open={processDialogOpen}
        onOpenChange={setProcessDialogOpen}
        bankName={withdrawal.bank_name}
        accountNumber={withdrawal.bank_account_number}
        accountHolderName={withdrawal.bank_account_name}
        totalAmount={withdrawal.total_amount}
        formatCurrency={formatCurrency}
        onConfirm={handleProcess}
        loading={actionLoading}
      />
    </DashboardLayout>
  );
};

export default DetailWithdrawal;
