# CCI GD Project

Fondasi game jam 2D berbasis Godot 4.7.1. Project saat ini memakai placeholder agar gameplay dapat dikembangkan tanpa menunggu asset final.

## Menjalankan project

1. Buka folder repository ini dari Godot 4.7.1.
2. Jalankan project (`F6`/`F5`) atau gunakan:
   ```bash
   /usr/bin/Godot --path .
   ```
3. Validasi tanpa membuka window:
   ```bash
   /usr/bin/Godot --headless --path . --editor --quit
   /usr/bin/Godot --headless --path . tests/foundation_smoke.tscn
   ```

## Kontrol

- `A`/`D` atau panah: bergerak
- `Space`: lompat
- `E`: interaksi/pickup
- `1`/`2` atau roda mouse: pilih hotbar
- Klik kiri: gunakan item aktif
- Klik kanan: lempar item aktif
- `Tab`: buka/tutup inventory
- `Esc`: pause

## Struktur dan workflow

- Scene dan script fitur berada bersama di `game/`.
- Resource data berada di `data/` dan ditemukan otomatis oleh `ContentCatalog`.
- Asset final masuk ke `assets/art/` dan `assets/audio/`; programmer tetap memiliki collision.
- Gunakan feature branch dan hindari mengedit `.tscn` yang sama secara bersamaan.
- Programmer membaca [dokumen fondasi teknis](docs/fondasi_teknis_godot.md) dan [panduan programming](docs/panduan_programming.md) sebelum mulai.
- Riwayat jawaban desain berada di [questionnaire fondasi](docs/pertanyaan_klarifikasi_fondasi.md).
- Dokumen desain sebelumnya disimpan utuh di `docs/reference/`.

## Target saat ini

Fondasi runtime, inventory, item, combat, sensing, persistence, dan world contract. `Throwable Rock` adalah implementasi referensi; `Rattlepod` adalah item berikutnya.
