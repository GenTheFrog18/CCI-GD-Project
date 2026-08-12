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
west_02  east_02   y = 800
west_03  east_03   y = 1600
```

West berada pada `x = 0`; east pada `x = 1280`. Section biasa berukuran 1280×800 px atau 80×50 tile. Total bounds layer adalah 2560×2400 px. Layer scene boleh mempunyai ruang khusus berbeda ukuran jika anchor dan bounds eksplisit.

## 2. Kontrak scene section

Setiap variation wajib mempunyai:

```text
WorldSection
├── Terrain              TileMapLayer
├── EntryAnchor          Marker2D
├── ExitAnchor           Marker2D
├── RespawnAnchor        Marker2D
├── Placers              Node2D
└── AuthoredContent      Node2D
```

Field root wajib:

- `slot_id`, contoh `layer1_east_02`;
- `variation_id`, contoh `layer1_east_02_a`;
- `selection_weight`, default `1`;
- `section_size = Vector2(1280, 800)`;
- `camera_bounds = Rect2(0, 0, 1280, 800)`;
- reference Entry, Exit, Respawn, Placers, dan AuthoredContent;
- special tags jika section memiliki shop, crossing, atau ending entrance.

Geometry seam:

- entry pada `(640, 0)`;
- exit pada `(640, 800)`;
- respawn pada `(640, 64)`;
- opening 96 px;
- collision clearance 96 px ke dalam section;
- 96 px atau enam tile dari entry/exit bebas random enemy dan hazard placer;
- semua variation pada slot sama memakai seam identik.

Sisi luar route tertutup collision. Connector horizontal hanya boleh ada pada slot khusus. Terrain utama tidak destructible; breakable adalah scene object terpisah.

## 3. Tanggung jawab slot khusus

- Layer 1 west/east slot 03: masing-masing menyediakan separuh crossing kompatibel dan entrance sisi menuju Layer 2.
- Layer 2 east slot 02: setiap variation mempunyai optional shop branch dan guidance yang terlihat.
- Layer 2 west/east slot 03: masing-masing menyediakan separuh gauntlet/crossing kompatibel.
- Layer 2 east slot 03: setiap variation mempunyai tepat satu interactable Layer 3 entrance.

Gatekeeper shop optional. Quest memberi Moon Whistle dan powerful relic, tetapi tidak membuka hard gate. Player terampil boleh melewati gauntlet tanpa reward. Interaction entrance Layer 3 selalu mengakhiri build.

## 4. Workflow level designer

1. Buka variation slot yang tepat sebagai inherited scene; jangan duplicate slot lain lalu mengganti ID saja.
2. Pilih child `Terrain`, lalu lukis map memakai TileMap GUI pada grid 80×50. Jangan mengubah root ID, tags, anchors, atau bounds.
3. Seam berada pada kolom tile 40. Sisakan enam baris tile paling atas dan bawah dari random enemy/hazard; buat landing aman di bawah `RespawnAnchor`.
4. Buat jalur turun dan naik yang jelas. Selama Rope baru berupa prototype non-persistent, map wajib dapat dilalui dua arah tanpa Rope. Layout Rope-required dibuat setelah persistence/seam Rope final dapat diuji.
5. Pastikan surface shop selalu mempunyai Rope yang terjangkau dan beri warning sebelum rope-required drop.
6. Buat optional branch di dalam section; generator tidak menyusun topology branch.
7. Tempatkan placer dan child SpawnPoint dengan GUI.
8. Run section melalui shared section test runner, lalu jalankan `Validate World` dari F3.

Target traversal setelah detailed graybox:

- sekitar 10 menit per layer untuk run normal dengan eksplorasi;
- sekitar 3 menit per layer jika player bergerak cepat;
- jalur wajib memakai maksimal sekitar 80% kemampuan movement agar tidak pixel-perfect.
- untuk controller saat ini, graybox wajib memakai rise maksimal 32 px, gap horizontal maksimal 48 px, dan landing minimal 96 px.

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

Camera mengikuti player secara horizontal dan vertikal. Depth 01–02 memakai bounds seluruh route 1280×2400 agar seam vertikal tidak menghentikan camera. Depth 03 memakai bounds seluruh layer 2560×2400 agar crossing east/west mulus. `Camera2D` native limit/smoothing dipakai; jangan membuat custom camera framework.

Keluar world tanpa seam valid mengembalikan player ke `last_safe_position` dengan tepat 1 HP. Safe position diperbarui hanya pada surface, shop, dan seam valid. Enemy out-of-bounds menerima fall damage; survivor atau enemy fall-immune kembali ke placer.

## 8. Persistence ownership

Manifest menyimpan seed, world revision, selected variation, resolved placer entries/points, semantic player location, dan runtime ID counter.

Placer result terpisah dari spawned object state. Destroyed child tidak muncul lagi. Enemy biasa menyimpan alive/dead dan health, lalu Continue menaruh survivor kembali di placer dengan AI state netral.

Item, enemy, dan Rope yang dapat melewati seam berada pada layer runtime root. Dynamic object menyimpan layer ID dan global position. Rope boleh melewati seam karena seluruh layer tetap instantiated; Rope menyimpan root placement dan geometry/state miliknya.

Aturan di atas adalah contract Rope final. Prototype player pertama sengaja hanya menguji item selection, placement/consume, visual, climbing, dan control. Prototype belum disimpan, belum dijamin melewati seam, dan tidak boleh dipakai level designer sebagai jalur wajib. Setelah prototype disetujui, barulah Rope dipindahkan ke layer runtime root dan diberi stable runtime ID/state sesuai contract ini.

Autosave layer transition dilakukan setelah destination selesai dibuat, player berada pada safe anchor, dan restore selesai. State source ditahan di memory selama transition agar tidak hilang.

## 9. Debug tools

Main menu Debug Run menampilkan seed input. Seed `0` berarti random; nilai lain mereproduksi run.

Pause menu selalu menunjukkan seed. Debug Mode menambah World Gen Log berisi:

- duration setiap stage dan total;
- selected variation per slot;
- placer result dan quantity;
- fallback, warning, dan error.

F3 selalu membuka panel scrollable berisi unlimited health, active-section text, bounds/seam draw, manifest dump, teleport ke slot/shop/gate, dan validate world. World Gen Log hanya ada pada Debug Run dan dapat ditutup dengan tombol Close atau Esc. Regenerate hanya melalui New Run.

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
- Camera tidak berhenti pada seam `y = 800` atau `y = 1600`, dan mengikuti gerak horizontal dalam route.
- Setiap map authored dapat dimainkan turun dan naik tanpa Rope selama mechanic Rope belum tersedia.
- Prototype Rope tidak dianggap memenuhi acceptance persistence/seam; map tetap tidak boleh bergantung kepadanya.
- Debug panel dan World Gen Log tidak keluar dari viewport 640×360.
- Headless import dan smoke test selesai tanpa error.
