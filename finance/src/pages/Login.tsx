import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Label } from "@/components/ui/label";
import { useNavigate } from "react-router-dom";
import { toast } from "sonner";
import api from "@/lib/api";

const Login = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const navigate = useNavigate();

const handleSubmit = async (e) => {
  e.preventDefault();

  if (!email || !password) {
    toast.error("Email dan password wajib diisi");
    return;
  }

  setIsLoading(true);

  try {
    const response = await api.post(
      "/users/login",
      { email, password }
    );

    toast.success(response.data.message);

    // simpan user admin
    localStorage.setItem(
      "user",
      JSON.stringify(response.data.user)
    );

    // redirect ke admin dashboard
    navigate("/dashboard");

  } catch (error) {
    const status = error.response?.status;
    const message = error.response?.data?.message;

    if (status === 401) {
      toast.error(message || "Email atau password salah");
    } else if (status === 403) {
      toast.error("Akses ditolak. Hanya admin yang dapat login");
    } else {
      toast.error("Terjadi kesalahan pada server");
    }
  } finally {
    setIsLoading(false);
  }
};



  return (
    <div className="min-h-screen flex">
      {/* Left Sidebar */}
      <div className="hidden lg:flex lg:w-[45%] bg-login-sidebar flex-col justify-between p-8 relative overflow-hidden">
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-20 left-10 w-32 h-32 border border-white/30 rounded-full" />
          <div className="absolute bottom-40 right-20 w-48 h-48 border border-white/20 rounded-full" />
          <div className="absolute top-1/2 left-1/4 w-24 h-24 border border-white/25 rounded-full" />
        </div>

        {/* Logo */}
        <div className="relative z-10">
          <div className="flex items-center gap-2">
            <span className="text-2xl font-bold text-login-sidebar-foreground">Nebeng</span>
            <span className="text-login-highlight text-2xl">.</span>
          </div>
        </div>

        {/* Welcome Text */}
        <div className="relative z-10 mb-20">
          <h1 className="text-4xl md:text-5xl font-bold text-login-sidebar-foreground mb-4">
            Hallo,
            <br />
            Selamat Datang
          </h1>
          <p className="text-login-sidebar-foreground/70 text-sm max-w-md leading-relaxed">
            Lorem ipsum is simply dummy text of the printing and typesetting industry. 
            Lorem ipsum has been the industry's standard dummy text ever since the 1500s.
          </p>
        </div>

        {/* Footer */}
        <div className="relative z-10">
          <p className="text-login-sidebar-foreground/50 text-xs">
            *Aplikasi yang membantu masyarakat dalam mobilitas{" "}
            <span className="underline cursor-pointer hover:text-login-sidebar-foreground/70">
              keperluan
            </span>
          </p>
        </div>
      </div>

      {/* Right Form Section */}
      <div className="flex-1 flex items-center justify-center p-8 bg-background">
        <div className="w-full max-w-md">
          {/* Mobile Logo */}
          <div className="lg:hidden mb-8 text-center">
            <div className="flex items-center justify-center gap-2">
              <span className="text-2xl font-bold text-primary">Nebeng</span>
              <span className="text-yellow-500 text-2xl">.</span>
            </div>
          </div>

          {/* Form Header */}
          <div className="mb-8">
            <p className="text-foreground/70 text-sm">
              <span className="text-primary font-medium underline cursor-pointer hover:text-primary/80">
                Login
              </span>{" "}
              untuk melanjutkan ke Dashboard Nebeng
            </p>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Email Field */}
            <div className="space-y-2">
              <Label htmlFor="email" className="text-sm font-medium text-foreground">
                Email
              </Label>
              <Input
                id="email"
                type="email"
                placeholder="Masukkan Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="h-12 border-border bg-background focus:ring-primary focus:border-primary"
              />
            </div>

            {/* Password Field */}
            <div className="space-y-2">
              <Label htmlFor="password" className="text-sm font-medium text-foreground">
                Password
              </Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="Masukkan password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="h-12 border-border bg-background focus:ring-primary focus:border-primary pr-12"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                >
                  {showPassword ? (
                    <EyeOff className="h-5 w-5" />
                  ) : (
                    <Eye className="h-5 w-5" />
                  )}
                </button>
              </div>
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="remember"
                  checked={rememberMe}
                  onCheckedChange={(checked) => setRememberMe(checked as boolean)}
                  className="border-border data-[state=checked]:bg-primary data-[state=checked]:border-primary"
                />
                <Label
                  htmlFor="remember"
                  className="text-sm text-muted-foreground cursor-pointer"
                >
                  Remember me
                </Label>
              </div>
              <button
                type="button"
                onClick={() => navigate("/forgot-password")}
                className="text-sm text-primary hover:text-primary/80 font-medium transition-colors"
              >
                Lupa Password?
              </button>
            </div>

            {/* Submit Button */}
            <Button
              type="submit"
              disabled={isLoading}
              className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium transition-all duration-200"
            >
              {isLoading ? "Memproses..." : "Log In"}
            </Button>
          </form>

          {/* Footer */}
          <p className="mt-8 text-xs text-muted-foreground">
            *Pengguna yang terdaftar adalah Supervisor
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;
