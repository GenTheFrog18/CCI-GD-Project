# Panduan World & Map Generation

Dokumen ini adalah kontrak kerja programmer dan level designer. Keputusan mentah tersimpan di `keputusan_world_generation.md`; jika terjadi konflik, `fondasi_teknis_godot.md` menang.

## 1. Hasil yang dibangun

World bukan terrain procedural. Level designer membuat section dengan tangan. Generator hanya:

1. memilih variation untuk 12 fixed slot,
2. memilih isi placer,
3. memvalidasi sambungan,
4. menginstansiasi layer aktif,
5. memulihkan living-run state.

Layer 0 adalah satu authored hub. Layer 1 dan Layer 2 masing-masing mempunyai enam slot:

```text
west_01  east_01   y = 0
west_02  east_02   y = 1600
west_03  east_03   y = 3200
```

West berada pada `x = 0`; east pada `x = 640`. Section biasa berukuran 640×1600 px. Layer scene boleh mempunyai ruang khusus berbeda ukuran jika anchor dan bounds eksplisit.

## 2. Kontrak scene section

Setiap variation wajib mempunyai:

```text
WorldSection
├── Terrain              TileMapLayer
├── EntryAnchor          Marker2D
├── ExitAnchor           Marker2D
├── Placers              Node2D
└── AuthoredContent      Node2D
```

Field root wajib:

- `slot_id`, contoh `layer1_east_02`;
- `variation_id`, contoh `layer1_east_02_a`;
- `selection_weight`, default `1`;
- `section_size = Vector2(640, 1600)`;
- `camera_bounds = Rect2(0, 0, 640, 1600)`;
- reference Entry, Exit, Placers, dan AuthoredContent;
- special tags jika section memiliki shop, crossing, atau ending entrance.

Geometry seam:

- entry pada `(320, 0)`;
- exit pada `(320, 1600)`;
- opening 96 px;
- collision clearance 96 px ke dalam section;
- 360 px dari entry/exit bebas random enemy dan hazard placer;
- semua variation pada slot sama memakai seam identik.

Sisi luar route tertutup collision. Connector horizontal hanya boleh ada pada slot khusus. Terrain utama tidak destructible; breakable adalah scene object terpisah.

## 3. Tanggung jawab slot khusus

- Layer 1 west/east slot 03: masing-masing menyediakan separuh crossing kompatibel dan entrance sisi menuju Layer 2.
- Layer 2 east slot 02: setiap variation mempunyai optional shop branch dan guidance yang terlihat.
- Layer 2 west/east slot 03: masing-masing menyediakan separuh gauntlet/crossing kompatibel.
- Layer 2 east slot 03: setiap variation mempunyai tepat satu interactable Layer 3 entrance.

Gatekeeper shop optional. Quest memberi Moon Whistle dan powerful relic, tetapi tidak membuka hard gate. Player terampil boleh melewati gauntlet tanpa reward. Interaction entrance Layer 3 selalu mengakhiri build.

## 4. Workflow level designer

1. Duplicate template slot yang tepat; jangan duplicate slot lain lalu mengganti ID saja.
2. Pertahankan root, size, anchor, clearance, camera bounds, dan inward connector.
3. Buat jalur turun dan naik yang jelas. Section boleh sengaja membutuhkan Rope untuk return/safe descent.
4. Pastikan surface shop selalu mempunyai Rope yang terjangkau dan beri warning sebelum rope-required drop.
5. Buat optional branch di dalam section; generator tidak menyusun topology branch.
6. Tempatkan placer dan child SpawnPoint dengan GUI.
7. Jangan menaruh random enemy/hazard di seam safe zone.
8. Run section melalui shared section test runner.
9. Run world validator sebelum menyerahkan scene.

Target traversal setelah detailed graybox:

- sekitar 10 menit per layer untuk run normal dengan eksplorasi;
- sekitar 3 menit per layer jika player bergerak cepat;
- jalur wajib memakai maksimal sekitar 80% kemampuan movement agar tidak pixel-perfect.

## 5. Kontrak placer

Placer menyimpan:

- `persistent_id` unik;
- `spawn_chance` 0–1;
- `minimum_quantity` dan `maximum_quantity`;
- weighted entries berisi stable content ID, scene, dan integer weight positif;
- authored SpawnPoint children;
- optional facing dan patrol bounds;
- optional allocation group dan required flag.

Resolve order:

1. roll activation satu kali;
2. jika aktif, roll quantity minimal satu;
3. pilih SpawnPoint tanpa replacement;
4. pilih weighted entry untuk tiap hasil;
5. beri child ID `placer_id:spawn_point_index`.

Quantity tidak boleh melebihi jumlah SpawnPoint. Runtime memakai posisi authored apa adanya; overlap atau marker tanpa ground adalah validation error.

Allocation group memilih maksimal satu placer pemenang di seluruh run. Required group selalu mempunyai satu pemenang; ini dipakai quest relic. Optional group boleh kosong; ini dipakai rare item maksimum satu per run.

## 6. Generation dan loading

New Run memilih seluruh layout dan placer result kedua playable layer. Hanya layer aktif yang diinstansiasi. Continue membaca manifest tersimpan.

Stage loading:

1. validate pools,
2. select sections,
3. validate selected scenes,
4. resolve allocation groups,
5. resolve placers,
6. instantiate current layer,
7. spawn persistent content,
8. restore saved state,
9. spawn player,
10. final validation.

Generator yield minimal sekali per unit kerja sehingga window tetap responsive dan progress menunjukkan kerja nyata. Tidak ada fixed delay setelah generation. Error development menghentikan player spawn dan ditampilkan lengkap; export mencoba fallback scene eksplisit lalu mencatat warning.

## 7. Activation, camera, dan out-of-bounds

Seluruh terrain layer aktif tetap loaded. Enemy processing aktif hanya pada:

- section player,
- tetangga vertical langsung,
- section pasangan saat player berada pada crossing slot 03.

F3 menampilkan current layer/route/slot dan daftar section aktif.

Camera memakai bounds section aktif. Crossing memakai gabungan bounds east/west. `Camera2D` native limit/smoothing dipakai; jangan membuat custom camera framework.

Keluar world tanpa seam valid mengembalikan player ke `last_safe_position` dengan tepat 1 HP. Safe position diperbarui hanya pada surface, shop, dan seam valid. Enemy out-of-bounds menerima fall damage; survivor atau enemy fall-immune kembali ke placer.

## 8. Persistence ownership

Manifest menyimpan seed, world revision, selected variation, resolved placer entries/points, semantic player location, dan runtime ID counter.

Placer result terpisah dari spawned object state. Destroyed child tidak muncul lagi. Enemy biasa menyimpan alive/dead dan health, lalu Continue menaruh survivor kembali di placer dengan AI state netral.

Item, enemy, dan Rope yang dapat melewati seam berada pada layer runtime root. Dynamic object menyimpan layer ID dan global position. Rope boleh melewati seam karena seluruh layer tetap instantiated; Rope menyimpan root placement dan geometry/state miliknya.

Autosave layer transition dilakukan setelah destination selesai dibuat, player berada pada safe anchor, dan restore selesai. State source ditahan di memory selama transition agar tidak hilang.

## 9. Debug tools

Main menu Debug Mode menampilkan seed input. Seed `0` berarti random; nilai lain mereproduksi run.

Pause menu selalu menunjukkan seed. Debug Mode menambah World Gen Log berisi:

- duration setiap stage dan total;
- selected variation per slot;
- placer result dan quantity;
- fallback, warning, dan error.

Debug panel menyediakan active-section text, bounds/seam draw, manifest dump, teleport ke slot/shop/gate, dan validate world. Regenerate hanya melalui New Run.

## 10. Acceptance minimum

- Seed sama menghasilkan manifest sama; seed berbeda dapat menghasilkan variation berbeda.
- Menambah slot/placer tidak mereroll stable ID lain.
- Semua A/B combination pada seam valid.
- Missing/duplicate ID, anchor, root, bounds, SpawnPoint, atau weight menjadi error.
- Semua special slot memenuhi tag/count contract.
- Continue tidak mereroll, respawn destroyed content, atau memindahkan state antar-layer.
- Player tidak ada sebelum generation selesai.
- Kedua sisi Layer 1 mencapai kedua entrance Layer 2.
- Shop optional dapat ditemukan di east slot 02.
- Gauntlet dan ending dapat dicapai tanpa quest reward.
- Headless import dan smoke test selesai tanpa error.
