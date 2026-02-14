import { useEffect, useState } from "react";
import DashboardLayout from "@/components/DashboardLayout";
import { ProfileHeader } from "@/components/ui/pengaturan/profile-header";
import { PersonalInfoForm } from "@/components/ui/pengaturan/personal-info-form";
import { AccountInfoForm } from "@/components/ui/pengaturan/account-info-form";
import { Button } from "@/components/ui/button";
import api from "@/lib/api";
import { toast } from "sonner";

// Get user ID from logged in user
const getUserId = () => {
  const userStr = localStorage.getItem("user");
  if (userStr) {
    try {
      const user = JSON.parse(userStr);
      return user.id;
    } catch (e) {
      console.error("Error parsing user data:", e);
    }
  }
  return null;
};

interface ProfileData {
  name: string;
  email: string;
  role: string;
  phone: string;
  address: string;
  profile_photo?: string;
}

const Pengaturan = () => {
  const [profile, setProfile] = useState<ProfileData | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditProfile, setIsEditProfile] = useState(false);
  const [isEditPassword, setIsEditPassword] = useState(false);
  const [profileImage, setProfileImage] = useState<string>("");
  
  const [formData, setFormData] = useState({
    nama_lengkap: "",
    email: "",
    alamat: "",
    no_tlp: "",
  });

  const [passwordData, setPasswordData] = useState({
    current: "**********",
    new: "",
    confirm: "",
  });

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    const userId = getUserId();
    if (!userId) {
      toast.error("User belum login");
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const res = await api.get(`/users/profile/${userId}`);
      const data = res.data;
      setProfile(data);
      setProfileImage(data.profile_photo ? `http://localhost:8000/storage/${data.profile_photo}` : "");
      
      setFormData({
        nama_lengkap: data.name || "",
        email: data.email || "",
        alamat: data.address || "",
        no_tlp: data.phone || "",
      });
    } catch (error) {
      console.error("Error fetching profile:", error);
      toast.error("Gagal mengambil data profil");
    } finally {
      setLoading(false);
    }
  };

  const handleImageUpload = async (file: File) => {
    const userId = getUserId();
    if (!userId) {
      toast.error("User belum login");
      return;
    }

    // Validate file size (max 2MB)
    if (file.size > 2 * 1024 * 1024) {
      toast.error("Ukuran file maksimal 2MB");
      return;
    }

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast.error("File harus berupa gambar");
      return;
    }

    try {
      // Preview image immediately
      const reader = new FileReader();
      reader.onloadend = () => {
        setProfileImage(reader.result as string);
      };
      reader.readAsDataURL(file);

      // Upload to server
      const formData = new FormData();
      formData.append('profile_image', file);

      await api.post(`/users/profile/${userId}/upload-image`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });

      toast.success("Foto profil berhasil diupload");
      fetchProfile(); // Refresh profile data
    } catch (error) {
      console.error("Error uploading image:", error);
      toast.error("Gagal mengupload foto profil");
    }
  };

  const handleFormChange = (field: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handlePasswordChange = (field: 'new' | 'confirm', value: string) => {
    setPasswordData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const handleSaveProfile = async () => {
    const userId = getUserId();
    if (!userId) {
      toast.error("User belum login");
      return;
    }

    try {
      await api.put(`/users/profile/${userId}`, {
        name: formData.nama_lengkap,
        email: formData.email,
        phone: formData.no_tlp,
        address: formData.alamat,
      });
      
      toast.success("Profil berhasil diperbarui");
      setIsEditProfile(false);
      fetchProfile();
    } catch (error) {
      console.error("Error updating profile:", error);
      toast.error("Gagal memperbarui profil");
    }
  };

  const handleSavePassword = async () => {
    if (!passwordData.new) {
      toast.error("Password baru tidak boleh kosong");
      return;
    }

    if (passwordData.new !== passwordData.confirm) {
      toast.error("Konfirmasi password tidak cocok");
      return;
    }

    const userId = getUserId();
    if (!userId) {
      toast.error("User belum login");
      return;
    }

    try {
      await api.put(`/users/account/${userId}`, {
        password: passwordData.new
      });
      
      toast.success("Password berhasil diperbarui");
      setIsEditPassword(false);
      setPasswordData({
        current: "**********",
        new: "",
        confirm: "",
      });
    } catch (error) {
      console.error("Error updating password:", error);
      toast.error("Gagal memperbarui password");
    }
  };

  const handleCancelProfile = () => {
    setIsEditProfile(false);
    if (profile) {
      setFormData({
        nama_lengkap: profile.name || "",
        email: profile.email || "",
        alamat: profile.address || "",
        no_tlp: profile.phone || "",
      });
    }
  };

  const handleCancelPassword = () => {
    setIsEditPassword(false);
    setPasswordData({
      current: "**********",
      new: "",
      confirm: "",
    });
  };

  if (loading) {
    return (
      <DashboardLayout title="Pengaturan">
        <div className="flex items-center justify-center py-12">
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </DashboardLayout>
    );
  }

  if (!profile) {
    return (
      <DashboardLayout title="Pengaturan">
        <div className="flex items-center justify-center py-12">
          <p className="text-muted-foreground">Data tidak ditemukan</p>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout title="Pengaturan">
      <ProfileHeader
        name={profile.name}
        role="Nebeng Motor"
        badge="Super Admin"
        onEdit={() => setIsEditProfile(!isEditProfile)}
        profileImage={profileImage}
        onImageChange={handleImageUpload}
      />

      <div className="space-y-6">
        <PersonalInfoForm
          formData={formData}
          isEdit={isEditProfile}
          onChange={handleFormChange}
        />

        {isEditProfile && (
          <div className="flex justify-end gap-3">
            <Button
              variant="outline"
              onClick={handleCancelProfile}
            >
              Batal
            </Button>
            <Button onClick={handleSaveProfile}>
              Simpan Perubahan
            </Button>
          </div>
        )}

        <AccountInfoForm
          currentPassword={passwordData.current}
          isEdit={isEditPassword}
          onEdit={() => setIsEditPassword(!isEditPassword)}
          onPasswordChange={handlePasswordChange}
          newPassword={passwordData.new}
          confirmPassword={passwordData.confirm}
        />

        {isEditPassword && (
          <div className="flex justify-end gap-3">
            <Button
              variant="outline"
              onClick={handleCancelPassword}
            >
              Batal
            </Button>
            <Button onClick={handleSavePassword}>
              Simpan Password
            </Button>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
};

export default Pengaturan;
