import { useState, useEffect } from "react";
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
import { Eye, EyeOff, Pencil, Calendar, Check, X } from "lucide-react";
import { useAdmin } from "@/contexts/AdminContext";
import { toast } from "sonner";

const Pengaturan = () => {
  const { profile, updateProfile, loading } = useAdmin();
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [isEditingPassword, setIsEditingPassword] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  // State untuk form data - akan di-update ketika profile berubah
  const [formData, setFormData] = useState({
    namaLengkap: "",
    email: "",
    tempatLahir: "",
    tanggalLahir: "",
    jenisKelamin: "",
    noTlp: "",
  });

  const [passwordData, setPasswordData] = useState({
    currentPassword: "••••••••",
    newPassword: "",
    confirmPassword: "",
  });

  // ✅ UPDATE formData ketika profile dari context berubah
  useEffect(() => {
    if (profile && !loading) {
      console.log('📝 Updating form data with profile:', profile);
      setFormData({
        namaLengkap: profile.namaLengkap || "",
        email: profile.email || "",
        tempatLahir: profile.tempatLahir || "",
        tanggalLahir: profile.tanggalLahir || "",
        jenisKelamin: profile.jenisKelamin || "",
        noTlp: profile.noTlp || "",
      });
    }
  }, [profile, loading]);

  const getInitials = (name: string) => {
    if (!name) return "AD";
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  };

  const handleSaveProfile = async () => {
    // Validasi
    if (!formData.namaLengkap || !formData.email) {
      toast.error("Nama lengkap dan email harus diisi!");
      return;
    }

    try {
      // Update profile menggunakan context
      await updateProfile(formData);
      setIsEditingProfile(false);
      toast.success("Profil berhasil diperbarui!");
    } catch (error) {
      console.error('Error updating profile:', error);
      toast.error("Gagal memperbarui profil!");
    }
  };

  const handleCancelEdit = () => {
    // Reset form data ke data profile asli
    setFormData({
      namaLengkap: profile.namaLengkap || "",
      email: profile.email || "",
      tempatLahir: profile.tempatLahir || "",
      tanggalLahir: profile.tanggalLahir || "",
      jenisKelamin: profile.jenisKelamin || "",
      noTlp: profile.noTlp || "",
    });
    setIsEditingProfile(false);
  };

  const handleSavePassword = () => {
    if (passwordData.newPassword !== passwordData.confirmPassword) {
      toast.error("Password baru dan konfirmasi password tidak cocok!");
      return;
    }
    if (passwordData.newPassword.length < 6) {
      toast.error("Password minimal 6 karakter!");
      return;
    }
    
    // TODO: Implement password update API
    toast.success("Password berhasil diperbarui!");
    setIsEditingPassword(false);
    setPasswordData({
      currentPassword: "••••••••",
      newPassword: "",
      confirmPassword: "",
    });
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <h1 className="text-2xl font-semibold text-foreground">Pengaturan</h1>
        <Card className="shadow-sm">
          <CardContent className="p-6">
            <div className="flex items-center justify-center h-64">
              <p className="text-muted-foreground">Loading...</p>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-foreground">Pengaturan</h1>

      <Card className="shadow-sm">
        <CardContent className="p-6">
          {/* Profile Header */}
          <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-4">
              <Avatar className="h-16 w-16">
                <AvatarImage src={profile.foto} />
                <AvatarFallback className="bg-muted text-muted-foreground text-xl">
                  {getInitials(profile.namaLengkap)}
                </AvatarFallback>
              </Avatar>
              <div>
                <h2 className="text-lg font-semibold text-foreground">{profile.namaLengkap || "Administrator"}</h2>
                <p className="text-sm text-muted-foreground">{profile.layanan || "Nebeng"}</p>
                <p className="text-sm text-muted-foreground">{profile.role || "Admin"}</p>
              </div>
            </div>
            {!isEditingProfile ? (
              <Button
                variant="outline"
                size="sm"
                className="text-primary border-primary hover:bg-primary/10"
                onClick={() => setIsEditingProfile(true)}
              >
                Edit <Pencil className="ml-1 h-4 w-4" />
              </Button>
            ) : (
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleCancelEdit}
                >
                  <X className="mr-1 h-4 w-4" /> Batal
                </Button>
                <Button
                  size="sm"
                  onClick={handleSaveProfile}
                  className="bg-primary hover:bg-primary/90"
                >
                  <Check className="mr-1 h-4 w-4" /> Simpan
                </Button>
              </div>
            )}
          </div>

          {/* Informasi Pribadi */}
          <div className="space-y-6">
            <h3 className="text-lg font-semibold text-foreground">Informasi Pribadi</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Nama Lengkap</Label>
                <Input
                  value={formData.namaLengkap}
                  onChange={(e) => setFormData({ ...formData, namaLengkap: e.target.value })}
                  disabled={!isEditingProfile}
                  className={`bg-muted/50 border-muted disabled:opacity-100 ${isEditingProfile ? 'bg-white' : ''}`}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Email</Label>
                <Input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  disabled={!isEditingProfile}
                  className={`bg-muted/50 border-muted disabled:opacity-100 ${isEditingProfile ? 'bg-white' : ''}`}
                />
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Tempat Lahir</Label>
                <Input
                  value={formData.tempatLahir}
                  onChange={(e) => setFormData({ ...formData, tempatLahir: e.target.value })}
                  disabled={!isEditingProfile}
                  className={`bg-muted/50 border-muted disabled:opacity-100 ${isEditingProfile ? 'bg-white' : ''}`}
                  placeholder="Masukkan tempat lahir"
                />
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Tanggal Lahir</Label>
                <div className="relative">
                  <Input
                    type="date"
                    value={formData.tanggalLahir}
                    onChange={(e) => setFormData({ ...formData, tanggalLahir: e.target.value })}
                    disabled={!isEditingProfile}
                    className={`bg-muted/50 border-muted disabled:opacity-100 pr-10 ${isEditingProfile ? 'bg-white' : ''}`}
                  />
                  <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
                </div>
              </div>
              <div className="space-y-2">
                <Label className="text-sm text-muted-foreground">Jenis Kelamin</Label>
                <Select
                  value={formData.jenisKelamin}
                  onValueChange={(value) => setFormData({ ...formData, jenisKelamin: value })}
                  disabled={!isEditingProfile}
                >
                  <SelectTrigger className={`bg-muted/50 border-muted disabled:opacity-100 ${isEditingProfile ? 'bg-white' : ''}`}>
                    <SelectValue placeholder="Pilih jenis kelamin" />
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
                  value={formData.noTlp}
                  onChange={(e) => setFormData({ ...formData, noTlp: e.target.value })}
                  disabled={!isEditingProfile}
                  className={`bg-muted/50 border-muted disabled:opacity-100 ${isEditingProfile ? 'bg-white' : ''}`}
                  placeholder="08xxxxxxxxxx"
                />
              </div>
            </div>
          </div>

          {/* Informasi Akun */}
          <div className="space-y-6 mt-8">
            <h3 className="text-lg font-semibold text-foreground">Informasi Akun</h3>
            
            <div className="space-y-4">
              <div className="flex items-end gap-4">
                <div className="flex-1 space-y-2">
                  <Label className="text-sm text-muted-foreground">Password</Label>
                  <div className="relative">
                    <Input
                      type={showPassword ? "text" : "password"}
                      value={passwordData.currentPassword}
                      disabled
                      className="bg-muted/50 border-muted disabled:opacity-100 pr-10"
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2"
                    >
                      {showPassword ? (
                        <EyeOff className="h-4 w-4 text-muted-foreground" />
                      ) : (
                        <Eye className="h-4 w-4 text-muted-foreground" />
                      )}
                    </button>
                  </div>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="text-primary border-primary hover:bg-primary/10"
                  onClick={() => setIsEditingPassword(!isEditingPassword)}
                >
                  {isEditingPassword ? "Batal" : "Edit"} <Pencil className="ml-1 h-4 w-4" />
                </Button>
              </div>

              {isEditingPassword && (
                <>
                  <div className="space-y-2 max-w-md">
                    <Label className="text-sm text-muted-foreground">Password Baru</Label>
                    <div className="relative">
                      <Input
                        type={showNewPassword ? "text" : "password"}
                        placeholder="Masukkan Password Baru"
                        value={passwordData.newPassword}
                        onChange={(e) => setPasswordData({ ...passwordData, newPassword: e.target.value })}
                        className="bg-muted/50 border-muted pr-10"
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

                  <div className="space-y-2 max-w-md">
                    <Label className="text-sm text-muted-foreground">Konfirmasi Password Baru</Label>
                    <div className="relative">
                      <Input
                        type={showConfirmPassword ? "text" : "password"}
                        placeholder="Masukkan Password Baru"
                        value={passwordData.confirmPassword}
                        onChange={(e) => setPasswordData({ ...passwordData, confirmPassword: e.target.value })}
                        className="bg-muted/50 border-muted pr-10"
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

                  <Button className="mt-4" onClick={handleSavePassword}>
                    Simpan Password
                  </Button>
                </>
              )}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Pengaturan;