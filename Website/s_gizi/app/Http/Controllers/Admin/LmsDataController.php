<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\WhoLmsAge;
use App\Models\WhoLmsWfh;
use App\Models\WhoLmsWfl;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\View\View;

class LmsDataController extends Controller
{
    public function index(Request $request): View
    {
        $type = $request->query('type', 'age');
        $model = $this->model($type);
        $rows = $model::query()->orderBy($type === 'age' ? 'umur' : ($type === 'wfl' ? 'panjang' : 'tinggi'))->paginate(25)->withQueryString();

        return view('admin.lms.index', compact('rows', 'type'));
    }

    public function store(Request $request): RedirectResponse
    {
        $type = $request->input('type', 'age');
        $model = $this->model($type);
        $model::query()->create($this->validated($request, $type));
        Cache::flush();

        return back()->with('success', 'Data LMS berhasil ditambahkan.');
    }

    public function update(Request $request, string $type, int $id): RedirectResponse
    {
        $model = $this->model($type);
        $model::query()->findOrFail($id)->update($this->validated($request, $type));
        Cache::flush();

        return back()->with('success', 'Data LMS berhasil diperbarui.');
    }

    public function destroy(string $type, int $id): RedirectResponse
    {
        $model = $this->model($type);
        $model::query()->findOrFail($id)->delete();
        Cache::flush();

        return back()->with('success', 'Data LMS berhasil dihapus.');
    }

    private function model(string $type): string
    {
        return match ($type) {
            'wfh' => WhoLmsWfh::class,
            'wfl' => WhoLmsWfl::class,
            default => WhoLmsAge::class,
        };
    }

    private function validated(Request $request, string $type): array
    {
        $base = [
            'jk' => ['required', 'in:L,P'],
            'L' => ['required', 'numeric'],
            'M' => ['required', 'numeric', 'gt:0'],
            'S' => ['required', 'numeric', 'gt:0'],
        ];

        if ($type === 'age') {
            return $request->validate($base + [
                'indikator' => ['required', 'in:bbu,tbu'],
                'umur' => ['required', 'integer', 'min:0', 'max:60'],
            ]);
        }

        return $request->validate($base + [
            $type === 'wfl' ? 'panjang' : 'tinggi' => ['required', 'numeric', 'min:30', 'max:130'],
        ]);
    }
}
