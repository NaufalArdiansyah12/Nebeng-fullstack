import { Loader2 } from "lucide-react";
import DashboardLayout from "@/components/DashboardLayout";
import { useNavigate, useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import api from "@/lib/api";
import { toast } from "sonner";
import { formatCurrency, formatDate } from "@/lib/refund-utils";
import { RefundHeader } from "@/components/ui/refund-detail/refund-header";
import { CustomerInfoCard } from "@/components/ui/refund-detail/customer-info-card";
import { RefundInfoCard } from "@/components/ui/refund-detail/refund-info-card";
import { BankInfoCard } from "@/components/ui/refund-detail/bank-info-card";
import { RefundSummaryCard } from "@/components/ui/refund-detail/refund-summary-card";
import { ProgressTimeline } from "@/components/ui/refund-detail/progress-timeline";
import { ActionCard } from "@/components/ui/refund-detail/action-card";
import { DurationInfoCard } from "@/components/ui/refund-detail/duration-info-card";
import { ApproveDialog } from "@/components/ui/refund-detail/approve-dialog";
import { RejectDialog } from "@/components/ui/refund-detail/reject-dialog";
import { ProcessDialog } from "@/components/ui/refund-detail/process-dialog";

interface RefundDetail {
  id: number;
  booking_id: number;
  booking_type: string;
  user_id: number;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  customer_photo: string | null;
  refund_reason: string;
  total_amount: number;
  refund_amount: number;
  admin_fee: number;
  bank_name: string;
  account_number: string;
  account_holder_name: string;
  status: "pending" | "approved" | "processing" | "completed" | "rejected";
  rejection_reason: string | null;
  submitted_at: string;
  approved_at: string | null;
  processed_at: string | null;
  completed_at: string | null;
  created_at: string;
  progress?: Array<{
    title: string;
    description: string;
    date: string | null;
    status: "completed" | "pending" | "rejected";
  }>;
}

const DetailRefund = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const [refund, setRefund] = useState<RefundDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  
  // Dialog states
  const [approveDialogOpen, setApproveDialogOpen] = useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const [processDialogOpen, setProcessDialogOpen] = useState(false);
  const [adminFee, setAdminFee] = useState("0");
  const [rejectionReason, setRejectionReason] = useState("");

  useEffect(() => {
    if (id) {
      fetchRefundDetail();
    }
  }, [id]);

  const fetchRefundDetail = async () => {
    try {
      setLoading(true);
      const response = await api.get(`/finance/refunds/${id}`);
      setRefund(response.data);
      setAdminFee(response.data.admin_fee.toString());
    } catch (error) {
      console.error("Error fetching refund detail:", error);
      toast.error("Gagal mengambil detail refund");
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async () => {
    if (!refund) return;
    
    try {
      setActionLoading(true);
      await api.post(`/finance/refunds/${id}/approve`, {
        admin_fee: parseFloat(adminFee) || 0,
      });
      toast.success("Refund berhasil disetujui");
      setApproveDialogOpen(false);
      fetchRefundDetail();
    } catch (error: any) {
      console.error("Error approving refund:", error);
      toast.error(error.response?.data?.message || "Gagal menyetujui refund");
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
      await api.post(`/finance/refunds/${id}/reject`, {
        rejection_reason: rejectionReason,
      });
      toast.success("Refund berhasil ditolak");
      setRejectDialogOpen(false);
      fetchRefundDetail();
    } catch (error: any) {
      console.error("Error rejecting refund:", error);
      toast.error(error.response?.data?.message || "Gagal menolak refund");
    } finally {
      setActionLoading(false);
    }
  };

  const handleProcess = async () => {
    try {
      setActionLoading(true);
      await api.post(`/finance/refunds/${id}/process`);
      toast.success("Refund berhasil diproses");
      setProcessDialogOpen(false);
      fetchRefundDetail();
    } catch (error: any) {
      console.error("Error processing refund:", error);
      toast.error(error.response?.data?.message || "Gagal memproses refund");
    } finally {
      setActionLoading(false);
    }
  };

  const handleComplete = async () => {
    try {
      setActionLoading(true);
      await api.post(`/finance/refunds/${id}/complete`);
      toast.success("Refund berhasil diselesaikan");
      fetchRefundDetail();
    } catch (error: any) {
      console.error("Error completing refund:", error);
      toast.error(error.response?.data?.message || "Gagal menyelesaikan refund");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <DashboardLayout title="Detail Refund">
        <div className="flex items-center justify-center py-12">
          <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
        </div>
      </DashboardLayout>
    );
  }

  if (!refund) {
    return (
      <DashboardLayout title="Detail Refund">
        <div className="flex items-center justify-center py-12">
          <p className="text-muted-foreground">Data tidak ditemukan</p>
        </div>
      </DashboardLayout>
    );
  }

  const calculatedRefund = refund.total_amount - parseFloat(adminFee || "0");

  return (
    <DashboardLayout title="Detail Refund">
      {/* Header */}
      <RefundHeader
        refundId={refund.id}
        bookingId={refund.booking_id}
        status={refund.status}
        onBack={() => navigate(-1)}
      />

      <div className="grid grid-cols-3 gap-6">
        {/* Main Content */}
        <div className="col-span-2 space-y-6">
          {/* Customer Information */}
          <CustomerInfoCard
            customerName={refund.customer_name}
            customerEmail={refund.customer_email}
            customerPhone={refund.customer_phone}
            bookingType={refund.booking_type}
          />

          {/* Refund Information */}
          <RefundInfoCard
            refundReason={refund.refund_reason}
            totalAmount={refund.total_amount}
            adminFee={adminFee}
            refundAmount={refund.refund_amount}
            calculatedRefund={calculatedRefund}
            status={refund.status}
            rejectionReason={refund.rejection_reason}
            formatCurrency={formatCurrency}
            onAdminFeeChange={setAdminFee}
          />

          {/* Bank Information */}
          <BankInfoCard
            bankName={refund.bank_name}
            accountNumber={refund.account_number}
            accountHolderName={refund.account_holder_name}
          />

          {/* Detail Refund Summary */}
          <RefundSummaryCard
            totalAmount={refund.total_amount}
            adminFee={refund.admin_fee}
            refundAmount={refund.refund_amount}
            formatCurrency={formatCurrency}
          />
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Progress Timeline */}
          {refund.progress && (
            <ProgressTimeline
              progress={refund.progress}
              formatDate={formatDate}
            />
          )}

          {/* Actions */}
          <ActionCard
            status={refund.status}
            actionLoading={actionLoading}
            onApprove={() => setApproveDialogOpen(true)}
            onReject={() => setRejectDialogOpen(true)}
            onProcess={() => setProcessDialogOpen(true)}
            onComplete={handleComplete}
          />

          {/* Duration Info */}
          <DurationInfoCard />
        </div>
      </div>

      {/* Dialogs */}
      <ApproveDialog
        open={approveDialogOpen}
        onOpenChange={setApproveDialogOpen}
        adminFee={adminFee}
        onAdminFeeChange={setAdminFee}
        totalAmount={refund.total_amount}
        calculatedRefund={calculatedRefund}
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
        bankName={refund.bank_name}
        accountNumber={refund.account_number}
        accountHolderName={refund.account_holder_name}
        refundAmount={refund.refund_amount}
        formatCurrency={formatCurrency}
        onConfirm={handleProcess}
        loading={actionLoading}
      />
    </DashboardLayout>
  );
};

export default DetailRefund;
