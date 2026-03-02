import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Copy, Calendar, Check, Pencil, Trash2, ZoomIn, Upload, ShieldCheck, ShieldX, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { posmitraApi, posmitraUsersApi, locationsApi } from "@/services/api";

// ── Reusable field components ────────────────────────────────────────────────

const ReadField = ({ label, value }: { label: string; value?: string }) => (
  <div className="flex flex-col gap-1.5">
    <span className="text-xs font-medium text-slate-400 uppercase tracking-wider">{label}</span>
    <span className="text-sm text-slate-800 font-medium">{value || "—"}</span>
  </div>
);

const EditField = ({
  label,
  value,
  onChange,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
}) => (
  <div className="flex flex-col gap-1.5">
    <Label className="text-xs font-medium text-slate-400 uppercase tracking-wider">{label}</Label>
    <Input
      type={type}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="h-9 text-sm bg-slate-50 border-slate-200 focus:bg-white transition-colors"
    />
  </div>
);

const SectionCard = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
    <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60">
      <h3 className="text-sm font-semibold text-slate-700 tracking-wide">{title}</h3>
    </div>
    <div className="p-6">{children}</div>
  </div>
);

// ── Status badge ─────────────────────────────────────────────────────────────

const StatusBadge = ({ status }: { status: string }) => {
  const map: Record<string, { label: string; cls: string; Icon: any }> = {
    approved: { label: "Disetujui", cls: "bg-emerald-50 text-emerald-700 border-emerald-200", Icon: ShieldCheck },
    rejected: { label: "Ditolak", cls: "bg-red-50 text-red-700 border-red-200", Icon: ShieldX },
    pending: { label: "Menunggu Verifikasi", cls: "bg-amber-50 text-amber-700 border-amber-200", Icon: Clock },
  };
  const cfg = map[status] || map.pending;
  return (
    <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold border ${cfg.cls}`}>
      <cfg.Icon size={12} />
      {cfg.label}
    </span>
  );
};

// ── Main component ───────────────────────────────────────────────────────────

const DetailPosMitra = () => {
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();

  const [currentLocation, setCurrentLocation] = useState<any>(null);
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [formData, setFormData] = useState({
    nama_lengkap: "",
    terminal_city: "",
    alamat: "",
    terminal_latitude: "",
    terminal_longitude: "",
    email: "",
    phone: "",
    jenis_kelamin: "",
    tanggal_lahir: "",
    terminal_name: "",
    terminal_address: "",
    ktpName: "",
    nik: "",
    ktpGender: "",
    ktpBirthDate: "",
    referralCode: "",
    role: "",
    status: "",
  });
  const [ktpImage, setKtpImage] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [ktpZoom, setKtpZoom] = useState(false);

  useEffect(() => {
    const loadData = async () => {
      if (!id) return;
      setIsLoading(true);
      try {
        const response = await posmitraUsersApi.getById(id);
        const { user, verifikasi } = response.data;
        const posmitraData = Array.isArray(verifikasi) && verifikasi.length > 0 ? verifikasi[0] : null;

        let terminalData = null;
        if (user.location_id) {
          try {
            const locationResponse = await locationsApi.getById(user.location_id);
            terminalData = locationResponse.data;
          } catch (e) {}
        }

        const builtLocation = {
          ...(posmitraData || {}),
          user_id: user.id || (posmitraData && posmitraData.user_id) || null,
          terminal_city: terminalData?.city || "",
          terminal_name: terminalData?.name || "",
          terminal_address: terminalData?.address || "",
          terminal_latitude: terminalData?.latitude || null,
          terminal_longitude: terminalData?.longitude || null,
        };

        setCurrentLocation(builtLocation);
        setFormData({
          nama_lengkap: user.name || (posmitraData && posmitraData.nama_lengkap) || "",
          terminal_city: terminalData?.city || "",
          alamat: (posmitraData && posmitraData.alamat) || "",
          terminal_latitude: terminalData?.latitude?.toString() || "",
          terminal_longitude: terminalData?.longitude?.toString() || "",
          email: user.email || "",
          phone: user.phone || "",
          jenis_kelamin: (posmitraData && posmitraData.jenis_kelamin) || "",
          tanggal_lahir: (posmitraData && posmitraData.tanggal_lahir) || "",
          terminal_name: terminalData?.name || "",
          terminal_address: terminalData?.address || "",
          ktpName: (posmitraData && posmitraData.nama_lengkap) || "",
          nik: (posmitraData && posmitraData.nik) || "",
          ktpGender: (posmitraData && posmitraData.jenis_kelamin) || "",
          ktpBirthDate: (posmitraData && posmitraData.tanggal_lahir) ? posmitraData.tanggal_lahir.split("T")[0] : "",
          referralCode: "",
          role: "Nebeng Motor",
          status: (posmitraData && posmitraData.status) || "pending",
        });

        if (posmitraData?.photo_ktp) setKtpImage(posmitraData.photo_ktp);
      } catch (e) {
        console.error(e);
      } finally {
        setIsLoading(false);
      }
    };
    loadData();
  }, [id]);

  const set = (field: string, value: string) => {
    const val = field === "ktpBirthDate" && value ? value.split("T")[0] : value;
    setFormData((prev) => ({ ...prev, [field]: val }));
  };

  const handleKTPImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => setKtpImage(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(formData.referralCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleSave = async () => {
    if (!currentLocation) return;
    try {
      const formattedBirthDate = formData.ktpBirthDate ? formData.ktpBirthDate.split("T")[0] : null;
      await posmitraApi.update(currentLocation.id, {
        nama_lengkap: formData.ktpName,
        nik: formData.nik,
        tanggal_lahir: formattedBirthDate,
        jenis_kelamin: formData.ktpGender,
        alamat: formData.alamat,
        photo_ktp: ktpImage,
        status: formData.status,
      } as any);
      setIsEditing(false);
      window.location.reload();
    } catch (e) {
      alert("Gagal memperbarui data");
    }
  };

  const handleDelete = async () => {
    if (!currentLocation) return;
    if (!window.confirm("Apakah Anda yakin ingin menghapus posmitra ini?")) return;
    try {
      await posmitraApi.delete(currentLocation.id);
      navigate("/dashboard/pos-mitra");
    } catch (e) {
      alert("Gagal menghapus posmitra");
    }
  };

  const handleVerification = async (status: "approved" | "rejected") => {
    if (!currentLocation) return;
    try {
      await posmitraApi.approve(currentLocation.id, {
        status,
        reviewer_id: 1,
        reviewed_at: new Date().toISOString(),
      } as any);
      setCurrentLocation({ ...currentLocation, status, reviewed_at: new Date().toISOString() });
      setFormData((prev) => ({ ...prev, status }));
    } catch (e) {
      alert("Gagal memperbarui verifikasi");
    }
  };

  const handleCancelEdit = () => {
    setIsEditing(false);
    if (currentLocation) {
      setFormData({
        nama_lengkap: currentLocation.nama_lengkap || "",
        terminal_city: currentLocation.terminal_city || "",
        alamat: currentLocation.alamat || "",
        terminal_latitude: currentLocation.terminal_latitude?.toString() || "",
        terminal_longitude: currentLocation.terminal_longitude?.toString() || "",
        email: "",
        phone: "",
        jenis_kelamin: currentLocation.jenis_kelamin || "",
        tanggal_lahir: currentLocation.tanggal_lahir || "",
        terminal_name: currentLocation.terminal_name || "",
        terminal_address: currentLocation.terminal_address || "",
        ktpName: currentLocation.nama_lengkap || "",
        nik: currentLocation.nik || "",
        ktpGender: currentLocation.jenis_kelamin || "",
        ktpBirthDate: currentLocation.tanggal_lahir ? currentLocation.tanggal_lahir.split("T")[0] : "",
        referralCode: "",
        role: "Nebeng Motor",
        status: currentLocation.status || "pending",
      });
      if (currentLocation.photo_ktp) setKtpImage(currentLocation.photo_ktp);
    }
  };

  const formatDate = (d: string) => {
    if (!d) return "";
    return new Date(d).toLocaleDateString("id-ID", { day: "2-digit", month: "long", year: "numeric" });
  };

  // ── Loading / not found ───────────────────────────────────────────────────

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh] gap-3 flex-col">
        <div className="w-8 h-8 border-2 border-slate-200 border-t-slate-700 rounded-full animate-spin" />
        <p className="text-sm text-slate-400">Memuat data...</p>
      </div>
    );
  }

  if (!currentLocation) {
    return (
      <div className="flex items-center justify-center min-h-[60vh] flex-col gap-3">
        <p className="text-slate-500">Data tidak ditemukan.</p>
        <Button variant="outline" onClick={() => navigate("/dashboard/pos-mitra")}>Kembali</Button>
      </div>
    );
  }

  const initials = formData.nama_lengkap?.charAt(0)?.toUpperCase() || "?";

  return (
    <div className="flex flex-col gap-5 pb-10">

      {/* ── Top bar ── */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => navigate("/dashboard/pos-mitra")}
          className="flex items-center gap-2 text-sm text-slate-500 hover:text-slate-800 transition-colors"
        >
          <ArrowLeft size={18} />
          <span>Kembali</span>
        </button>

        <div className="flex items-center gap-2">
          {!isEditing ? (
            <>
              <button
                onClick={handleDelete}
                className="inline-flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-medium text-red-600 hover:bg-red-50 border border-red-200 transition-colors"
              >
                <Trash2 size={14} />
                Hapus
              </button>
              <button
                onClick={() => setIsEditing(true)}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-medium text-white bg-slate-900 hover:bg-slate-700 transition-colors"
              >
                <Pencil size={14} />
                Edit
              </button>
            </>
          ) : (
            <>
              <button
                onClick={handleCancelEdit}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-medium text-slate-600 border border-slate-200 hover:bg-slate-50 transition-colors"
              >
                Batal
              </button>
              <button
                onClick={handleSave}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-medium text-white bg-blue-600 hover:bg-blue-700 transition-colors"
              >
                <Check size={14} />
                Simpan Perubahan
              </button>
            </>
          )}
        </div>
      </div>

      {/* ── Profile hero card ── */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="w-14 h-14 rounded-full bg-gradient-to-br from-slate-700 to-slate-900 flex items-center justify-center text-white text-xl font-bold flex-shrink-0 shadow-md">
              {initials}
            </div>
            <div>
              <div className="flex items-center gap-2 mb-1">
                <h1 className="text-lg font-bold text-slate-900">{formData.nama_lengkap || "—"}</h1>
                <StatusBadge status={formData.status} />
              </div>
              <div className="flex items-center gap-3 text-sm text-slate-500">
                <span>{formData.email || "—"}</span>
                {formData.phone && (
                  <>
                    <span className="text-slate-300">•</span>
                    <span>{formData.phone}</span>
                  </>
                )}
                {formData.role && (
                  <>
                    <span className="text-slate-300">•</span>
                    <span className="bg-slate-100 text-slate-600 px-2 py-0.5 rounded-md text-xs font-medium">{formData.role}</span>
                  </>
                )}
              </div>
            </div>
          </div>

          {formData.referralCode && (
            <div className="text-right">
              <p className="text-xs text-slate-400 uppercase tracking-wider mb-1">Kode Referral</p>
              <div className="flex items-center gap-2 justify-end">
                <span className="text-slate-800 font-mono font-bold text-lg tracking-widest">{formData.referralCode}</span>
                <button
                  onClick={handleCopy}
                  className={`p-1.5 rounded-lg transition-colors ${copied ? "bg-emerald-100 text-emerald-600" : "bg-slate-100 text-slate-500 hover:bg-slate-200"}`}
                >
                  {copied ? <Check size={14} /> : <Copy size={14} />}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── Informasi Pribadi ── */}
      <SectionCard title="Informasi Pribadi">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-x-8 gap-y-6">
          {isEditing ? (
            <>
              <EditField label="Nama Lengkap" value={formData.nama_lengkap} onChange={(v) => set("nama_lengkap", v)} />
              <EditField label="Email" value={formData.email} onChange={(v) => set("email", v)} />
              <div className="flex flex-col gap-1.5">
                <Label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Jenis Kelamin</Label>
                <Select value={formData.jenis_kelamin} onValueChange={(v) => set("jenis_kelamin", v)}>
                  <SelectTrigger className="h-9 text-sm bg-slate-50 border-slate-200">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <EditField label="Terminal" value={formData.terminal_name} onChange={(v) => set("terminal_name", v)} />
              <EditField label="No. Telepon" value={formData.phone} onChange={(v) => set("phone", v)} />
              <div className="flex flex-col gap-1.5">
                <Label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Tanggal Lahir</Label>
                <Input
                  type="date"
                  value={formData.tanggal_lahir}
                  onChange={(e) => set("tanggal_lahir", e.target.value)}
                  className="h-9 text-sm bg-slate-50 border-slate-200"
                />
              </div>
            </>
          ) : (
            <>
              <ReadField label="Nama Lengkap" value={formData.nama_lengkap} />
              <ReadField label="Email" value={formData.email} />
              <ReadField label="Jenis Kelamin" value={formData.jenis_kelamin} />
              <ReadField label="Terminal" value={formData.terminal_name} />
              <ReadField label="No. Telepon" value={formData.phone} />
              <ReadField label="Tanggal Lahir" value={formData.tanggal_lahir ? formatDate(formData.tanggal_lahir) : undefined} />
            </>
          )}
        </div>

        <div className="mt-6 pt-6 border-t border-slate-100">
          <div className="flex flex-col gap-1.5">
            <span className="text-xs font-medium text-slate-400 uppercase tracking-wider">Alamat Terminal</span>
            {isEditing ? (
              <Textarea
                value={formData.terminal_address}
                onChange={(e) => set("terminal_address", e.target.value)}
                className="text-sm bg-slate-50 border-slate-200 min-h-20 resize-none"
              />
            ) : (
              <p className="text-sm text-slate-800 leading-relaxed">{formData.terminal_address || "—"}</p>
            )}
          </div>
        </div>
      </SectionCard>

      {/* ── Informasi KTP ── */}
      <SectionCard title="Informasi KTP">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">

          {/* Form fields */}
          <div className="space-y-5">
            {isEditing ? (
              <>
                <EditField label="Nama Lengkap (KTP)" value={formData.ktpName} onChange={(v) => set("ktpName", v)} />
                <EditField label="NIK" value={formData.nik} onChange={(v) => set("nik", v)} />
                <div className="flex flex-col gap-1.5">
                  <Label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Jenis Kelamin</Label>
                  <Select value={formData.ktpGender} onValueChange={(v) => set("ktpGender", v)}>
                    <SelectTrigger className="h-9 text-sm bg-slate-50 border-slate-200">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                      <SelectItem value="Perempuan">Perempuan</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="flex flex-col gap-1.5">
                  <Label className="text-xs font-medium text-slate-400 uppercase tracking-wider">Tanggal Lahir</Label>
                  <Input
                    type="date"
                    value={formData.ktpBirthDate}
                    onChange={(e) => set("ktpBirthDate", e.target.value)}
                    className="h-9 text-sm bg-slate-50 border-slate-200"
                  />
                </div>
              </>
            ) : (
              <>
                <ReadField label="Nama Lengkap (KTP)" value={formData.ktpName} />
                <ReadField label="NIK" value={formData.nik} />
                <ReadField label="Jenis Kelamin" value={formData.ktpGender} />
                <ReadField label="Tanggal Lahir" value={formData.ktpBirthDate ? formatDate(formData.ktpBirthDate) : undefined} />
              </>
            )}
          </div>

          {/* KTP image */}
          <div className="flex flex-col items-center justify-center gap-3">
            {ktpImage ? (
              <div className="relative w-full max-w-xs group">
                <img
                  src={ktpImage}
                  alt="Foto KTP"
                  className="w-full rounded-xl object-cover shadow-md border border-slate-200 aspect-[1.6/1]"
                />
                {!isEditing && (
                  <button
                    onClick={() => window.open(ktpImage, "_blank")}
                    className="absolute inset-0 rounded-xl bg-black/0 group-hover:bg-black/30 transition-all flex items-center justify-center"
                  >
                    <ZoomIn size={22} className="text-white opacity-0 group-hover:opacity-100 transition-opacity" />
                  </button>
                )}
              </div>
            ) : (
              <div className="w-full max-w-xs aspect-[1.6/1] rounded-xl bg-gradient-to-br from-blue-600 to-blue-800 flex flex-col justify-between p-4 shadow-md">
                <div>
                  <p className="text-white text-[10px] font-bold tracking-widest">REPUBLIK INDONESIA</p>
                  <p className="text-white/70 text-[9px] mt-0.5">{formData.terminal_city?.toUpperCase() || "—"}</p>
                </div>
                <div className="space-y-0.5">
                  <p className="text-white/60 text-[9px]">NIK</p>
                  <p className="text-white font-mono text-xs font-bold tracking-widest">{formData.nik || "— — — —"}</p>
                  <p className="text-white text-[10px] mt-1 font-medium">{formData.ktpName || "—"}</p>
                </div>
              </div>
            )}

            {isEditing && (
              <label htmlFor="ktp-upload" className="cursor-pointer">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-medium border border-slate-200 text-slate-600 hover:bg-slate-50 transition-colors">
                  <Upload size={14} />
                  {ktpImage ? "Ganti Foto KTP" : "Upload Foto KTP"}
                </div>
                <input id="ktp-upload" type="file" accept="image/*" onChange={handleKTPImageUpload} className="hidden" />
              </label>
            )}

            {!ktpImage && !isEditing && (
              <p className="text-xs text-slate-400 italic">Belum ada foto KTP</p>
            )}
          </div>
        </div>
      </SectionCard>

      {/* ── Verifikasi ── */}
      <SectionCard title="Verifikasi">
        <div className="flex items-center justify-between">
          <div className="flex flex-col gap-2">
            <span className="text-xs font-medium text-slate-400 uppercase tracking-wider">Status</span>
            {isEditing ? (
              <Select value={formData.status} onValueChange={(v) => set("status", v)}>
                <SelectTrigger className="h-9 text-sm bg-slate-50 border-slate-200 w-56">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Menunggu Verifikasi</SelectItem>
                  <SelectItem value="approved">Disetujui</SelectItem>
                  <SelectItem value="rejected">Ditolak</SelectItem>
                </SelectContent>
              </Select>
            ) : (
              <div className="flex items-center gap-3">
                <StatusBadge status={formData.status} />
                {currentLocation.reviewed_at && (
                  <span className="text-xs text-slate-400">• {formatDate(currentLocation.reviewed_at)}</span>
                )}
              </div>
            )}
          </div>

          {!isEditing && formData.status === "pending" && (
            <div className="flex gap-2">
              <button
                onClick={() => handleVerification("rejected")}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-semibold text-red-700 border border-red-200 bg-red-50 hover:bg-red-100 transition-colors"
              >
                <ShieldX size={14} />
                Tolak
              </button>
              <button
                onClick={() => handleVerification("approved")}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-semibold text-emerald-700 border border-emerald-200 bg-emerald-50 hover:bg-emerald-100 transition-colors"
              >
                <ShieldCheck size={14} />
                Setujui
              </button>
            </div>
          )}
        </div>
      </SectionCard>

    </div>
  );
};

export default DetailPosMitra;