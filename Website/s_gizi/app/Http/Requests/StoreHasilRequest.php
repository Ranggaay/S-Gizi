<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreHasilRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'child_id' => ['required', 'integer', 'exists:children,id'],
            'berat' => ['required', 'numeric', 'min:0.1', 'max:200'],
            'tinggi' => ['required', 'numeric', 'min:30', 'max:200'],
            'tanggal_ukur' => ['required', 'date'],
        ];
    }
}

