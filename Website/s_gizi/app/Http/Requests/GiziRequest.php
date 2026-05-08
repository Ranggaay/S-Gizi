<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Contracts\Validation\Validator;
use Illuminate\Http\Exceptions\HttpResponseException;

class GiziRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'jenis_kelamin' => ['required', 'in:L,P'],
            'tanggal_lahir' => ['required', 'date'],
            'tanggal_ukur' => ['required', 'date', 'after_or_equal:tanggal_lahir'],
            'berat_badan' => ['required', 'numeric', 'gt:0', 'max:80'],
            'tinggi_badan' => ['required', 'numeric', 'gt:0', 'min:30', 'max:130'],
            'cara_ukur' => ['required', 'in:standing,lying'],
        ];
    }

    protected function failedValidation(Validator $validator): void
    {
        throw new HttpResponseException(response()->json([
            'error' => 'Validasi input gagal.',
            'details' => $validator->errors(),
        ], 422));
    }
}

