import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Checkbox } from "@/components/ui/checkbox";
import { Eye, EyeOff, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { loginSchema } from "@/lib/validations";
import FormError from "@/components/FormError";

const Index = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});

    // Validate form
    const result = loginSchema.safeParse({ email, password });
    if (!result.success) {
      const fieldErrors: { email?: string; password?: string } = {};
      result.error.errors.forEach((err) => {
        if (err.path[0] === "email") fieldErrors.email = err.message;
        if (err.path[0] === "password") fieldErrors.password = err.message;
      });
      setErrors(fieldErrors);
      return;
    }

    setIsLoading(true);
    
    try {
      // Coba fetch tanpa abort signal dulu
      const response = await fetch('http://localhost:3001/api/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: email,
          password: password,
        }),
      });

      // Cek apakah response OK
      if (!response.ok) {
        const errorText = await response.text();
        console.error('Server response error:', errorText);
        throw new Error(`Server error: ${response.status}`);
      }

      const data = await response.json();

      if (data.success) {
        // Cek apakah role adalah admin (sudah dicek di backend tapi double check)
        if (data.user.role !== 'admin') {
          toast.error("Akses ditolak! Hanya admin yang dapat login ke dashboard.");
          setIsLoading(false);
          return;
        }

        // PENTING: Simpan token dan user data
        console.log('✅ Login successful, saving token:', data.token);
        
        if (data.token) {
          localStorage.setItem('token', data.token);
          console.log('Token saved to localStorage');
        }
        
        const userData = JSON.stringify(data.user);
        if (rememberMe) {
          localStorage.setItem('user', userData);
          console.log('User data saved to localStorage');
        } else {
          sessionStorage.setItem('user', userData);
          console.log('User data saved to sessionStorage');
        }

        toast.success("Login berhasil!");
        
        // Delay sedikit sebelum navigate agar token tersimpan
        setTimeout(() => {
          navigate("/dashboard");
        }, 100);
      } else {
        // Tampilkan error dari server
        toast.error(data.message || "Email atau password salah!");
      }
    } catch (error: any) {
      console.error('Login error:', error);
      
      // Cek jenis error
      if (error.message.includes('Failed to fetch')) {
        toast.error("Tidak dapat terhubung ke server. Pastikan backend berjalan di http://localhost:3001");
      } else if (error.name === 'AbortError') {
        toast.error("Request timeout. Server terlalu lama merespon.");
      } else if (error.message.includes('Server error')) {
        toast.error("Server mengalami masalah. Cek console untuk detail.");
      } else {
        toast.error("Terjadi kesalahan saat login: " + error.message);
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen">
      {/* Left Panel - Gradient Background */}
      <div className="hidden lg:flex lg:w-1/2 bg-nebeng-gradient relative overflow-hidden flex-col justify-between p-10">
        {/* Decorative blobs */}
        <div className="blob-shape blob-1" />
        <div className="blob-shape blob-2" />
        
        {/* Logo */}
        <div className="relative z-10">
          <div className="flex items-center gap-1">
            <span className="text-3xl font-bold text-white">Nebeng</span>
            <div className="relative flex items-center justify-center w-5 h-5">
              <div className="absolute w-3 h-3 rounded-full bg-blue-400" />
              <svg
                className="absolute w-5 h-5"
                viewBox="0 0 24 24"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <circle cx="12" cy="12" r="3" fill="#60A5FA" />
                <path
                  d="M12 8C10.9391 8 9.92172 8.42143 9.17157 9.17157C8.42143 9.92172 8 10.9391 8 12"
                  stroke="#60A5FA"
                  strokeWidth="1.5"
                  strokeLinecap="round"
                />
              </svg>
            </div>
          </div>
        </div>

        {/* Welcome Text */}
        <div className="relative z-10 flex-1 flex flex-col justify-center">
          <h1 className="text-5xl font-bold text-white mb-4">
            Hallo,
            <br />
            Selamat Datang
          </h1>
          <p className="text-white/70 text-sm max-w-md leading-relaxed">
            Kelola Nebeng lebih cepat dan terorganisir.
            Login untuk melanjutkan ke dashboard admin.
          </p>
        </div>

        {/* Footer Text */}
        <div className="relative z-10">
          <p className="text-white/60 text-xs">
            * Aplikasi yang membantu masyarakat dalam mencari{" "}
            <a href="#" className="underline hover:text-white/80 transition-colors">
              transportasi
            </a>
          </p>
        </div>
      </div>

      {/* Right Panel - Login Form */}
      <div className="w-full lg:w-1/2 flex flex-col justify-between p-8 lg:p-16">
        <div className="flex-1 flex flex-col justify-center max-w-md mx-auto w-full">
          {/* Mobile Logo */}
          <div className="lg:hidden mb-8">
            <div className="flex items-center gap-1">
              <span className="text-2xl font-bold text-primary">Nebeng</span>
              <div className="w-2 h-2 rounded-full bg-nebeng-blue" />
            </div>
          </div>

          {/* Login Header */}
          <div className="mb-8">
            <h2 className="text-xl text-foreground">
              <span className="font-semibold text-primary">Login</span>{" "}
              <span className="text-muted-foreground">untuk melanjutkan ke Dashboard Nebeng</span>
            </h2>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Email Field */}
            <div className="space-y-2">
              <label htmlFor="email" className="text-sm font-medium text-foreground">
                Email
              </label>
              <Input
                id="email"
                type="email"
                placeholder="Masukkan Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={`h-12 border-border bg-background placeholder:text-muted-foreground/60 ${errors.email ? "border-destructive" : ""}`}
              />
              <FormError message={errors.email} />
            </div>

            {/* Password Field */}
            <div className="space-y-2">
              <label htmlFor="password" className="text-sm font-medium text-foreground">
                Password
              </label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  placeholder="Masukkan password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className={`h-12 border-border bg-background placeholder:text-muted-foreground/60 pr-12 ${errors.password ? "border-destructive" : ""}`}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                >
                  {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
              <FormError message={errors.password} />
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="remember"
                  checked={rememberMe}
                  onCheckedChange={(checked) => setRememberMe(checked as boolean)}
                />
                <label
                  htmlFor="remember"
                  className="text-sm text-muted-foreground cursor-pointer"
                >
                  Remember me
                </label>
              </div>
              <a
                href="/forgot-password"
                className="text-sm text-primary hover:text-primary/80 transition-colors"
              >
                Lupa Password?
              </a>
            </div>

            {/* Login Button */}
            <Button
              type="submit"
              disabled={isLoading}
              className="w-auto px-8 h-11 bg-primary hover:bg-primary/90 text-primary-foreground font-medium"
            >
              {isLoading ? <Loader2 className="animate-spin" size={20} /> : "Log In"}
            </Button>
          </form>
        </div>

        {/* Footer */}
        <div className="mt-8">
          <p className="text-xs text-muted-foreground">
            * Penggunaan yang mudah dan sudah di percaya
          </p>
        </div>
      </div>
    </div>
  );
};

export default Index;