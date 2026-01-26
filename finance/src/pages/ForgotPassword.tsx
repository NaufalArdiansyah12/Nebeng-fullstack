import { useState } from "react";
import { ArrowLeft, Lock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import api from "@/lib/api";

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!email) {
      toast.error("Mohon masukkan email Anda");
      return;
    }

    setIsLoading(true);
    
    try {
      const response = await api.post("/forgot-password", { email });
      toast.success("Link reset password telah dikirim ke email Anda");
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || "Terjadi kesalahan saat mengirim link reset password";
      toast.error(errorMessage);
    } finally {
      setIsLoading(false);
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
            {/* Header with Back Button and Lock Icon */}
            <div className="flex items-start justify-between mb-6">
              {/* Back Button */}
              <button
                onClick={() => navigate("/login")}
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
              Kesulitan Login?
            </h1>

            {/* Description */}
            <p className="text-muted-foreground text-sm mb-8">
              Masukkan email, atau nama pengguna yang terkait dengan akun Anda untuk mengubah kata sandinya.
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Email Field */}
              <div className="space-y-2">
                <Label htmlFor="email" className="text-sm font-medium text-foreground">
                  Email/Username
                </Label>
                <Input
                  id="email"
                  type="email"
                  placeholder="Masukan Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="h-12 border-border bg-background focus:ring-primary focus:border-primary"
                />
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={isLoading}
                className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium transition-all duration-200"
              >
                {isLoading ? "Mengirim..." : "Kirim Tautan Masuk"}
              </Button>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;
