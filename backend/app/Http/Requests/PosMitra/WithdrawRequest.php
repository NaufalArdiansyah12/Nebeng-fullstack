<?php

namespace App\Http\Requests\PosMitra;

use Illuminate\Foundation\Http\FormRequest;

class WithdrawRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'amount' => 'required|numeric|min:50000',
            'bank_name' => 'required|string|max:255',
            'account_number' => 'required|string|max:255',
            'pin' => 'required|string|size:6',
        ];
    }

    /**
     * Get custom messages for validator errors.
     */
    public function messages(): array
    {
        return [
            'amount.required' => 'Jumlah penarikan harus diisi',
            'amount.numeric' => 'Jumlah penarikan harus berupa angka',
            'amount.min' => 'Minimal penarikan Rp 50.000',
            'bank_name.required' => 'Nama bank harus diisi',
            'account_number.required' => 'Nomor rekening harus diisi',
            'pin.required' => 'PIN harus diisi',
            'pin.size' => 'PIN harus 6 digit',
        ];
    }
}
