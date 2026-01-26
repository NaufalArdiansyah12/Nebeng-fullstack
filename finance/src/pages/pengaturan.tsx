import { Search } from "lucide-react";
import { useEffect, useState } from "react";
import DashboardLayout from "@/components/DashboardLayout";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue
} from "@/components/ui/select";
import api from "@/lib/api";

const USER_ID = 4; // ⬅️ sementara (nanti dari auth)

const Pengaturan = () => {
  const [isEdit, setIsEdit] = useState(false);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true)
  const [newPassword, setNewPassword] = useState("");
const [confirmPassword, setConfirmPassword] = useState("");

  /* =========================
     FETCH PROFILE
  ========================= */
  useEffect(() => {
    api.get(`/users/profile/${USER_ID}`)
      .then(res => {
        setProfile(res.data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  /* =========================
     HANDLE CHANGE
  ========================= */
  const handleChange = (e) => {
    setProfile({
      ...profile,
      [e.target.name]: e.target.value
    });
  };

  if (loading) {
    return (
      <DashboardLayout title="Pengaturan">
        <p>loading...</p>
      </DashboardLayout>
    );
  }

const handleSave = async () => {
  if (newPassword && newPassword !== confirmPassword) {
    alert("konfirmasi password tidak sama");
    return;
  }

  try {
    // update profile
    await api.put(`/users/profile/${USER_ID}`, {
      name: profile.name,
      phone: profile.phone,
      gender: profile.gender,
      address: profile.address
    });

    // update account (email / password)
    if (profile.email || newPassword) {
      await api.put(`/users/account/${USER_ID}`, {
        email: profile.email,
        password: newPassword || null
      });
    }

    alert("data berhasil diperbarui");
    setIsEdit(false);
    setNewPassword("");
    setConfirmPassword("");
  } catch (error) {
    alert("gagal update data");
  }
};



  return (
    <DashboardLayout title="Pengaturan">
      <div className="space-y-6">

        {/* Search */}
        <div className="flex justify-end">
          <div className="relative w-64">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input placeholder="Search" className="pl-9" />
          </div>
        </div>

        {/* Card */}
        <div className="bg-background border border-border rounded-xl p-6 space-y-6">

          {/* Profile Header */}
          <div className="flex items-center justify-between bg-muted/40 rounded-lg p-4">
            <div className="flex items-center gap-4">
              <div className="w-14 h-14 rounded-full bg-muted flex items-center justify-center font-semibold">
                {profile.name?.charAt(0)}
              </div>
              <div>
                <p className="font-semibold">{profile.name}</p>
                <p className="text-sm text-muted-foreground">
                  {profile.email}
                </p>
                <Badge className="mt-1 bg-blue-500">
                  {profile.role}
                </Badge>
              </div>
            </div>

            <Button
              size="sm"
              variant="outline"
              onClick={() => setIsEdit(!isEdit)}
            >
              {isEdit ? "Batal" : "Edit"}
            </Button>
          </div>

          {/* Informasi Pribadi */}
          <div className="space-y-4">
            <h3 className="font-semibold">Informasi Pribadi</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-xs text-muted-foreground">
                  Nama Lengkap
                </label>
                <Input
                  name="name"
                  value={profile.name || ""}
                  disabled={!isEdit}
                  onChange={handleChange}
                />
              </div>

              <div>
  <label className="text-xs text-muted-foreground">Email</label>
  <Input
    name="email"
    value={profile.email}
    disabled={!isEdit}
    onChange={handleChange}
  />
</div>

<div>
  <label className="text-xs text-muted-foreground">
    Password Baru
  </label>
  <Input
    type="password"
    placeholder="Password baru"
    disabled={!isEdit}
    value={newPassword}
    onChange={(e) => setNewPassword(e.target.value)}
  />
</div>

<div>
  <label className="text-xs text-muted-foreground">
    Konfirmasi Password
  </label>
  <Input
    type="password"
    placeholder="Ulangi password"
    disabled={!isEdit}
    value={confirmPassword}
    onChange={(e) => setConfirmPassword(e.target.value)}
  />
</div>



              <div>
                <label className="text-xs text-muted-foreground">
                  Jenis Kelamin
                </label>
                <Select
                  disabled={!isEdit}
                  value={profile.gender || ""}
                  onValueChange={(value) =>
                    setProfile({ ...profile, gender: value })
                  }
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Pilih" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">
                      Laki - Laki
                    </SelectItem>
                    <SelectItem value="Perempuan">
                      Perempuan
                    </SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-xs text-muted-foreground">
                  No. Telp
                </label>
                <Input
                  name="phone"
                  value={profile.phone || ""}
                  disabled={!isEdit}
                  onChange={handleChange}
                />
              </div>

              <div className="md:col-span-2">
                <label className="text-xs text-muted-foreground">
                  Alamat
                </label>
                <Input
                  name="address"
                  value={profile.address || ""}
                  disabled={!isEdit}
                  onChange={handleChange}
                />
              </div>
            </div>
          </div>

          {/* Footer */}
          {isEdit && (
            <div className="flex justify-end gap-3">
              <Button
                variant="outline"
                onClick={() => setIsEdit(false)}
              >
                Batal
              </Button>
              <Button onClick={handleSave}>
  Simpan
</Button>
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
};

export default Pengaturan;
