import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ArrowLeft, Lock, Loader2 } from "lucide-react";
import { useNavigate } from "react-router-dom";
import ConfirmationPopup from "@/components/ConfirmationPopup";
import { forgotPasswordSchema } from "@/lib/validations";
import FormError from "@/components/FormError";

const ForgotPassword = () => {
  const [email, setEmail] = useState("");
  const [showPopup, setShowPopup] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errors, setErrors] = useState<{ email?: string }>({});
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrors({});

    // Validate form
    const result = forgotPasswordSchema.safeParse({ email });
    if (!result.success) {
      const fieldErrors: { email?: string } = {};
      result.error.errors.forEach((err) => {
        if (err.path[0] === "email") fieldErrors.email = err.message;
      });
      setErrors(fieldErrors);
      return;
    }

    setIsLoading(true);
    
    // Simulate API delay
    await new Promise((resolve) => setTimeout(resolve, 1000));
    
    setIsLoading(false);
    setShowPopup(true);
  };

  const handlePopupClose = (open: boolean) => {
    setShowPopup(open);
    if (!open) {
      navigate("/reset-password");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-muted/30 p-4">
      <div className="w-full max-w-md">
        {/* Card with top border */}
        <div className="bg-background rounded-lg shadow-lg overflow-hidden">
          {/* Top accent border */}
          <div className="h-1.5 bg-primary" />
          
          <div className="p-8">
            {/* Header with back button and lock icon */}
            <div className="flex items-start justify-between mb-6">
              <button
                onClick={() => navigate("/")}
                className="w-10 h-10 rounded-lg bg-primary flex items-center justify-center text-primary-foreground hover:bg-primary/90 transition-colors"
              >
                <ArrowLeft size={20} />
              </button>
              <div className="w-12 h-12 rounded-lg border-2 border-primary flex items-center justify-center">
                <Lock className="text-primary" size={24} />
              </div>
            </div>

            {/* Title and description */}
            <h1 className="text-xl font-semibold text-foreground mb-2">
              Kesulitan Login?
            </h1>
            <p className="text-sm text-muted-foreground mb-8">
              Masukkan email, atau nama pengguna yang terkait dengan akun Anda untuk mengubah kata sandinya.
            </p>

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="space-y-2">
                <label htmlFor="email" className="text-sm font-medium text-foreground">
                  Email/Username
                </label>
                <Input
                  id="email"
                  type="email"
                  placeholder="Masukan Email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className={`h-12 border-border bg-background placeholder:text-muted-foreground/60 ${errors.email ? "border-destructive" : ""}`}
                />
                <FormError message={errors.email} />
              </div>

              <Button
                type="submit"
                disabled={isLoading}
                className="w-full h-12 bg-primary hover:bg-primary/90 text-primary-foreground font-medium"
              >
                {isLoading ? <Loader2 className="animate-spin" size={20} /> : "Kirim Tautan Masuk"}
              </Button>
            </form>
          </div>
        </div>
      </div>

      {/* Confirmation Popup */}
      <ConfirmationPopup
        open={showPopup}
        onOpenChange={handlePopupClose}
        type="email-sent"
        email={email}
      />
    </div>
  );
};

export default ForgotPassword;
