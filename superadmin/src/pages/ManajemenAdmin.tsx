import { useState, useEffect } from "react";
import {
  UserCog, Plus, Pencil, Trash2, KeyRound, Search, Save, Eye, EyeOff, ShieldCheck,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import {
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
} from "@/components/ui/dialog";
import { toast } from "sonner";
import { managemenAdminApi } from "@/services/api";

interface Admin {
  id: number;
  name: string;
  email: string;
  phone?: string;
  role: string;
  created_at?: string;
  updated_at?: string;
}

const emptyForm = { name: "", email: "", phone: "", password: "" };
const emptyPassForm = { newPassword: "", confirmPassword: "" };

const ManajemenAdmin = () => {
  const [admins, setAdmins] = useState<Admin[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [dialogOpen, setDialogOpen] = useState(false);
  const [passDialogOpen, setPassDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [targetAdmin, setTargetAdmin] = useState<Admin | null>(null);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ ...emptyForm });
  const [passForm, setPassForm] = useState({ ...emptyPassForm });
  const [showPassword, setShowPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const loadAdmins = async () => {
    setLoading(true);
    try {
      const res = await managemenAdminApi.getAll();
      setAdmins(Array.isArray(res.data) ? res.data : (res.data?.data ?? []));
    } catch (e) {
      console.error("Failed loading admins", e);
      toast.error("Gagal memuat data admin");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadAdmins(); }, []);

  const openCreate = () => {
    setEditingId(null);
    setForm({ ...emptyForm });
    setShowPassword(false);
    setDialogOpen(true);
  };

  const openEdit = (a: Admin) => {
    setEditingId(a.id);
    setForm({ name: a.name, email: a.email, phone: a.phone || "", password: "" });
    setShowPassword(false);
    setDialogOpen(true);
  };

  const openResetPass = (a: Admin) => {
    setTargetAdmin(a);
    setPassForm({ ...emptyPassForm });
    setShowNewPassword(false);
    setShowConfirmPassword(false);
    setPassDialogOpen(true);
  };

  const handleSave = async () => {
    if (!form.name.trim()) { toast.error("Nama admin wajib diisi."); return; }
    if (!form.email.trim()) { toast.error("Email wajib diisi."); return; }
    if (editingId === null && !form.password.trim()) { toast.error("Password wajib diisi untuk admin baru."); return; }
    setSaving(true);
    try {
      if (editingId !== null) {
        const payload: any = { name: form.name, email: form.email, phone: form.phone };
        await managemenAdminApi.update(String(editingId), payload);
        toast.success("Data admin berhasil diperbarui.");
      } else {
        await managemenAdminApi.create({ ...form, role: "admin" });
        toast.success("Admin baru berhasil ditambahkan.");
      }
      setDialogOpen(false);
      await loadAdmins();
    } catch (err: any) {
      const msg = err?.response?.data?.message || "Gagal menyimpan data admin.";
      toast.error(msg);
    } finally {
      setSaving(false);
    }
  };

  const handleResetPassword = async () => {
    if (!passForm.newPassword.trim()) { toast.error("Password baru wajib diisi."); return; }
    if (passForm.newPassword.length < 6) { toast.error("Password minimal 6 karakter."); return; }
    if (passForm.newPassword !== passForm.confirmPassword) { toast.error("Konfirmasi password tidak cocok."); return; }
    setSaving(true);
    try {
      await managemenAdminApi.resetPassword(String(targetAdmin!.id), { newPassword: passForm.newPassword });
      toast.success(`Password ${targetAdmin!.name} berhasil direset.`);
      setPassDialogOpen(false);
    } catch {
      toast.error("Gagal reset password.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!targetAdmin) return;
    try {
      await managemenAdminApi.delete(String(targetAdmin.id));
      toast.success(`Admin "${targetAdmin.name}" berhasil dihapus.`);
      setDeleteDialogOpen(false);
      setTargetAdmin(null);
      loadAdmins();
    } catch {
      toast.error("Gagal menghapus admin.");
    }
  };

  const formatDate = (d?: string) => {
    if (!d) return "—";
    return new Date(d).toLocaleDateString("id-ID", { day: "2-digit", month: "short", year: "numeric" });
  };

  const filtered = admins.filter(
    (a) =>
      a.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.email.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {[
          { label: "Total Admin", value: admins.length, icon: UserCog, color: "text-[#1e3a5f]", bg: "bg-[#1e3a5f]/10" },
          { label: "Admin Aktif", value: admins.length, icon: ShieldCheck, color: "text-green-600", bg: "bg-green-50" },
        ].map((s) => (
          <Card key={s.label} className="shadow-sm">
            <CardContent className="flex items-center gap-4 p-5">
              <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${s.bg}`}>
                <s.icon className={`h-5 w-5 ${s.color}`} />
              </div>
              <div>
                <p className="text-2xl font-bold">{s.value}</p>
                <p className="text-xs text-muted-foreground">{s.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Table Card */}
      <Card className="shadow-sm">
        <CardHeader className="pb-4">
          <div className="flex items-center justify-between">
            <CardTitle className="text-xl font-semibold">Daftar Admin</CardTitle>
            <Button onClick={openCreate} className="gap-2 bg-[#1e3a5f] hover:bg-[#152a45]">
              <Plus size={16} /> Tambah Admin
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {/* Search */}
          <div className="relative w-72 mb-6">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" size={16} />
            <Input
              placeholder="Cari admin..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 h-10"
            />
          </div>

          {/* Table */}
          <div className="overflow-x-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-[#1e3a5f] text-white">
                  <th className="text-left py-3 px-4 font-medium rounded-tl-lg w-12">NO</th>
                  <th className="text-left py-3 px-4 font-medium">NAMA</th>
                  <th className="text-left py-3 px-4 font-medium">EMAIL</th>
                  <th className="text-left py-3 px-4 font-medium">NO. TELEPON</th>
                  <th className="text-center py-3 px-4 font-medium">ROLE</th>
                  <th className="text-left py-3 px-4 font-medium">DIBUAT</th>
                  <th className="text-center py-3 px-4 font-medium rounded-tr-lg">AKSI</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={7} className="py-16 text-center">
                      <span className="inline-block animate-spin h-6 w-6 border-2 border-[#1e3a5f]/30 border-t-[#1e3a5f] rounded-full" />
                    </td>
                  </tr>
                ) : filtered.length > 0 ? (
                  filtered.map((admin, idx) => (
                    <tr key={admin.id} className="border-b border-border/50 hover:bg-muted/30 transition-colors">
                      <td className="py-3 px-4 text-muted-foreground">{idx + 1}</td>
                      <td className="py-3 px-4 font-medium">{admin.name}</td>
                      <td className="py-3 px-4 text-muted-foreground">{admin.email}</td>
                      <td className="py-3 px-4 text-muted-foreground">{admin.phone || "—"}</td>
                      <td className="py-3 px-4 text-center">
                        <Badge className="bg-[#1e3a5f]/10 text-[#1e3a5f] border border-[#1e3a5f]/20 hover:bg-[#1e3a5f]/20 capitalize">
                          {admin.role}
                        </Badge>
                      </td>
                      <td className="py-3 px-4 text-muted-foreground">{formatDate(admin.created_at)}</td>
                      <td className="py-3 px-4">
                        <div className="flex items-center justify-center gap-1">
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-[#1e3a5f]/10" title="Edit admin" onClick={() => openEdit(admin)}>
                            <Pencil size={15} className="text-[#1e3a5f]" />
                          </Button>
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-amber-50" title="Reset password" onClick={() => openResetPass(admin)}>
                            <KeyRound size={15} className="text-amber-600" />
                          </Button>
                          <Button variant="ghost" size="icon" className="h-8 w-8 hover:bg-red-50" title="Hapus admin"
                            onClick={() => { setTargetAdmin(admin); setDeleteDialogOpen(true); }}>
                            <Trash2 size={15} className="text-red-500" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={7} className="py-16 text-center text-muted-foreground">
                      <UserCog size={36} className="mx-auto mb-3 text-gray-300" />
                      <p>{searchQuery ? "Tidak ada admin yang cocok" : "Belum ada admin terdaftar"}</p>
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>

      {/* Create / Edit Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>{editingId !== null ? "Edit Admin" : "Tambah Admin Baru"}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div>
              <Label className="text-sm font-medium">Nama Lengkap <span className="text-destructive">*</span></Label>
              <Input className="mt-1.5" placeholder="Contoh: Budi Santoso" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
            </div>
            <div>
              <Label className="text-sm font-medium">Email <span className="text-destructive">*</span></Label>
              <Input className="mt-1.5" type="email" placeholder="budi@nebeng.id" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
            </div>
            <div>
              <Label className="text-sm font-medium">No. Telepon</Label>
              <Input className="mt-1.5" placeholder="0812xxxxxxxx" value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
            </div>
            {editingId === null && (
              <div>
                <Label className="text-sm font-medium">Password <span className="text-destructive">*</span></Label>
                <div className="relative mt-1.5">
                  <Input
                    type={showPassword ? "text" : "password"}
                    placeholder="Min. 6 karakter"
                    value={form.password}
                    onChange={(e) => setForm({ ...form, password: e.target.value })}
                    className="pr-10"
                  />
                  <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground" onClick={() => setShowPassword(!showPassword)}>
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>
            )}
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>Batal</Button>
            <Button onClick={handleSave} disabled={saving} className="bg-[#1e3a5f] hover:bg-[#152a45] gap-2">
              {saving ? <span className="animate-spin h-4 w-4 border-2 border-white/30 border-t-white rounded-full" /> : <Save size={15} />}
              {editingId !== null ? "Simpan" : "Tambah Admin"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reset Password Dialog */}
      <Dialog open={passDialogOpen} onOpenChange={setPassDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Reset Password — {targetAdmin?.name}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div>
              <Label className="text-sm font-medium">Password Baru <span className="text-destructive">*</span></Label>
              <div className="relative mt-1.5">
                <Input type={showNewPassword ? "text" : "password"} placeholder="Min. 6 karakter"
                  value={passForm.newPassword} onChange={(e) => setPassForm({ ...passForm, newPassword: e.target.value })} className="pr-10" />
                <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" onClick={() => setShowNewPassword(!showNewPassword)}>
                  {showNewPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>
            <div>
              <Label className="text-sm font-medium">Konfirmasi Password <span className="text-destructive">*</span></Label>
              <div className="relative mt-1.5">
                <Input type={showConfirmPassword ? "text" : "password"} placeholder="Ulangi password baru"
                  value={passForm.confirmPassword} onChange={(e) => setPassForm({ ...passForm, confirmPassword: e.target.value })} className="pr-10" />
                <button type="button" className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" onClick={() => setShowConfirmPassword(!showConfirmPassword)}>
                  {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setPassDialogOpen(false)} disabled={saving}>Batal</Button>
            <Button onClick={handleResetPassword} disabled={saving} className="bg-amber-600 hover:bg-amber-700 gap-2">
              {saving ? <span className="animate-spin h-4 w-4 border-2 border-white/30 border-t-white rounded-full" /> : <KeyRound size={15} />}
              Reset Password
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirm Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Hapus Admin?</DialogTitle>
          </DialogHeader>
          <p className="text-sm text-muted-foreground py-2">
            Admin <strong>"{targetAdmin?.name}"</strong> akan dihapus secara permanen.
          </p>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Batal</Button>
            <Button variant="destructive" onClick={handleDelete}>Hapus</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default ManajemenAdmin;
