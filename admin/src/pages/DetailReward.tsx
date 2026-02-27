import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ChevronLeft, CheckCircle, XCircle, Gift, MapPin, Coins } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { rewardApi } from "@/services/api";

// ✅ Format tanggal ke format yang readable
const formatDate = (dateString: string | null | undefined): string => {
  if (!dateString) return "-";
  
  try {
    const date = new Date(dateString);
    
    // Check if date is valid
    if (isNaN(date.getTime())) return "-";
    
    // Format: DD/MM/YYYY HH:MM
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    
    return `${day}/${month}/${year} ${hours}:${minutes}`;
  } catch (error) {
    console.error('Error formatting date:', error);
    return "-";
  }
};

const getStatusBadge = (status?: string | null) => {
  switch (status) {
    case "completed":
      return <Badge className="bg-green-500 hover:bg-green-600 text-white text-xs">Selesai</Badge>;
    case "approved":
      return <Badge className="bg-blue-500 hover:bg-blue-600 text-white text-xs">Disetujui</Badge>;
    case "rejected":
      return <Badge className="bg-red-500 hover:bg-red-600 text-white text-xs">Ditolak</Badge>;
    case "pending":
      return <Badge className="bg-yellow-500 hover:bg-yellow-600 text-white text-xs">Menunggu</Badge>;
    default:
      return <Badge className="bg-gray-500 hover:bg-gray-600 text-white text-xs">{status || "-"}</Badge>;
  }
};

const DetailReward = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { toast } = useToast();
  
  // ✅ STATE UNTUK MENYIMPAN REWARD DATA
  const [reward, setReward] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const currentStatus = reward?.status || "pending";

  // Modal states
  const [showConfirmApprove, setShowConfirmApprove] = useState(false);
  const [showConfirmReject, setShowConfirmReject] = useState(false);
  const [showConfirmComplete, setShowConfirmComplete] = useState(false);
  const [showApproveModal, setShowApproveModal] = useState(false);
  const [showRejectModal, setShowRejectModal] = useState(false);
  const [showCompleteModal, setShowCompleteModal] = useState(false);
  const [showImagePreview, setShowImagePreview] = useState(false);

  // ✅ FETCH REWARD DATA - Sama seperti di Reward.tsx
  useEffect(() => {
    const fetchData = async () => {
      if (!id) return;
      
      setLoading(true);
      try {
        const response = await rewardApi.getById(id);
        // Ambil data dari response.data seperti di Reward.tsx
        const data = response.data;
        if (data) {
          setReward(data);
          console.log('✅ Reward loaded:', data);
        } else {
          toast({
            title: "Error",
            description: "Reward tidak ditemukan",
            variant: "destructive",
          });
          navigate(-1);
        }
      } catch (error) {
        console.error('❌ Error loading reward:', error);
        toast({
          title: "Error",
          description: "Gagal memuat data reward",
          variant: "destructive",
        });
        navigate(-1);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [id]);

  // Loading state
  if (loading) {
    return (
      <div className="p-6 flex items-center justify-center">
        <p>Loading...</p>
      </div>
    );
  }

  // Reward not found
  if (!reward) {
    return (
      <div className="p-6">
        <p>Data reward tidak ditemukan</p>
        <Button onClick={() => navigate(-1)} className="mt-4">Kembali</Button>
      </div>
    );
  }

  // ✅ HANDLE STATUS CHANGES
  const handleApproveClick = () => {
    setShowConfirmApprove(true);
  };

  const handleRejectClick = () => {
    setShowConfirmReject(true);
  };

  const handleCompleteClick = () => {
    setShowConfirmComplete(true);
  };

  const handleConfirmApprove = async () => {
    if (!id) return;
    
    try {
      await rewardApi.updateStatus(id, "approved");
      
      // Refresh reward data - ambil dari response.data seperti di Reward.tsx
      const response = await rewardApi.getById(id);
      const updatedReward = response.data;
      if (updatedReward) {
        setReward(updatedReward);
      }
      
      setShowConfirmApprove(false);
      setShowApproveModal(true);
      
      toast({
        title: "Berhasil",
        description: "Reward berhasil disetujui",
      });
    } catch (error) {
      console.error('❌ Error approving reward:', error);
      toast({
        title: "Error",
        description: "Gagal menyetujui reward",
        variant: "destructive",
      });
    }
  };

  const handleConfirmReject = async () => {
    if (!id) return;
    
    try {
      await rewardApi.updateStatus(id, "rejected");
      
      // Refresh reward data - ambil dari response.data seperti di Reward.tsx
      const response = await rewardApi.getById(id);
      const updatedReward = response.data;
      if (updatedReward) {
        setReward(updatedReward);
      }
      
      setShowConfirmReject(false);
      setShowRejectModal(true);
      
      toast({
        title: "Berhasil",
        description: "Reward berhasil ditolak",
      });
    } catch (error) {
      console.error('❌ Error rejecting reward:', error);
      toast({
        title: "Error",
        description: "Gagal menolak reward",
        variant: "destructive",
      });
    }
  };

  const handleConfirmComplete = async () => {
    if (!id) return;
    
    try {
      await rewardApi.updateStatus(id, "completed");
      
      // Refresh reward data - ambil dari response.data seperti di Reward.tsx
      const response = await rewardApi.getById(id);
      const updatedReward = response.data;
      if (updatedReward) {
        setReward(updatedReward);
      }
      
      setShowConfirmComplete(false);
      setShowCompleteModal(true);
      
      toast({
        title: "Berhasil",
        description: "Reward ditandai selesai",
      });
    } catch (error) {
      console.error('❌ Error completing reward:', error);
      toast({
        title: "Error",
        description: "Gagal menyelesaikan reward",
        variant: "destructive",
      });
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button 
          variant="ghost" 
          size="icon" 
          onClick={() => navigate(-1)}
          className="h-8 w-8"
        >
          <ChevronLeft size={20} />
        </Button>
        <h1 className="text-xl font-semibold">Detail Reward</h1>
      </div>

      {/* Main Content */}
      <div className="bg-card rounded-lg p-6 shadow-sm">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <div className="relative">
              <div className="h-20 w-20 rounded-full bg-orange-100 flex items-center justify-center border-4 border-orange-200">
                <Gift size={36} className="text-orange-600" />
              </div>
            </div>
            <div>
              <h2 className="text-lg font-semibold">{reward.reward_name || "Reward"}</h2>
              <p className="text-muted-foreground text-sm">ID Redemption: #{reward.id}</p>
              <span className="text-primary font-medium text-sm">User ID: {reward.user_id}</span>
              <div className="mt-2">
                {getStatusBadge(reward.status)}
              </div>
            </div>
          </div>
        </div>

        {/* Informasi User - Sama seperti di tabel Reward.tsx */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Informasi User</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="text-sm text-muted-foreground">Nama Lengkap</label>
              <Input 
                value={reward.user_name || "-"} 
                readOnly
                className="mt-1 bg-muted/50"
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Email</label>
              <Input 
                value={reward.user_email || "-"} 
                readOnly
                className="mt-1 bg-muted/50"
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground">No. Telepon</label>
              <Input 
                value={reward.user_phone || "-"} 
                readOnly
                className="mt-1 bg-muted/50"
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground flex items-center gap-1">
                <Coins size={14} className="text-yellow-500" />
                Total Poin User
              </label>
              <Input 
                value={reward.user_total_points || 0} 
                readOnly
                className="mt-1 bg-yellow-50 border-yellow-200 text-yellow-700 font-semibold"
              />
            </div>
            <div className="md:col-span-2">
              <label className="text-sm text-muted-foreground flex items-center gap-1">
                <MapPin size={14} />
                Alamat Pengiriman
              </label>
              <Input 
                value={reward.user_address || "-"} 
                readOnly
                className="mt-1 bg-muted/50"
              />
            </div>
          </div>
        </div>

        {/* Informasi Reward */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Informasi Reward</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="md:col-span-2 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="text-sm text-muted-foreground">Nama Reward</label>
                  <Input 
                    value={reward.reward_name || "-"} 
                    readOnly
                    className="mt-1 bg-muted/50"
                  />
                </div>
                <div>
                  <label className="text-sm text-muted-foreground">Poin yang Diperlukan</label>
                  <Input 
                    value={reward.points_cost || 0} 
                    readOnly
                    className="mt-1 bg-yellow-50 border-yellow-200 text-yellow-700 font-semibold"
                  />
                </div>
                <div className="md:col-span-2">
                  <label className="text-sm text-muted-foreground">Deskripsi</label>
                  <Input 
                    value={reward.reward_description || "-"} 
                    readOnly
                    className="mt-1 bg-muted/50"
                  />
                </div>
              </div>
            </div>
            <div className="flex justify-center md:justify-end">
              {reward.reward_image ? (
                <img 
                  src={reward.reward_image} 
                  alt={reward.reward_name}
                  className="w-48 h-auto rounded-lg border-2 border-orange-200 shadow-md object-cover cursor-pointer hover:opacity-90 hover:shadow-lg transition-all"
                  onClick={() => setShowImagePreview(true)}
                />
              ) : (
                <div className="w-48 h-48 rounded-lg border-2 border-dashed border-orange-200 flex items-center justify-center bg-orange-50">
                  <Gift size={48} className="text-orange-300" />
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Detail Penukaran - Sama seperti di tabel Reward.tsx */}
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Detail Penukaran</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="text-sm text-muted-foreground">Poin Digunakan</label>
              <Input 
                value={reward.points_spent || 0} 
                readOnly
                className="mt-1 bg-primary/10 text-primary font-semibold"
              />
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Status</label>
              <div className="mt-1">
                {getStatusBadge(reward.status)}
              </div>
            </div>
            <div>
              <label className="text-sm text-muted-foreground">Tanggal Penukaran</label>
              <Input 
                value={formatDate(reward.created_at)} 
                readOnly
                className="mt-1 bg-muted/50"
              />
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="mt-8 flex gap-4 flex-wrap">
          {currentStatus === "pending" && (
            <>
              <Button 
                className="bg-primary hover:bg-primary/90 text-primary-foreground px-8"
                onClick={handleApproveClick}
              >
                Setuju
              </Button>
              <Button 
                variant="outline"
                className="border-red-500 text-red-500 hover:bg-red-50 px-8"
                onClick={handleRejectClick}
              >
                Tolak
              </Button>
            </>
          )}
          {currentStatus === "approved" && (
            <Button 
              className="bg-green-600 hover:bg-green-700 text-white px-8 gap-2"
              onClick={handleCompleteClick}
            >
              <CheckCircle size={16} />
              Tandai Selesai
            </Button>
          )}
          {currentStatus === "rejected" && (
            <p className="text-red-500 font-medium">Reward ini ditolak</p>
          )}
          {currentStatus === "completed" && (
            <p className="text-green-600 font-medium flex items-center gap-2">
              <CheckCircle size={16} />
              Reward telah selesai diproses
            </p>
          )}
        </div>
      </div>

      {/* Modal: Konfirmasi Setuju */}
      <Dialog open={showConfirmApprove} onOpenChange={setShowConfirmApprove}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda akan menyetujui reward ini.</h2>
            <p className="text-muted-foreground mb-6">Apakah Anda yakin?</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-muted rounded-lg flex items-center justify-center">
                <Gift size={48} className="text-muted-foreground" />
              </div>
              <div className="absolute -bottom-2 -right-2 bg-green-500 rounded-full p-1"><CheckCircle size={20} className="text-white" /></div>
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowConfirmApprove(false)} className="min-w-24">Kembali</Button>
              <Button className="min-w-24 bg-primary hover:bg-primary/90" onClick={handleConfirmApprove}>Ya, Setuju</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Konfirmasi Tolak */}
      <Dialog open={showConfirmReject} onOpenChange={setShowConfirmReject}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda akan menolak reward ini.</h2>
            <p className="text-muted-foreground mb-6">Apakah Anda yakin?</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-muted rounded-lg flex items-center justify-center">
                <Gift size={48} className="text-muted-foreground" />
              </div>
              <div className="absolute -bottom-2 -right-2 bg-red-500 rounded-full p-1"><XCircle size={20} className="text-white" /></div>
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowConfirmReject(false)} className="min-w-24">Kembali</Button>
              <Button className="min-w-24 bg-red-500 hover:bg-red-600" onClick={handleConfirmReject}>Ya, Tolak</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Modal: Konfirmasi Selesai */}
      <Dialog open={showConfirmComplete} onOpenChange={setShowConfirmComplete}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda akan menandai reward ini sebagai selesai.</h2>
            <p className="text-muted-foreground mb-6">Apakah Anda yakin?</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-green-100 rounded-lg flex items-center justify-center">
                <Gift size={48} className="text-green-600" />
              </div>
              <div className="absolute -bottom-2 -right-2 bg-green-500 rounded-full p-1"><CheckCircle size={20} className="text-white" /></div>
            </div>
            <div className="flex gap-3">
              <Button variant="outline" onClick={() => setShowConfirmComplete(false)} className="min-w-24">Kembali</Button>
              <Button className="min-w-24 bg-green-600 hover:bg-green-700" onClick={handleConfirmComplete}>Ya, Selesai</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Approve Success Modal */}
      <Dialog open={showApproveModal} onOpenChange={setShowApproveModal}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Anda telah berhasil menyetujui reward.</h2>
            <p className="text-muted-foreground mb-6">Semua data sudah diperbarui.</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle size={40} className="text-green-600" />
              </div>
            </div>
            <Button className="min-w-24" onClick={() => { setShowApproveModal(false); navigate("/dashboard/reward"); }}>Oke</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Reject Modal */}
      <Dialog open={showRejectModal} onOpenChange={setShowRejectModal}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-6">Anda telah menolak reward ini.</h2>
            <div className="relative mb-6">
              <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center">
                <XCircle size={40} className="text-red-600" />
              </div>
            </div>
            <Button className="min-w-24" onClick={() => { setShowRejectModal(false); navigate("/dashboard/reward"); }}>Oke</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Complete Modal */}
      <Dialog open={showCompleteModal} onOpenChange={setShowCompleteModal}>
        <DialogContent className="sm:max-w-md text-center">
          <div className="flex flex-col items-center py-4">
            <h2 className="text-lg font-semibold mb-2">Reward telah ditandai selesai.</h2>
            <p className="text-muted-foreground mb-6">Semua data sudah diperbarui.</p>
            <div className="relative mb-6">
              <div className="w-20 h-24 bg-green-100 rounded-lg flex items-center justify-center">
                <CheckCircle size={40} className="text-green-600" />
              </div>
            </div>
            <Button className="min-w-24" onClick={() => { setShowCompleteModal(false); navigate("/dashboard/reward"); }}>Oke</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Image Preview Modal */}
      <Dialog open={showImagePreview} onOpenChange={setShowImagePreview}>
        <DialogContent className="sm:max-w-2xl p-4">
          <div className="flex flex-col items-center">
            <h3 className="text-lg font-semibold mb-4">Preview Reward</h3>
            <img 
              src={reward.reward_image} 
              alt={reward.reward_name}
              className="w-full max-w-lg h-auto rounded-lg border-2 border-orange-200 shadow-lg"
            />
            <p className="mt-4 text-sm text-muted-foreground">
              {reward.reward_name} - {reward.points_cost} poin
            </p>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default DetailReward;
