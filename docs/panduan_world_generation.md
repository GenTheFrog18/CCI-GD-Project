# Panduan World dan Map Generation

> **Status:** kontrak authoring aktif, diaudit 30 Agustus 2026. Dokumen ini menjelaskan code sekarang; intent world jangka panjang berada di GDD.

## 1. Model world

Terrain tidak procedural. Level designer membuat setiap section secara manual. Generator hanya:

1. memilih satu variation per fixed slot;
2. menyelesaikan weighted placer dari seed;
3. memvalidasi ID dan scene contract;
4. menyimpan manifest;
5. menginstansiasi layer aktif;
6. memulihkan state run.

Surface adalah satu authored hub. Layer 1 dan foundation Layer 2 masing-masing mempunyai enam slot:

```text
west_01  east_01   y = 0
west_02  east_02   y = 800
west_03  east_03   y = 1600
```

West berada di `x = 0`, east di `x = 1280`. Default section 1280×800 px; default layer bounds 2560×2400 px.

Normal build sekarang selesai di gate Layer 2. Requirement Layer 3 yang masih ada pada template/validator adalah legacy code, bukan target authoring baru.

## 2. Scene contract

Root variation harus `WorldSection` dan mengisi:

- `slot_id` yang sama dengan owning `WorldSlot`;
- unique `variation_id`;
- positive `selection_weight`;
- `section_size` dan `camera_bounds`;
- `EntryAnchor`, `ExitAnchor`, `RespawnAnchor`;
- `Placers` dan `AuthoredContent` owner;
- `special_tags` hanya bila validator/code benar-benar membutuhkannya.

Terrain biasanya `TileMapLayer`. Authored NPC, gate, safe zone, POI, darkness region, background marker, dan map Rope berada di `AuthoredContent`, bukan placer.

Variation untuk slot yang sama wajib mempunyai seam compatible. Current baseline memakai entry `(640, 0)`, exit `(640, 800)`, opening 96 px, dan safe clearance 96 px, kecuali slot/scene menyatakan bounds khusus.

Jangan mengubah `slot_id` untuk memakai scene variation milik slot lain. Generator menolak mismatch.

## 3. Workflow membuat variation

1. Mulai dari template/inherited scene slot yang benar.
2. Isi terrain melalui TileMap editor.
3. Pertahankan root ID, anchors, bounds, dan required tags.
4. Pastikan jalur utama dapat turun dan naik; Rope belum boleh menjadi satu-satunya jalan kecuali acquisition dijamin.
5. Sisakan area aman pada entry, exit, respawn, gate, dan landing sempit.
6. Tambahkan authored content dan placer pada owner yang benar.
7. Beri setiap placer `persistent_id` global-unique.
8. Jalankan section langsung, custom world F3, lalu Validate World.

Target traversal lama seperti 3/10 menit adalah playtest guide, bukan validator. Jangan mengubah movement player agar map buruk lolos.

## 4. Deterministic placer

Semua placer umum memakai `game/world/deterministic_placer.gd`.

| Property | Makna |
| --- | --- |
| `Persistent ID` | Stable ID global untuk manifest/save. Wajib unik. |
| `Spawn Chance` | Satu activation roll untuk seluruh placer. |
| `Entries` | Weighted content candidates. Satu dipilih per hasil. |
| `Minimum/Maximum Quantity` | Rentang jumlah hasil setelah placer aktif. |
| `Allocation Group` | Beberapa placer berkompetisi untuk satu winner run-wide. |
| `Required Allocation` | Winner group dipaksa aktif saat resolve. |
| `Spawn Group ID` | Optional coordination group yang disuntik ke spawned actor. |
| `Attack Group Maximum/Spacing` | Optional coordinated attack limits. |
| `Drop Scatter Radius/Height Offset` | Area drop breakable; terlihat di editor. |
| `Facing` | Tanda horizontal awal, biasanya `1` atau `-1`. |
| `Patrol Bounds` | Rectangle optional untuk actor yang menerimanya. |

`Entries` berisi `WorldSpawnEntry`:

- `content_id`: item/enemy stable ID;
- `scene`: scene yang diinstansiasi;
- `weight`: relative integer weight.

## 5. SpawnPoint dan quantity

Direct child `Marker2D` adalah SpawnPoint. Bila tidak ada direct child, array storage `spawn_points` dapat menjadi fallback, tetapi authoring baru harus memakai child marker.

Quantity tidak dibatasi jumlah SpawnPoint. Setiap hasil memilih point dengan replacement. Contoh quantity 3 dengan satu SpawnPoint menghasilkan tiga object pada marker yang sama, masing-masing dengan persistent ID berbeda:

```text
placer_id:0
placer_id:0:1
placer_id:0:2
```

Gunakan beberapa SpawnPoint bila perlu penyebaran authored. Gunakan satu point bila overlap awal aman atau spawned scene sendiri melakukan scatter. Loot breakable memakai `drop_scatter_radius` dan `drop_height_offset` untuk menyebar static pickup setelah pecah.

Jangan mengandalkan urutan SpawnPoint yang berubah setelah save compatibility dianggap penting.

## 6. Allocation dan group

`allocation_group` dipakai untuk unique content lintas selected variation. Generator mengurutkan candidate berdasarkan persistent ID, memilih winner deterministic, lalu hanya winner yang resolve.

- Kosong: placer resolve sendiri memakai chance.
- Group optional: hanya winner boleh resolve, tetapi chance winner tetap dapat menghasilkan kosong.
- Group required: winner resolve tanpa activation failure.

`spawn_group_id` berbeda fungsi. Field ini menyambungkan actor yang perlu berbagi coordinator/alert; ia tidak menentukan apakah placer dipilih.

## 7. Preset placer

| Scene | Pemakaian |
| --- | --- |
| `enemy_placer.tscn` | Ordinary Layer 1 enemy/hazard. |
| `loot_placer.tscn` | Breakable source berisi weighted item. |
| `bird_nest_placer.tscn` | 1–3 Knockback Bird dengan circular patrol radius editor preview. |
| `large_flyer_placer.tscn` | Candidate untuk satu Large Flyer Layer 1. |
| `layer2_enemy_placer.tscn` | Weighted Layer 2 foundation enemy. |
| relic placer Layer 2 | Unique Umbrella, Lacerator, atau required Resonance Core. |

Loot placer mengisi `BreakableLoot.item_id`. Ketika pecah, source menghasilkan Throwable Rock dan configured item sebagai static pickup yang langsung dapat diambil. Posisi masing-masing diacak dalam circular scatter area di atas source.

Bird Nest memakai `patrol_radius`, bukan `patrol_bounds`. Large Flyer membutuhkan authored `LargeFlyerPOI`; transparent `LargeFlyerBlocker` hanya menghalangi movement, bukan sight.

## 8. Generation lifecycle

`WorldGenerator.build_manifest()`:

1. instantiate dan validate layer pool;
2. pilih variation, termasuk optional debug override Layer 1;
3. validate section/special contract;
4. kumpulkan placer dan cek duplicate ID;
5. pilih allocation winner;
6. resolve placer;
7. simpan generation log dan errors.

Generator yield antar unit kerja agar startup tetap responsive. Error menghentikan player spawn dan tampil pada loading panel.

`WorldLayer.instantiate_manifest()` membuat selected section, memulihkan resolved placer data, lalu spawn ke runtime root. Surface tidak memakai section manifest.

## 9. Activation, camera, dan bounds

`WorldRun` memeriksa section player secara berkala. Layer memilih active slot, mengatur processing content, camera bounds, current route/slot, dan safe position.

Player di luar layer bounds + margin kembali ke safe position. Dynamic world object yang mempunyai `handle_world_out_of_bounds()` menentukan recovery atau destruction sendiri.

Rope ditempatkan pada runtime root dan dapat melewati seam section. Map-authored Rope memakai `placed_rope.tscn`; player-created Rope mempunyai runtime ID dan geometry persistent.

Darkness region boleh berada sebagian di luar cave/layer bounds. Background adalah camera-space presentation, bukan terrain world object.

## 10. Save ownership

Manifest menyimpan keputusan generation. Object save menyimpan hasil runtime. Jangan memakai salah satunya untuk mengganti yang lain.

- Placer result tidak di-roll ulang saat Continue.
- Destroyed ID mencegah child respawn.
- Enemy biasa menyimpan alive, health, status, position; transient AI reset.
- Item menyimpan ID/state/transform/velocity/frozen state.
- Rope menyimpan placement dan segment lengths.
- Layer transition baru disimpan setelah destination siap dan restore selesai.

## 11. Debug dan preview

F3 main menu membuka Custom World:

- pilih explicit variation untuk enam Layer 1 slot;
- default tiap slot adalah option pertama dari owning `WorldSlot`;
- run tetap dimulai di Surface;
- override hanya berlaku pada requested Layer 1 debug run.

F3 gameplay menyediakan current layer/route/slot, world log, manifest dump, validation, teleport, dan category-based gameplay ranges. Toggle range tetap aktif setelah panel ditutup.

`layer1_section_preview.tscn` hanya editor preview untuk merakit enam chosen variation. Ia bukan runtime generator dan tidak disimpan.

`foundation_test_room.tscn` dapat menjalankan placer langsung melalui bootstrap test-room script, tetapi tidak menggantikan full generated-run test.

## 12. Acceptance checklist

- Root layer/section type benar.
- Semua slot memilih variation miliknya sendiri.
- Stable ID dan variation ID unik.
- Semua required anchors/reference tersedia.
- Entries valid dan mempunyai positive weight.
- Quantity range valid; satu SpawnPoint boleh menerima beberapa hasil.
- Allocation required mempunyai candidate pada setiap layout yang relevan.
- Seam dan collision compatible antar variation.
- Spawn tidak berada dalam terrain/respawn/gate trigger.
- Continue mempertahankan manifest dan destroyed objects.
- Player selalu mulai New Run di Surface.
- Gate Layer 2 dapat dicapai dari kedua route Layer 1.
- F3 Validate World tidak menemukan error.

## 13. Command verifikasi

```bash
/usr/bin/Godot --headless --path . --editor --quit
/usr/bin/Godot --headless --path . --scene res://tests/foundation_smoke.tscn
/usr/bin/Godot --headless --path . --scene res://tests/content_smoke.tscn
```

Untuk masalah pathfinding, tambahkan `ground_traversal_smoke.tscn`. Untuk background/darkness, jalankan smoke scene subsystem tersebut.
