import { z } from "zod";

export const emailSchema = z
  .string()
  .trim()
  .min(1, { message: "Email tidak boleh kosong" })
  .email({ message: "Format email tidak valid" })
  .max(255, { message: "Email maksimal 255 karakter" });

export const passwordSchema = z
  .string()
  .min(8, { message: "Password minimal 8 karakter" })
  .regex(/[a-z]/, { message: "Password harus mengandung huruf kecil" })
  .regex(/[A-Z]/, { message: "Password harus mengandung huruf besar" })
  .regex(/[0-9]/, { message: "Password harus mengandung angka" })
  .regex(/[#?!@$%^&*-]/, { message: "Password harus mengandung karakter khusus (#?!@$%^&*-)" });

export const loginSchema = z.object({
  email: emailSchema,
  password: z.string().min(1, { message: "Password tidak boleh kosong" }),
});

export const forgotPasswordSchema = z.object({
  email: emailSchema,
});

export const resetPasswordSchema = z
  .object({
    newPassword: passwordSchema,
    confirmPassword: z.string().min(1, { message: "Konfirmasi password tidak boleh kosong" }),
  })
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: "Password tidak cocok",
    path: ["confirmPassword"],
  });
