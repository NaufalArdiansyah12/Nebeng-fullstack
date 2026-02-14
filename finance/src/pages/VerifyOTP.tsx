import { useState, useEffect, useRef } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ArrowLeft, Shield } from "lucide-react";
import api from "@/lib/api";
import { toast } from "sonner";

const VerifyOTP = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email;
  const debugOtp = location.state?.otp;

  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const [loading, setLoading] = useState(false);
  const [resendLoading, setResendLoading] = useState(false);
  const [countdown, setCountdown] = useState(60);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    if (!email) {
      toast.error("Email tidak ditemukan");
      navigate("/forgot-password");
      return;
    }

    // Show OTP in debug mode
    if (debugOtp) {
      toast.info(`Debug Mode - OTP: ${debugOtp}`, { duration: 10000 });
    }
  }, [email, debugOtp, navigate]);

  useEffect(() => {
    if (countdown > 0) {
      const timer = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [countdown]);

  const handleChange = (index: number, value: string) => {
    if (value.length > 1) {
      value = value.slice(0, 1);
    }

    if (!/^\d*$/.test(value)) {
      return;
    }

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    // Auto focus next input
    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").slice(0, 6);
    
    if (!/^\d+$/.test(pastedData)) {
      toast.error("Hanya angka yang diperbolehkan");
      return;
    }

    const newOtp = pastedData.split("");
    while (newOtp.length < 6) {
      newOtp.push("");
    }
    setOtp(newOtp.slice(0, 6));
    
    inputRefs.current[5]?.focus();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const otpString = otp.join("");
    
    if (otpString.length !== 6) {
      toast.error("Masukkan 6 digit OTP");
      return;
    }

    setLoading(true);

    try {
      await api.post("/users/verify-otp", {
        email,
        otp: otpString,
      });

      toast.success("OTP berhasil diverifikasi");
      navigate("/reset-password", { 
        state: { 
          email,
          otp: otpString 
        } 
      });
    } catch (error: any) {
      console.error("Verify OTP error:", error);
      toast.error(error.response?.data?.message || "OTP tidak valid");
    } finally {
      setLoading(false);
    }
  };

  const handleResendOtp = async () => {
    if (countdown > 0) return;

    setResendLoading(true);

    try {
      const res = await api.post("/users/forgot-password", { email });
      toast.success("OTP baru telah dikirim");
      setCountdown(60);
      setOtp(["", "", "", "", "", ""]);
      inputRefs.current[0]?.focus();

      // Show new OTP in debug mode
    //   if (res.data.otp) {
    //     toast.info(`Debug Mode - OTP: ${res.data.otp}`, { duration: 10000 });
    //   }
    } catch (error: any) {
      toast.error(error.response?.data?.message || "Gagal mengirim ulang OTP");
    } finally {
      setResendLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/30 p-4">
      <div className="w-full max-w-md">
        {/* Card Container */}
        <div className="bg-background rounded-lg shadow-lg overflow-hidden">
          {/* Top Border Accent */}
          <div className="h-2 bg-primary" />
          
          {/* Card Content */}
          <div className="p-8">
            {/* Header with Back Button and Shield Icon */}
            <div className="flex items-start justify-between mb-6">
              {/* Back Button */}
              <button
                onClick={() => navigate("/forgot-password")}
                className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center text-primary-foreground hover:bg-primary/90 transition-colors"
              >
                <ArrowLeft className="h-5 w-5" />
              </button>
              
              {/* Shield Icon */}
              <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center">
                <Shield className="h-6 w-6 text-primary" />
              </div>
            </div>

            {/* Title */}
            <h1 className="text-2xl font-bold text-foreground mb-2">
              Verifikasi OTP
            </h1>

            {/* Description */}
            <p className="text-muted-foreground text-sm mb-8">
              Masukkan kode 6 digit yang dikirim ke{" "}
              <span className="font-medium text-foreground">{email}</span>
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* OTP Input */}
              <div className="space-y-2">
                <Label className="text-sm font-medium text-foreground">
                  Kode OTP
                </Label>
                <div className="flex gap-2 justify-between">
                  {otp.map((digit, index) => (
                    <Input
                      key={index}
                      ref={(el) => (inputRefs.current[index] = el)}
                      type="text"
                      inputMode="numeric"
                      maxLength={1}
                      value={digit}
                      onChange={(e) => handleChange(index, e.target.value)}
                      onKeyDown={(e) => handleKeyDown(index, e)}
                      onPaste={handlePaste}
                      className="w-full h-14 text-center text-xl font-semibold border-border bg-background focus:ring-primary focus:border-primary"
                      disabled={loading}
                    />
                  ))}
                </div>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={loading || otp.join("").length !== 6}
                className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium transition-all duration-200"
              >
                {loading ? "Memverifikasi..." : "Verifikasi OTP"}
              </Button>

              {/* Resend OTP */}
              <div className="text-center">
                {countdown > 0 ? (
                  <p className="text-sm text-muted-foreground">
                    Kirim ulang OTP dalam{" "}
                    <span className="font-semibold text-foreground">{countdown}s</span>
                  </p>
                ) : (
                  <button
                    type="button"
                    onClick={handleResendOtp}
                    disabled={resendLoading}
                    className="text-sm text-primary hover:underline font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {resendLoading ? "Mengirim..." : "Kirim Ulang OTP"}
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default VerifyOTP;
