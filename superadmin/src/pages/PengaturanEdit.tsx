import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Eye, EyeOff, Camera } from "lucide-react";
import SavePengaturanPopup from "@/components/SavePengaturanPopup";
import { useAdmin } from "@/contexts/AdminContext";

const PengaturanEdit = () => {
  const navigate = useNavigate();
  const { profile, updateProfile } = useAdmin();
  
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [showSavePopup, setShowSavePopup] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [passwordError, setPasswordError] = useState("");
  const [emailError, setEmailError] = useState("");
  const [phoneError, setPhoneError] = useState("");
  const [previewPhoto, setPreviewPhoto] = useState(profile.foto);

  const [profileData, setProfileData] = useState({
    namaLengkap: profile.namaLengkap,
    email: profile.email,
    tempatLahir: profile.tempatLahir,
    tanggalLahir: profile.tanggalLahir,
    jenisKelamin: profile.jenisKelamin,
    noTlp: profile.noTlp,
  });

  const handlePhotoUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 2 * 1024 * 1024) {
        alert("Ukuran foto maksimal 2MB");
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        const base64String = reader.result as string;
        setPreviewPhoto(base64String);
      };
      reader.readAsDataURL(file);
    }
  };

  const [passwordData, setPasswordData] = useState({
    newPassword: "",
    confirmPassword: "",
  });

  const getInitials = (name: string) => {
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  const validateEmail = (email: string) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const validatePhone = (phone: string) => {
    const phoneRegex = /^[0-9]{10,13}$/;
    return phoneRegex.test(phone);
  };

  const validateForm = () => {
    let isValid = true;

    // Validate email
    if (!profileData.email.trim()) {
      setEmailError("Email tidak boleh kosong");
      isValid = false;
    } else if (!validateEmail(profileData.email)) {
      setEmailError("Format email tidak valid");
      isValid = false;
    } else {
      setEmailError("");
    }

    // Validate phone
    if (!profileData.noTlp.trim()) {
      setPhoneError("Nomor telepon tidak boleh kosong");
      isValid = false;
    } else if (!validatePhone(profileData.noTlp)) {
      setPhoneError("Nomor telepon harus 10-13 digit angka");
      isValid = false;
    } else {
      setPhoneError("");
    }

    // Validate passwords
    if (passwordData.newPassword || passwordData.confirmPassword) {
      if (passwordData.newPassword !== passwordData.confirmPassword) {
        setPasswordError("Password baru dan konfirmasi password tidak sama");
        isValid = false;
      } else if (passwordData.newPassword.length < 6) {
        setPasswordError("Password minimal 6 karakter");
        isValid = false;
      } else {
        setPasswordError("");
      }
    } else {
      setPasswordError("");
    }

    return isValid;
  };

  const handleSaveClick = () => {
    if (validateForm()) {
      setShowSavePopup(true);
    }
  };

  const handleEmailChange = (value: string) => {
    setProfileData({ ...profileData, email: value });
    if (emailError) setEmailError("");
  };

  const handlePhoneChange = (value: string) => {
    // Only allow numbers
    const numericValue = value.replace(/[^0-9]/g, "");
    setProfileData({ ...profileData, noTlp: numericValue });
    if (phoneError) setPhoneError("");
  };

  const handleConfirmSave = () => {
    // Update the global admin profile including photo
    updateProfile({ ...profileData, foto: previewPhoto });
    setShowSuccess(true);
  };

  const handleSuccessClose = () => {
    setShowSavePopup(false);
    setShowSuccess(false);
    navigate("/dashboard/pengaturan");
  };

  const handleCancelSave = () => {
    setShowSavePopup(false);
  };

  const handleCancel = () => {
    navigate("/dashboard/pengaturan");
  };

  const handlePasswordChange = (field: "newPassword" | "confirmPassword", value: string) => {
    setPasswordData({ ...passwordData, [field]: value });
    if (passwordError) {
      setPasswordError("");
    }
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-foreground">Edit Pengaturan</h1>

      <Card className="shadow-sm">
        <CardContent className="p-6">
          {/* Profile Header with Photo Upload */}
          <div className="flex items-center gap-4 mb-8">
            <div className="relative">
              <Avatar className="h-20 w-20">
                <AvatarImage src={previewPhoto} />
                <AvatarFallback className="bg-muted text-muted-foreground text-2xl">
                  {getInitials(profileData.namaLengkap)}
                </AvatarFallback>
              </Avatar>
              <label className="absolute bottom-0 right-0 bg-primary text-primary-foreground rounded-full p-1.5 hover:bg-primary/90 cursor-pointer">
                <Camera className="h-4 w-4" />
                <input
                  type="file"
                  accept="image/*"
                  onChange={handlePhotoUpload}
                  className="hidden"
                />
              </label>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-foreground">{profileData.namaLengkap}</h2>
              <p className="text-sm text-muted-foreground">{profile.layanan}</p>
              <p className="text-sm text-muted-foreground">{profile.role}</p>
            </div>
          </div>

          {/* Informasi Pribadi */}
          <div className="space-y-6">
            <h3 className="text-lg font-semibold text-foreground">Informasi Pribadi</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Nama Lengkap</Label>
                <Input
                  value={profileData.namaLengkap}
                  onChange={(e) => setProfileData({ ...profileData, namaLengkap: e.target.value })}
                  className="bg-muted/50 border-muted"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Email</Label>
                <Input
                  type="email"
                  value={profileData.email}
                  onChange={(e) => handleEmailChange(e.target.value)}
                  className={`bg-muted/50 border-muted ${emailError ? "border-destructive" : ""}`}
                />
                {emailError && <p className="text-sm text-destructive">{emailError}</p>}
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Tempat Lahir</Label>
                <Input
                  value={profileData.tempatLahir}
                  onChange={(e) => setProfileData({ ...profileData, tempatLahir: e.target.value })}
                  className="bg-muted/50 border-muted"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Tanggal Lahir</Label>
                <div className="relative">
                  <Input
                    type="date"
                    value="1999-02-01"
                    onChange={(e) => setProfileData({ ...profileData, tanggalLahir: e.target.value })}
                    className="bg-muted/50 border-muted"
                  />
                </div>
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Jenis Kelamin</Label>
                <Select
                  value={profileData.jenisKelamin}
                  onValueChange={(value) => setProfileData({ ...profileData, jenisKelamin: value })}
                >
                  <SelectTrigger className="bg-muted/50 border-muted">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">No. Tlp</Label>
                <Input
                  value={profileData.noTlp}
                  onChange={(e) => handlePhoneChange(e.target.value)}
                  className={`bg-muted/50 border-muted ${phoneError ? "border-destructive" : ""}`}
                  maxLength={13}
                />
                {phoneError && <p className="text-sm text-destructive">{phoneError}</p>}
              </div>
            </div>
          </div>

          {/* Informasi Akun */}
          <div className="space-y-6 mt-8">
            <h3 className="text-lg font-semibold text-foreground">Ubah Password</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Password Baru</Label>
                <div className="relative">
                  <Input
                    type={showNewPassword ? "text" : "password"}
                    placeholder="Masukkan Password Baru"
                    value={passwordData.newPassword}
                    onChange={(e) => handlePasswordChange("newPassword", e.target.value)}
                    className={`bg-muted/50 border-muted pr-10 ${passwordError ? "border-destructive" : ""}`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowNewPassword(!showNewPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2"
                  >
                    {showNewPassword ? (
                      <EyeOff className="h-4 w-4 text-muted-foreground" />
                    ) : (
                      <Eye className="h-4 w-4 text-muted-foreground" />
                    )}
                  </button>
                </div>
              </div>

              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Konfirmasi Password Baru</Label>
                <div className="relative">
                  <Input
                    type={showConfirmPassword ? "text" : "password"}
                    placeholder="Masukkan Password Baru"
                    value={passwordData.confirmPassword}
                    onChange={(e) => handlePasswordChange("confirmPassword", e.target.value)}
                    className={`bg-muted/50 border-muted pr-10 ${passwordError ? "border-destructive" : ""}`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2"
                  >
                    {showConfirmPassword ? (
                      <EyeOff className="h-4 w-4 text-muted-foreground" />
                    ) : (
                      <Eye className="h-4 w-4 text-muted-foreground" />
                    )}
                  </button>
                </div>
              </div>
              
              {passwordError && (
                <div className="md:col-span-2">
                  <p className="text-sm text-destructive">{passwordError}</p>
                </div>
              )}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-4 mt-8">
            <Button onClick={handleSaveClick}>
              Simpan Perubahan
            </Button>
            <Button variant="outline" onClick={handleCancel}>
              Batal
            </Button>
          </div>
        </CardContent>
      </Card>

      <SavePengaturanPopup
        open={showSavePopup}
        onOpenChange={setShowSavePopup}
        onConfirm={handleConfirmSave}
        onCancel={handleCancelSave}
        showSuccess={showSuccess}
        onSuccessClose={handleSuccessClose}
      />
    </div>
  );
};

export default PengaturanEdit;
