import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ArrowLeft, User, Mail, Phone, Lock, MapPin, Loader2, ChevronDown } from "lucide-react";
import { posmitraUsersApi, locationsApi } from "@/services/api";

const FieldWrapper = ({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) => (
  <div className="flex flex-col gap-1.5">
    <Label className="text-xs font-medium text-slate-500 uppercase tracking-wider">{label}</Label>
    {children}
    {hint && <p className="text-xs text-slate-400">{hint}</p>}
  </div>
);

const IconInput = ({
  icon: Icon,
  ...props
}: { icon: React.ElementType } & React.InputHTMLAttributes<HTMLInputElement>) => (
  <div className="relative">
    <Icon size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
    <Input
      {...props}
      className="pl-9 h-10 text-sm bg-slate-50 border-slate-200 focus:bg-white transition-colors"
    />
  </div>
);

const CreatePosMitra = () => {
  const navigate = useNavigate();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [locationId, setLocationId] = useState<string | null>(null);
  const [locations, setLocations] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [locLoading, setLocLoading] = useState(true);

  useEffect(() => {
    const loadLocations = async () => {
      try {
        const res = await locationsApi.getAll();
        setLocations(res.data || []);
      } catch (err) {
        console.error("Failed to load locations:", err);
      } finally {
        setLocLoading(false);
      }
    };
    loadLocations();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !email || !phone || !locationId) {
      alert("Semua field harus diisi");
      return;
    }
    if (password && password.length < 6) {
      alert("Password minimal 6 karakter");
      return;
    }
    setLoading(true);
    try {
      await posmitraUsersApi.create({
        name,
        email,
        phone,
        location_id: Number(locationId),
        password: password || undefined,
      });
      navigate("/dashboard/pos-mitra");
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || "Gagal membuat akun pos mitra";
      alert(msg);
    } finally {
      setLoading(false);
    }
  };

  const isComplete = name && email && phone && locationId;

  return (
    <div className="p-6 max-w-4xl mx-auto">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center gap-3 mb-2">
          <Button 
            variant="ghost" 
            size="icon"
            onClick={() => navigate('/dashboard/pos-mitra')}
            className="h-8 w-8"
          >
            ←
          </Button>
          <div>
            <h1 className="text-2xl font-bold">Buat Akun Pos Mitra</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Isi informasi di bawah untuk mendaftarkan akun pos mitra baru
            </p>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex flex-col gap-5 max-w-xl">

        {/* Card: Informasi Akun */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60">
            <h3 className="text-sm font-semibold text-slate-700 tracking-wide">Informasi Akun</h3>
          </div>
          <div className="p-6 flex flex-col gap-5">
            <FieldWrapper label="Nama Lengkap">
              <IconInput
                icon={User}
                placeholder="Masukkan nama lengkap"
                value={name}
                onChange={(e) => setName(e.target.value)}
              />
            </FieldWrapper>

            <FieldWrapper label="Email">
              <IconInput
                icon={Mail}
                type="email"
                placeholder="contoh@email.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </FieldWrapper>

            <FieldWrapper label="Telepon">
              <IconInput
                icon={Phone}
                placeholder="+62 812 xxxx xxxx"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
              />
            </FieldWrapper>

            <FieldWrapper
              label="Password"
              hint="Minimal 6 karakter. Kosongkan jika ingin dibuat otomatis."
            >
              <IconInput
                icon={Lock}
                type="password"
                placeholder="Buat password..."
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </FieldWrapper>
          </div>
        </div>

        {/* Card: Lokasi */}
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60">
            <h3 className="text-sm font-semibold text-slate-700 tracking-wide">Terminal / Lokasi</h3>
          </div>
          <div className="p-6">
            <FieldWrapper label="Pilih Terminal">
              <div className="relative">
                <MapPin size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none z-10" />
                <ChevronDown size={15} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                <select
                  className="w-full h-10 pl-9 pr-8 text-sm bg-slate-50 border border-slate-200 rounded-md appearance-none focus:outline-none focus:ring-2 focus:ring-slate-400 focus:bg-white transition-colors text-slate-700 disabled:opacity-50"
                  value={locationId ?? ""}
                  onChange={(e) => setLocationId(e.target.value || null)}
                  disabled={locLoading}
                >
                  <option value="">
                    {locLoading ? "Memuat lokasi..." : "Pilih terminal atau lokasi"}
                  </option>
                  {locations.map((loc) => (
                    <option key={loc.id} value={loc.id}>
                      {loc.name} — {loc.city}
                    </option>
                  ))}
                </select>
              </div>
            </FieldWrapper>
          </div>
        </div>

        {/* Actions */}
        <div className="flex items-center gap-3 pt-2 border-t">
          <Button
            type="submit"
            disabled={loading || !isComplete}
            className="flex-1 h-11"
          >
            {loading ? (
              <>
                <Loader2 size={15} className="animate-spin mr-2" />
                Menyimpan...
              </>
            ) : (
              "Buat Akun Pos Mitra"
            )}
          </Button>
          <Button
            type="button"
            variant="outline"
            onClick={() => navigate("/dashboard/pos-mitra")}
            className="h-11"
          >
            Batal
          </Button>
        </div>

      </form>
    </div>
  );
};

export default CreatePosMitra;