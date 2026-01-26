import { useState, useEffect } from "react";
import { ArrowLeft, Lock, Eye, EyeOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useNavigate, useSearchParams } from "react-router-dom";
import { toast } from "sonner";
import api from "@/lib/api";

const ResetPassword = () => {
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showPasswordConfirmation, setShowPasswordConfirmation] = useState(false);
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const token = searchParams.get("token");
  const email = searchParams.get("email");

  useEffect(() => {
    if (!token || !email) {
      toast.error("Link reset password tidak valid");
      navigate("/forgot-password");
    }
  }, [token, email, navigate]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!password) {
      toast.error("Mohon masukkan password baru");
      return;
    }

    if (password.length < 6) {
      toast.error("Password minimal 6 karakter");
      return;
    }

    if (password !== passwordConfirmation) {
      toast.error("Password dan konfirmasi password tidak sama");
      return;
    }

    if (!token || !email) {
      toast.error("Token atau email tidak valid");
      return;
    }

    setIsLoading(true);
    
    try {
      const response = await api.post("/reset-password", {
        token,
        email,
        password,
        password_confirmation: passwordConfirmation,
      });
      toast.success("Password berhasil direset. Silakan login dengan password baru Anda.");
      navigate("/login-finance");
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || "Terjadi kesalahan saat mereset password";
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
    }
  };

  if (!token || !email) {
    return null;
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/30 p-4">
      <div className="w-full max-w-md">
        {/* Card Container */}
        <div className="bg-background rounded-lg shadow-lg overflow-hidden">
          {/* Top Border Accent */}
          <div className="h-2 bg-primary" />
          
          {/* Card Content */}
          <div className="p-8">
            {/* Header with Back Button and Lock Icon */}
            <div className="flex items-start justify-between mb-6">
              {/* Back Button */}
              <button
                onClick={() => navigate("/forgot-password")}
                className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center text-primary-foreground hover:bg-primary/90 transition-colors"
              >
                <ArrowLeft className="h-5 w-5" />
              </button>
              
              {/* Lock Icon */}
              <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center">
                <Lock className="h-6 w-6 text-primary" />
              </div>
            </div>

            {/* Title */}
            <h1 className="text-2xl font-bold text-foreground mb-2">
              Reset Password
            </h1>

            {/* Description */}
            <p className="text-muted-foreground text-sm mb-8">
              Masukkan password baru Anda. Pastikan password minimal 6 karakter.
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Password Field */}
              <div className="space-y-2">
                <Label htmlFor="password" className="text-sm font-medium text-foreground">
                  Password Baru
                </Label>
                <div className="relative">
                  <Input
                    id="password"
                    type={showPassword ? "text" : "password"}
                    placeholder="Masukkan password baru"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="h-12 border-border bg-background focus:ring-primary focus:border-primary pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                  </button>
                </div>
              </div>

              {/* Password Confirmation Field */}
              <div className="space-y-2">
                <Label htmlFor="passwordConfirmation" className="text-sm font-medium text-foreground">
                  Konfirmasi Password
                </Label>
                <div className="relative">
                  <Input
                    id="passwordConfirmation"
                    type={showPasswordConfirmation ? "text" : "password"}
                    placeholder="Konfirmasi password baru"
                    value={passwordConfirmation}
                    onChange={(e) => setPasswordConfirmation(e.target.value)}
                    className="h-12 border-border bg-background focus:ring-primary focus:border-primary pr-10"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPasswordConfirmation(!showPasswordConfirmation)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    {showPasswordConfirmation ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                  </button>
                </div>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={isLoading}
                className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium transition-all duration-200"
              >
                {isLoading ? "Mereset..." : "Reset Password"}
              </Button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ResetPassword;
