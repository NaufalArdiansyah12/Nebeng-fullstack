import { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { ArrowLeft, Copy, Calendar } from "lucide-react";
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
import { Card, CardContent } from "@/components/ui/card";
import { posmitraApi, posmitraUsersApi, locationsApi } from "@/services/api";

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
  const [copiedField, setCopiedField] = useState<string | null>(null);

  // Load location data when component mounts or id changes
  useEffect(() => {
    const loadData = async () => {
      if (!id) return;

      setIsLoading(true);
      try {
        // Fetch posmitra user and verifikasi data
        const response = await posmitraUsersApi.getById(id);
        const { user, verifikasi } = response.data;

        if (verifikasi.length === 0) {
          // No verifikasi record found
          setCurrentLocation(null);
          setIsLoading(false);
          return;
        }

        // Use the first (latest) verifikasi record
        const posmitraData = verifikasi[0];

        // Fetch terminal data from locations using user's location_id
        let terminalData = null;
        if (user.location_id) {
          try {
            const locationResponse = await locationsApi.getById(user.location_id);
            terminalData = locationResponse.data;
          } catch (error) {
            console.error("Error fetching location data:", error);
          }
        }

        setCurrentLocation({
          ...posmitraData,
          terminal_city: terminalData?.city || "",
          terminal_name: terminalData?.name || "",
          terminal_address: terminalData?.address || "",
          terminal_latitude: terminalData?.latitude || null,
          terminal_longitude: terminalData?.longitude || null,
        });

        setFormData({
          nama_lengkap: user.name || posmitraData.nama_lengkap || "",
          terminal_city: terminalData?.city || "",
          alamat: posmitraData.alamat || "",
          terminal_latitude: terminalData?.latitude?.toString() || "",
          terminal_longitude: terminalData?.longitude?.toString() || "",
          email: user.email || "",
          phone: user.phone || "",
          jenis_kelamin: posmitraData.jenis_kelamin || "",
          tanggal_lahir: posmitraData.tanggal_lahir || "",
          terminal_name: terminalData?.name || "",
          terminal_address: terminalData?.address || "",
          ktpName: posmitraData.nama_lengkap || "",
          nik: posmitraData.nik || "",
          ktpGender: posmitraData.jenis_kelamin || "",
          ktpBirthDate: posmitraData.tanggal_lahir ? posmitraData.tanggal_lahir.split('T')[0] : "",
          referralCode: "",
          role: "Nebeng Motor",
          status: posmitraData.status || "pending",
        });

        // Set KTP image if available
        if (posmitraData.photo_ktp) {
          setKtpImage(posmitraData.photo_ktp);
        }
      } catch (error) {
        console.error("Error loading data:", error);
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [id]);

  const handleInputChange = (field: string, value: string) => {
    // For date fields, ensure only date part is stored
    if (field === 'ktpBirthDate' && value) {
      const dateOnly = value.split('T')[0];
      setFormData((prev) => ({ ...prev, [field]: dateOnly }));
    } else {
      setFormData((prev) => ({ ...prev, [field]: value }));
    }
  };

  const handleKTPImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setKtpImage(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleCopyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedField("referral");
    setTimeout(() => setCopiedField(null), 2000);
  };

  const handleSave = async () => {
    if (!currentLocation) return;

    try {
      // Ensure date is in yyyy-MM-dd format
      const formattedBirthDate = formData.ktpBirthDate
        ? formData.ktpBirthDate.split('T')[0]
        : null;

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
      alert("Data berhasil diperbarui!");
      // Refresh data
      window.location.reload();
    } catch (error) {
      console.error("Error updating posmitra:", error);
      alert("Gagal memperbarui data");
    }
  };

  const handleDelete = async () => {
    if (!currentLocation) return;

    if (window.confirm("Apakah Anda yakin ingin menghapus posmitra ini?")) {
      try {
        await posmitraApi.delete(currentLocation.id);
        navigate("/dashboard/pos-mitra");
      } catch (error) {
        console.error("Error deleting posmitra:", error);
        alert("Gagal menghapus posmitra");
      }
    }
  };

  const handleVerification = async (status: 'approved' | 'rejected') => {
    if (!currentLocation) return;

    try {
      await posmitraApi.approve(currentLocation.id, {
        status,
        reviewer_id: 1, // Assuming admin id
        reviewed_at: new Date().toISOString(),
      } as any);
      setCurrentLocation({ ...currentLocation, status, reviewed_at: new Date().toISOString() });
      setFormData((prev) => ({ ...prev, status }));
      alert(`Pos mitra ${status === 'approved' ? 'disetujui' : 'ditolak'}!`);
    } catch (error) {
      console.error("Error updating verification:", error);
      alert("Gagal memperbarui verifikasi");
    }
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return "";
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric'
    });
  };

  if (isLoading) {
    return (
      <div className="flex flex-col gap-6 p-6 bg-gray-50 min-h-screen">
        <div className="text-center">Loading...</div>
      </div>
    );
  }

  if (!currentLocation) {
    return (
      <div className="flex flex-col gap-6 p-6 bg-gray-50 min-h-screen">
        <div className="text-center">Lokasi tidak ditemukan</div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6 p-6 bg-gray-50 min-h-screen">

      {/* HEADER */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate("/dashboard/pos-mitra")}
            className="flex items-center justify-center text-gray-600 hover:text-gray-900 transition-colors"
          >
            <ArrowLeft size={24} />
          </button>
          <h1 className="text-2xl font-bold text-gray-800">Detail Pos Mitra</h1>
        </div>
      </div>

      {/* PROFILE CARD */}
      <Card className="border-none shadow-sm bg-white">
        <CardContent className="pt-6 pb-6">
          <div className="flex items-center justify-between">
            {/* Left: Avatar & Info */}
            <div className="flex items-center gap-4">
              <div className="relative">
                {/* Avatar with illustration style */}
                <div className="w-16 h-16 rounded-full bg-yellow-100 flex items-center justify-center overflow-hidden">
                  <svg viewBox="0 0 100 100" className="w-full h-full">
                    {/* Simple avatar illustration */}
                    <circle cx="50" cy="35" r="18" fill="#FFB380" />
                    <path d="M 25 75 Q 25 55 50 55 Q 75 55 75 75 L 75 100 L 25 100 Z" fill="#4A90E2" />
                  </svg>
                </div>
                {/* Online status */}
                <div className="absolute bottom-0 right-0 w-4 h-4 bg-gray-800 rounded-full border-2 border-white flex items-center justify-center">
                  <div className="w-2 h-2 bg-white rounded-full"></div>
                </div>
              </div>

              <div>
                <h2 className="text-lg font-bold text-gray-900">
                  {currentLocation.nama_lengkap}
                </h2>
                <p className="text-gray-500 text-sm">
                  {formData.role}
                </p>
              </div>
            </div>

            {/* Right: Referral Code */}
            {formData.referralCode && (
              <div className="text-right">
                <p className="text-xs text-gray-500 font-medium mb-1">
                  KODE REFERRAL
                </p>
                <div className="flex items-center gap-2">
                  <span className="text-blue-600 font-semibold text-lg">
                    {formData.referralCode}
                  </span>
                  <button
                    onClick={() => handleCopyToClipboard(formData.referralCode)}
                    className="text-gray-400 hover:text-gray-600 transition-colors"
                  >
                    <Copy size={16} />
                  </button>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>

      {/* INFORMASI PRIBADI */}
      <Card className="border-none shadow-sm bg-white">
        <CardContent className="pt-6 pb-6">
          <h3 className="text-base font-bold text-gray-900 mb-6">
            Informasi Pribadi
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Nama Lengkap */}
            <div>
              <Label className="text-sm font-normal text-gray-600 mb-2 block">
                Nama Lengkap
              </Label>
              {isEditing ? (
                <Input
                  value={formData.nama_lengkap}
                  onChange={(e) => handleInputChange("nama_lengkap", e.target.value)}
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              ) : (
                <Input
                  value={formData.nama_lengkap}
                  readOnly
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              )}
            </div>

            {/* Email */}
            <div>
              <Label className="text-sm font-normal text-gray-600 mb-2 block">
                Email
              </Label>
              {isEditing ? (
                <Input
                  value={formData.email}
                  onChange={(e) => handleInputChange("email", e.target.value)}
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              ) : (
                <Input
                  value={formData.email || "-"}
                  readOnly
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              )}
            </div>

            {/* Jenis Kelamin */}
            <div>
              <Label className="text-sm font-normal text-gray-600 mb-2 block">
                Jenis Kelamin
              </Label>
              {isEditing ? (
                <Select value={formData.jenis_kelamin} onValueChange={(value) => handleInputChange("jenis_kelamin", value)}>
                  <SelectTrigger className="bg-gray-50 border-gray-200 text-sm h-10">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                    <SelectItem value="Perempuan">Perempuan</SelectItem>
                  </SelectContent>
                </Select>
              ) : (
                <Input
                  value={formData.jenis_kelamin || "-"}
                  readOnly
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              )}
            </div>

            {/* Terminal */}
            <div>
              <Label className="text-sm font-normal text-gray-600 mb-2 block">
                Terminal
              </Label>
              {isEditing ? (
                <Input
                  value={formData.terminal_name}
                  onChange={(e) => handleInputChange("terminal_name", e.target.value)}
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              ) : (
                <Input
                  value={formData.terminal_name || "-"}
                  readOnly
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              )}
            </div>

            {/* No. Tlp */}
            <div>
              <Label className="text-sm font-normal text-gray-600 mb-2 block">
                No. Tlp
              </Label>
              {isEditing ? (
                <Input
                  value={formData.phone}
                  onChange={(e) => handleInputChange("phone", e.target.value)}
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              ) : (
                <Input
                  value={formData.phone || "-"}
                  readOnly
                  className="bg-gray-50 border-gray-200 text-sm h-10"
                />
              )}
            </div>

            {/* Tanggal Lahir */}
            <div>
              <Label className="text-sm font-normal text-gray-600 mb-2 block">
                Tanggal Lahir
              </Label>
              {isEditing ? (
                <div className="relative">
                  <Input
                    type="date"
                    value={formData.tanggal_lahir}
                    onChange={(e) => handleInputChange("tanggal_lahir", e.target.value)}
                    className="bg-gray-50 border-gray-200 text-sm h-10 pr-10"
                  />
                  <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" size={16} />
                </div>
              ) : (
                <div className="relative">
                  <Input
                    value={formData.tanggal_lahir ? formatDate(formData.tanggal_lahir) : "-"}
                    readOnly
                    className="bg-gray-50 border-gray-200 text-sm h-10 pr-10"
                  />
                  <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                </div>
              )}
            </div>
          </div>

          {/* Alamat Terminal */}
          <div className="mt-4">
            <Label className="text-sm font-normal text-gray-600 mb-2 block">
              Alamat Terminal
            </Label>
            {isEditing ? (
              <Textarea
                value={formData.terminal_address}
                onChange={(e) => handleInputChange("terminal_address", e.target.value)}
                className="bg-gray-50 border-gray-200 text-sm min-h-24 resize-none"
              />
            ) : (
              <Textarea
                value={formData.terminal_address || "-"}
                readOnly
                className="bg-gray-50 border-gray-200 text-sm min-h-24 resize-none"
              />
            )}
          </div>
        </CardContent>
      </Card>

      {/* INFORMASI KTP */}
      <Card className="border-none shadow-sm bg-white">
        <CardContent className="pt-6 pb-6">
          <h3 className="text-base font-bold text-gray-900 mb-6">
            Informasi KTP
          </h3>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Left Column: Form Fields */}
            <div className="space-y-4">
              {/* Nama Lengkap */}
              <div>
                <Label className="text-sm font-normal text-gray-600 mb-2 block">
                  Nama Lengkap
                </Label>
                {isEditing ? (
                  <Input
                    value={formData.ktpName}
                    onChange={(e) => handleInputChange("ktpName", e.target.value)}
                    className="bg-gray-50 border-gray-200 text-sm h-10"
                  />
                ) : (
                  <Input
                    value={formData.ktpName || "-"}
                    readOnly
                    className="bg-gray-50 border-gray-200 text-sm h-10"
                  />
                )}
              </div>

              {/* NIK */}
              <div>
                <Label className="text-sm font-normal text-gray-600 mb-2 block">
                  NIK
                </Label>
                {isEditing ? (
                  <Input
                    value={formData.nik}
                    onChange={(e) => handleInputChange("nik", e.target.value)}
                    className="bg-gray-50 border-gray-200 text-sm h-10"
                  />
                ) : (
                  <Input
                    value={formData.nik || "-"}
                    readOnly
                    className="bg-gray-50 border-gray-200 text-sm h-10"
                  />
                )}
              </div>

              {/* Jenis Kelamin */}
              <div>
                <Label className="text-sm font-normal text-gray-600 mb-2 block">
                  Jenis Kelamin
                </Label>
                {isEditing ? (
                  <Select value={formData.ktpGender} onValueChange={(value) => handleInputChange("ktpGender", value)}>
                    <SelectTrigger className="bg-gray-50 border-gray-200 text-sm h-10">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Laki - Laki">Laki - Laki</SelectItem>
                      <SelectItem value="Perempuan">Perempuan</SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <Input
                    value={formData.ktpGender || "-"}
                    readOnly
                    className="bg-gray-50 border-gray-200 text-sm h-10"
                  />
                )}
              </div>

              {/* Tanggal Lahir */}
              <div>
                <Label className="text-sm font-normal text-gray-600 mb-2 block">
                  Tanggal Lahir
                </Label>
                {isEditing ? (
                  <div className="relative">
                    <Input
                      type="date"
                      value={formData.ktpBirthDate}
                      onChange={(e) => handleInputChange("ktpBirthDate", e.target.value)}
                      className="bg-gray-50 border-gray-200 text-sm h-10 pr-10"
                    />
                    <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" size={16} />
                  </div>
                ) : (
                  <div className="relative">
                    <Input
                      value={formData.ktpBirthDate ? formatDate(formData.ktpBirthDate) : "-"}
                      readOnly
                      className="bg-gray-50 border-gray-200 text-sm h-10 pr-10"
                    />
                    <Calendar className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400" size={16} />
                  </div>
                )}
              </div>
            </div>

            {/* Right Column: KTP Image */}
            <div className="flex items-center justify-center">
              <div className="relative w-full max-w-xs">
                {ktpImage ? (
                  /* Real KTP Image */
                  <div className="relative rounded-lg overflow-hidden shadow-lg aspect-[1.6/1]">
                    <img 
                      src={ktpImage} 
                      alt="KTP" 
                      className="w-full h-full object-cover"
                    />
                    {/* Zoom button overlay */}
                    {!isEditing && (
                      <button 
                        onClick={() => window.open(ktpImage, '_blank')}
                        className="absolute bottom-3 right-3 w-8 h-8 bg-gray-800 bg-opacity-60 rounded-full flex items-center justify-center text-white hover:bg-opacity-80 transition-all"
                      >
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <circle cx="11" cy="11" r="8"></circle>
                          <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                          <line x1="11" y1="8" x2="11" y2="14"></line>
                          <line x1="8" y1="11" x2="14" y2="11"></line>
                        </svg>
                      </button>
                    )}
                  </div>
                ) : (
                  /* KTP Card Preview when no image */
                  <div className="bg-gradient-to-br from-blue-500 to-blue-700 rounded-lg p-4 shadow-lg aspect-[1.6/1] flex flex-col justify-between">
                    <div className="flex items-start justify-between">
                      <div className="text-white">
                        <div className="text-xs font-bold mb-1">REPUBLIK INDONESIA</div>
                        <div className="text-[10px] opacity-90">PROVINSI {formData.terminal_city?.toUpperCase() || "..."}</div>
                      </div>
                      <div className="w-12 h-12 bg-red-500 rounded flex items-center justify-center">
                        {/* Placeholder for photo */}
                        <svg viewBox="0 0 100 100" className="w-full h-full">
                          <circle cx="50" cy="35" r="15" fill="#FFB380" />
                          <path d="M 30 70 Q 30 55 50 55 Q 70 55 70 70 L 70 85 L 30 85 Z" fill="#4A90E2" />
                        </svg>
                      </div>
                    </div>
                    <div className="text-white">
                      <div className="text-[10px] mb-1">
                        <span className="opacity-70">NIK: </span>
                        <span className="font-semibold">{formData.nik || "..."}</span>
                      </div>
                      <div className="text-[10px]">
                        <span className="opacity-70">Nama: </span>
                        <span className="font-semibold">{formData.ktpName?.substring(0, 20) || "..."}</span>
                      </div>
                    </div>
                  </div>
                )}
                
                {/* Upload button when editing */}
                {isEditing && (
                  <div className="mt-3">
                    <Label htmlFor="ktp-upload" className="cursor-pointer">
                      <div className="flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm">
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                          <polyline points="17 8 12 3 7 8"></polyline>
                          <line x1="12" y1="3" x2="12" y2="15"></line>
                        </svg>
                        Upload KTP
                      </div>
                    </Label>
                    <Input
                      id="ktp-upload"
                      type="file"
                      accept="image/*"
                      onChange={handleKTPImageUpload}
                      className="hidden"
                    />
                  </div>
                )}
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* VERIFICATION SECTION */}
      <Card className="border-none shadow-sm bg-white">
        <CardContent className="pt-6 pb-6">
          <h3 className="text-base font-bold text-gray-900 mb-6">
            Verifikasi KTP dan Data
          </h3>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex-1">
                <Label className="text-sm font-normal text-gray-600 mb-2 block">
                  Status Verifikasi
                </Label>
                {isEditing ? (
                  <Select value={formData.status} onValueChange={(value) => handleInputChange("status", value)}>
                    <SelectTrigger className="bg-gray-50 border-gray-200 text-sm h-10 w-full md:w-64">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">Menunggu Verifikasi</SelectItem>
                      <SelectItem value="approved">Disetujui</SelectItem>
                      <SelectItem value="rejected">Ditolak</SelectItem>
                    </SelectContent>
                  </Select>
                ) : (
                  <div className="flex items-center gap-2">
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      formData.status === 'approved' ? 'bg-green-100 text-green-800' :
                      formData.status === 'rejected' ? 'bg-red-100 text-red-800' :
                      'bg-yellow-100 text-yellow-800'
                    }`}>
                      {formData.status === 'approved' ? 'Disetujui' :
                       formData.status === 'rejected' ? 'Ditolak' :
                       'Menunggu Verifikasi'}
                    </span>
                    {currentLocation.reviewed_at && (
                      <span className="text-xs text-gray-500">
                        pada {formatDate(currentLocation.reviewed_at)}
                      </span>
                    )}
                  </div>
                )}
              </div>

              {!isEditing && formData.status === 'pending' && (
                <div className="flex gap-3">
                  <Button
                    variant="outline"
                    onClick={() => handleVerification('rejected')}
                    className="px-6 h-10 border-red-300 text-red-700 hover:bg-red-50"
                  >
                    Tolak
                  </Button>
                  <Button
                    onClick={() => handleVerification('approved')}
                    className="px-6 h-10 bg-green-600 hover:bg-green-700 text-white font-medium"
                  >
                    Setujui
                  </Button>
                </div>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* ACTION BUTTONS */}
      {isEditing ? (
        <div className="flex items-center justify-end gap-3 mt-2">
          <Button
            variant="outline"
            onClick={() => {
              setIsEditing(false);
              // Reset form data
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
                  ktpBirthDate: currentLocation.tanggal_lahir ? currentLocation.tanggal_lahir.split('T')[0] : "",
                  referralCode: "",
                  role: "Nebeng Motor",
                  status: currentLocation.status || "pending",
                });
                if (currentLocation.photo_ktp) {
                  setKtpImage(currentLocation.photo_ktp);
                }
              }
            }}
            className="px-8 h-10 border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            Batal
          </Button>
          <Button
            onClick={handleSave}
            className="px-8 h-10 bg-blue-600 hover:bg-blue-700 text-white font-medium"
          >
            Simpan Perubahan
          </Button>
        </div>
      ) : (
        <div className="flex items-center justify-end gap-3 mt-2">
          <Button
            variant="outline"
            onClick={() => setIsEditing(true)}
            className="px-8 h-10 border-gray-300 text-gray-700 hover:bg-gray-50"
          >
            Edit
          </Button>
        </div>
      )}
    </div>
  );
};

export default DetailPosMitra;