# Panduan Programming — CCI GD Project

Panduan ini menjelaskan cara menulis code yang dapat dibaca dan digabung oleh tim kecil. Aturan desain dan gameplay tetap berasal dari `fondasi_teknis_godot.md`.

## 1. Urutan kerja wajib

Sebelum coding:

1. Baca contract fitur di dokumen fondasi.
2. Cari implementasi serupa dengan `rg`; jangan membuat versi kedua dari sistem yang sudah ada.
3. Tulis input, output, state yang dimiliki, dan acceptance check fitur dalam task/commit.
4. Tentukan file/scene owner agar dua programmer tidak mengedit `.tscn` yang sama.

Saat coding:

1. Buat perubahan terkecil yang menghubungkan fitur ke main game.
2. Simpan nilai balance di Inspector/Resource.
3. Tambahkan satu runnable check untuk logic bercabang, loop, parser, transaksi, atau persistence.
4. Jalankan project dari clean boot, bukan hanya scene test.

Selesai berarti terintegrasi, tidak menghasilkan debugger error berulang, dan diuji orang lain sekali.

## 2. Struktur file

```text
autoload/  hanya empat service global yang disetujui
core/      contract bersama lintas fitur
data/      Resource definition dan content .tres
game/      scene/script gameplay, dikelompokkan per fitur
ui/        menu, HUD, inventory, dialogue
tests/     assertion smoke test
assets/art/     exported runtime art, grouped by feature
assets/source/  editable art source seperti .aseprite
```

Letakkan script di samping scene pemiliknya. Jangan membuat folder `utils/`, `managers/`, atau `helpers/` sebagai tempat code tanpa owner. Helper satu fitur tetap bersama fitur tersebut; pindahkan ke `core/` hanya setelah dipakai minimal dua subsystem nyata.

Asset item memakai `assets/art/items/<fitur>/`; asset UI memakai `assets/art/ui/<fitur>/`. Nama file `snake_case`. Jangan menaruh asset final di folder sementara seperti `current assets`, dan jangan mengubah ukuran bitmap pixel-art untuk menyesuaikan collision. Simpan `.aseprite` yang sesuai di `assets/source/` dengan grouping yang sama.

Mapping asset delivery 12 Agustus yang wajib dipakai saat integration:

| File sementara | Tujuan runtime |
| --- | --- |
| `bandage.png`, `info book.png`, `multitool.png`, `numbing pills.png`, `rock.png` | `assets/art/items/` dengan nama `snake_case` |
| `whistle-red.png`, `whistle-blue.png`, `whistle-moon.png` | `assets/art/items/whistles/whistle_red.png`, `whistle_blue.png`, `whistle_moon.png` |
| `rope-item.png`, `rope-mid.png`, `rope-end.png` | `assets/art/items/rope/rope_item.png`, `rope_segment.png`, `rope_end.png` |
| `backpack.png`, `hotbar-main.png`, `hotbar-sec.png`, `arrow-hotbar.png` | `assets/art/ui/inventory/backpack.png`, `hotbar_main.png`, `hotbar_secondary.png`, `hotbar_arrow.png` |

Pindahkan `.aseprite` pasangan ke `assets/source/items/`, `assets/source/items/whistles/`, `assets/source/items/rope/`, atau `assets/source/ui/inventory/` dengan nama stem yang sama. File source yang memang tidak diberikan tidak perlu dibuat. Lakukan move lewat Godot FileSystem jika asset sudah direferensikan; jika belum direferensikan, filesystem move biasa aman lalu periksa `.import` yang dibentuk ulang.

## 3. GDScript style

- Satu script mempunyai satu tanggung jawab yang dapat disebut dalam satu kalimat.
- Gunakan `class_name` hanya untuk type yang benar-benar dipakai lintas scene/resource.
- Nama file, variable, function, signal, group, dan stable ID memakai `snake_case`.
- Nama class memakai `PascalCase`; constant memakai `UPPER_SNAKE_CASE`.
- Function publik memakai verb: `apply_damage`, `try_add_item`, `capture_state`.
- Boolean memakai `is_`, `has_`, `can_`, atau `should_`.
- Signal menyatakan kejadian lampau: `health_changed`, `item_picked_up`, `died`.
- Prefer typed parameter/return untuk contract publik; local variable sederhana boleh inferred.
- Hindari magic number. Balance value diexport atau berada di Resource.
- Jangan memakai komentar untuk menjelaskan code buruk; komentar menjelaskan alasan/constraint yang tidak terlihat.

Contoh:

```gdscript
signal died(source: Node)

@export var move_speed := 120.0

func apply_damage(info: DamageInfo) -> bool:
    if is_dead or info.amount <= 0.0:
        return false
    health = maxf(0.0, health - info.amount)
    if health == 0.0:
        is_dead = true
        died.emit(info.source)
    return true
```

Hindari:

```gdscript
func do_thing(data):
    # mengecek banyak type item/enemy dengan nama string
    pass
```

## 4. Scene dan node ownership

- Scene root memiliki script yang mengoordinasikan child miliknya.
- Child component memiliki state lokalnya sendiri: Health menyimpan health, Inventory menyimpan slot, Status menyimpan active effects.
- Parent menghubungkan signal child; child tidak mencari parent dengan path panjang seperti `../../../Player`.
- Gunakan exported Node/Resource reference atau signal. NodePath string hanya untuk hubungan stabil dalam scene milik sendiri.
- Collision shape tidak mengikuti sprite otomatis. Programmer mengatur collision; artist mengganti visual child.
- Runtime node yang dibuat code selalu masuk parent yang jelas dan dibersihkan oleh owner yang sama.

## 5. Kapan memakai signal, group, atau direct call

| Kebutuhan | Gunakan |
| --- | --- |
| Caller tahu receiver dan membutuhkan hasil | Direct method call |
| Child memberi tahu parent/observer | Signal |
| Satu event didengar banyak node tidak dikenal | SceneTree group |
| State global run/save/catalog/scene | Autoload yang sudah disetujui |

Contoh: item memanggil Inventory secara langsung untuk request action; Inventory memancarkan `inventory_changed`; sound broadcaster memanggil group `sound_listeners`.

Jangan membuat EventBus global. Ia menyembunyikan dependency dan membuat signal sulit dilacak.

## 6. Autoload

Autoload yang diizinkan:

- `GameSession`
- `SaveManager`
- `ContentCatalog`
- `SceneRouter`

Autoload tidak menyimpan node gameplay, AI, projectile, UI panel, atau behavior item. Jika fitur hanya dipakai satu scene, scene tersebut adalah owner-nya.

## 7. Data Resource

- Resource menyimpan identity, asset reference, dan angka tuning; scene/script menjalankan behavior.
- Stable ID tidak boleh berubah ketika file/node diganti nama.
- ID kosong atau duplicate adalah startup/debug error, bukan warning yang diabaikan.
- Jangan menyimpan mutable per-instance state di Resource yang dibagi banyak item. Simpan di inventory slot/world instance.
- ContentCatalog mengurutkan hasil discovery sebelum registrasi agar konsisten antar-OS.

Setiap definition baru minimal mempunyai test bahwa Resource dapat dimuat dan ID terdaftar.

## 8. Item programming

Programmer item hanya boleh bergantung pada:

- `ItemDefinition`
- primary/secondary `ItemBehavior`
- `ItemContext`
- `ItemActionResult`
- `ThrownItem`
- shared reaction contract

Item behavior tidak boleh:

- mencari dan mengubah array inventory,
- mengurangi quantity langsung,
- memeriksa nama enemy scene,
- hardcode UI path,
- menyimpan state instance pada shared Resource.

Alur action:

```text
Input → Inventory meminta behavior
      → behavior validasi context/state
      → behavior mengembalikan result
      → Inventory commit consume/state hanya jika success
```

Throw wajib atomic:

1. Validasi secondary action dan world spawn point.
2. Buat `ThrownItem` memakai copy state satu unit.
3. Pastikan node masuk world dengan sukses.
4. Baru kurangi inventory.
5. Saat pickup, tambah inventory dulu; hapus world item hanya jika berhasil.

Ini mencegah duplikasi dan kehilangan.

### Weight dan action visual

- `ItemDefinition.weight` adalah integer non-negatif yang dibaca inventory, throw, dan impact. Jangan menyimpan salinan weight pada Player.
- Inventory menyediakan satu total quantity × weight; held/prepared item tidak dihitung ulang.
- Player tidak boleh mempunyai branch `if item_id == ...`. Behavior active item memulai action dan memakai held-item anchor yang sama.
- Untuk Multitool, behavior memakai satu reusable hit area/visual child yang dikonfigurasi item. Jangan mempertahankan input `attack`, `SwordHitbox`, timer hardcoded, atau raycast damage lama.
- Karena thrust pertama tidak mempunyai frame animation, sprite/hit shape snap ke full extension, aktif satu durasi exported, lalu kembali. Cleanup death/scene/item-change wajib mematikan shape.
- Satu thrust menyimpan receiver yang sudah diproses dan menyelesaikan hanya satu target menurut urutan fondasi. Jangan membuat combo/buffer framework.

### Throw preview

- Preview memakai perhitungan initial velocity dan gravity yang sama dengan throw sebenarnya, lalu menggambar sample sampai configured visual length.
- Preview tidak melakukan physics query collision. Jangan membuat simulator projectile kedua.
- Weight modifier dihitung satu kali di shared throw path agar preview dan real throw tidak berbeda.
- Temporary heavy comparison item hanya didaftarkan/diberikan melalui debug path; jangan masukkan ke placer/shop normal.

## 9. ThrownItem dan Projectile

Jangan menyatukan keduanya:

- `ThrownItem` adalah item nyata, membawa item ID/state, dapat persistent/pickup.
- `Projectile` adalah serangan sementara, tidak masuk inventory, tidak disimpan.

Keduanya menghasilkan `ImpactData`. Receiver menangani `apply_damage`, `apply_force`, `apply_status`, atau agitation tanpa mengetahui class pengirim.

`WorldItem` dan `ThrownItem` memakai `WorldItemState` yang sama untuk item ID, instance state, quantity, persistent ID, transform, velocity, dan frozen state. Karena root physics Godot berbeda, state dibagi lewat composition, bukan inheritance node.

`ItemDefinition.world_hitbox` adalah `Shape2D` per item. Generic world scenes menerapkan shape tersebut pada `CollisionShape2D`; jika kosong, keduanya memakai fallback circle. Edit field ini langsung pada resource item di Inspector.

Behavior throw yang mengaktifkan efek saat impact mewarisi `impact_activation_speed`. Threshold membaca kecepatan impact aktual. Impact di bawah threshold tidak mengaktifkan efek khusus dan item tetap dapat berhenti serta dipungut.

Moving payload wajib mempunyai source dan species ID. Filter same-species damage berada satu kali di shared damage pipeline, bukan di setiap enemy/projectile.

Multi-hit payload menyimpan receiver ID yang sudah terkena. Default payload berhenti pada hit pertama; jangan menambah penetration logic ke semua projectile.

## 10. Actor dan enemy programming

Enemy memakai enum state kecil:

```gdscript
enum State { IDLE, PATROL, INVESTIGATE, ATTACK, RECOVER }
```

Hanya masukkan state yang benar-benar digunakan enemy tersebut. Jangan membuat base class berisi semua kemungkinan state.

Shared component/contract:

- health/damage/death
- force/knockback
- status receiver
- sight query
- sound listener
- target override
- persistence adapter bila perlu

Enemy script memilih reaksi. Contoh: `hear_sound(event)` pada amphibian mengubah target investigasi; Rattlepod tidak memanggil `Amphibian`.

Attack damage hanya aktif selama telegraph selesai dan hitbox attack aktif. Tidak ada contact damage otomatis.

### Player movement, interaction, dan camera

- Satu controller memiliki timer coyote/buffer, jump cut, ground/air acceleration, dan encumbrance multiplier. Status/item tidak menulis velocity atau exported base value langsung.
- Hitung load ratio dari inventory total: `0` sampai capacity tidak memberi penalty; capacity sampai `2 × capacity` lerp speed/jump ke nol dan fall acceleration ke cap.
- Interaction sensor membuat satu rectangle terrotasi dari pusat collision actor ke clamped cursor, memfilter obstruction, lalu sort cursor distance sebelum priority tie-break. Jangan scan seluruh group atau membiarkan tiap interactable memilih dirinya sendiri.
- Camera tetap satu `Camera2D`. Input look-ahead berasal dari cursor screen-space dengan center deadzone agar camera movement tidak memberi feedback ke cursor world-space. Limit offset, UI return/zoom, smoothing, dan native bounds berada pada owner camera/player yang sama.
- Held-item pivot adalah transform nyata yang dimirror oleh facing player. Jangan menghitung offset virtual berbeda dari posisi sprite/hitbox.
- Semua action player memeriksa alive, inventory/UI ownership, control lock, dan climbing rule sebelum menjalankan behavior.
- Rope extension tetap beberapa `Area2D`, tetapi gameplay membaca root, batas, dan end-cap sebagai satu chain. Area exit satu segment tidak boleh detach; input up/down di ujung hanya berhenti, sedangkan Space adalah input detach. Force, death, load, dan recovery tetap boleh membersihkan climbing state.

### Detection ownership dan biaya

- Producer membuat `SoundEvent` atau menjadi candidate sight; ia tidak memilih enemy.
- Listener memfilter radius, minimum priority, ignored type, sight cone/obstruction, proximity, serta optional sound-over-sight override.
- Enemy script memutuskan state transition. Jangan membuat universal AI controller atau behavior tree.
- Sound tetap immediate group broadcast. Sight/proximity memakai staggered tick sekitar 0,1 detik dan disabled bersama processing enemy yang tidak loaded.
- Simpan last-known position dan timestamps, bukan tracking Node position menembus obstruction.
- Repeat escalation memakai producer identity, tiga event/dua detik sebagai default, dan direct-target mode; jangan membuat synthetic maximum priority.

## 11. Status dan modifier

- Semua effect masuk melalui `StatusController`.
- Definition menentukan duration, refresh/stack rule, maximum stack, tick, dan persistence.
- Player controller membaca modifier hasil agregasi; effect tidak menulis `move_speed` langsung.
- Semua heal melewati health API agar healing multiplier/cap diterapkan.
- Semua throw membaca modifier range/force dari satu query.
- Timer transient seperti stun boleh reset saat load; effect persisten wajib capture/restore remaining duration.

## 12. World dan persistent state

Persistent node contract:

```gdscript
@export var persistent_id: StringName

func capture_state() -> Dictionary:
    return {}

func restore_state(data: Dictionary) -> void:
    pass
```

Aturan:

- ID manual dan terlihat di Inspector.
- Jangan memakai `get_path()` atau nama node sebagai save key.
- Capture hanya data stabil, bukan Node reference, signal, Tween, atau active animation frame.
- Restore harus menerima field lama yang hilang dengan default aman.
- Save schema mempunyai version dan migration/fallback yang eksplisit.
- Write ke temporary file lalu replace save valid.
- Jangan menyimpan projectile sementara.

Deterministic generation memakai seed + stable placer ID. Jangan memakai urutan iterasi directory/dictionary sebagai sumber randomness.

World generation wajib mengikuti `panduan_world_generation.md`:

- randomness section memakai `seed + slot_id`;
- randomness placer memakai `seed + persistent_id`;
- scene pool dan spawn point memakai urutan data authored yang tervalidasi, bukan urutan directory;
- generated object mendapat ID `placer_id:spawn_point_index` sebelum `_ready()`;
- direct child `Marker2D` pada placer menentukan urutan spawn point; jangan mengubah urutannya setelah content freeze;
- runtime object dari player memakai counter run yang disimpan, bukan timestamp atau `randi()`;
- section tidak boleh menentukan global transform sendiri;
- runtime tidak memperbaiki marker buruk dengan ground search; validator harus menolak authoring yang salah;
- player hanya spawn setelah generation dan restore selesai;
- object lintas seam berada pada layer runtime root, bukan section root.

Jangan menambah procedural geometry, constraint solver, atau streaming per-section. Seluruh terrain layer aktif tetap loaded sampai profiler menunjukkan kebutuhan lain.

### Rope runtime contract

- Rope pertama adalah fixed `Area2D`, bukan joints/physics chain.
- Placement memakai normal item-result transaction: validasi penuh, buat preview/node, baru consume satu item.
- Visual memakai native 16×16 `rope_segment` yang diulang/dipotong dan satu `rope_end`; logic panjang tidak membaca opaque pixel.
- Player menyimpan climbing state sementara dan current Rope reference; Rope tidak mengubah Player lewat path parent panjang.
- Knockback meminta detach melalui method/signal yang dimiliki Player, bukan menghapus Rope.
- Placed Rope memakai catch width 24 px, visual scale horizontal 0,5, dan stride 14 px. Climbing left/right memakai velocity collision biasa untuk offset maksimal 8 px; jangan menulis posisi langsung atau teleport melewati terrain.
- Endpoint atas/bawah memilih chain yang sama dan menambah node segment baru dari bottom chain. Extension memakai validasi terrain/bounds yang sama dan normal `ItemActionResult` consumption.
- Hanya root chain masuk `persistent_objects` dan mendapat runtime ID. `capture_state()` menyimpan posisi root serta panjang segment terurut; extension tidak mempunyai ID/save record sendiri.
- `restore_state()` wajib idempotent: hapus extension lama, bangun ulang geometry/collision, sambungkan extension ke root, lalu sisakan satu end-cap terbawah. Restore selalu menaruh chain di runtime root layer asal melalui `SaveManager` yang sudah ada.
- Climbing state tidak persistent. Save saat climbing memakai safe position player. Shop stock dan guaranteed acquisition bukan bagian persistence Rope.

### Lokasi implementasi player foundation

| Sistem | File utama | Data/scene |
|---|---|---|
| Movement, encumbrance, climb | `game/player/player.gd` | `game/player/player.tscn` |
| Camera cursor/bounds | `game/player/player_camera.gd` | child `Camera2D` pada Player |
| Cursor interaction | `core/interaction/interaction_sensor.gd` | child `InteractionSensor` pada Player |
| Item transaction/preview | `game/items/player_item_controller.gd` | `game/player/player_item_preview.gd` |
| Weighted throw | `game/items/behaviors/default_throw_behavior.gd` | `game/items/world/thrown_item.gd` |
| Multitool thrust | `game/items/behaviors/multitool_behavior.gd` | `game/items/actions/held_thrust.tscn` |
| Sight/hearing | `core/sensing/sight_sensor.gd`, `core/sensing/sound_listener.gd` | production enemy pada `game/enemies/layer1/` |
| Effect/status | `core/status/status_controller.gd` | `data/effects/`, `game/items/world/world_effect_area.gd` |
| Ascension Curse | `game/player/curse_tracker.gd` | child runtime milik Player, UI/debug pada `ui/foundation_hud.gd` |
| Layer 1 enemy | `game/enemies/layer1/` | `data/enemies/`, placer pada `game/world/placers/` |
| Rope placement/persistence | `game/items/behaviors/rope_behavior.gd` | `data/items/rope.tres`, `game/items/world/placed_rope.tscn` |
| Integrated graybox | `game/world/foundation_test_room.tscn` | pilih Debug Run lalu Foundation Test Room |

Rope authored anchor optional adalah `Marker2D` dalam group `rope_anchors`. Tanpa marker, behavior mencari solid surface dekat cursor. Debug menu `F3` mempunyai `Show Gameplay Ranges` untuk melihat interaction reach, Multitool shape, sight cone/ray, accepted sound radius, trajectory, dan validitas Rope.

## 13. UI dan control lock

- UI tidak mengubah gameplay state langsung; panggil model/service API.
- Satu owner mengatur control-lock reasons seperti inventory, dialogue, stun, death.
- Gunakan set alasan/token, bukan satu boolean yang dapat dibuka fitur lain secara tidak sengaja.
- Setiap lock mempunyai cleanup pada close, cancel, scene exit, dan error path.
- Gameplay click tidak diproses ketika inventory UI aktif.
- UI harus tetap dapat dipakai dengan placeholder dan tanpa portrait/audio.

## 14. Error handling

Gunakan `assert` untuk invariant developer pada debug build: duplicate ID, missing required child, invalid data definition. Untuk keadaan yang dapat terjadi pada pemain—inventory penuh, save rusak, target invalid—return gagal dan tampilkan feedback; jangan crash.

Function `try_*` harus atomic dan mengembalikan keberhasilan:

```gdscript
if not inventory.try_add_item(item):
    return false
world_item.queue_free()
return true
```

Jangan `queue_free()` sebelum operasi penerima berhasil.

## 15. Test minimum

Logic trivial satu baris tidak membutuhkan test. Logic dengan branch/loop/state/persistence membutuhkan satu runnable check terkecil.

Smoke test fondasi harus memeriksa:

- duplicate/blank content ID,
- stack/overflow/swap,
- primary/secondary rollback,
- throw dan pickup tanpa duplikasi,
- same-species damage filter,
- multi-hit tidak mengenai receiver dua kali,
- status refresh/stack/expire,
- deterministic placer,
- save roundtrip dan corrupt-save fallback,
- control lock selalu terlepas.

Player-foundation check tambahan:

- tap/full jump, coyote, buffer, dan no-double-jump;
- encumbrance boundary pada capacity dan `2 × capacity`;
- Multitool satu utility target atau multi-enemy sekali per target, plus cleanup hitbox;
- cursor clamp, obstruction, dan tie-break interaction;
- preview/real initial velocity memakai weight formula sama;
- sound priority/tie/repeat escalation dan blocked sight memory;
- Rope consume/invalid rollback, endpoint extension, held-input attach, lateral climb/jump, item action saat climb, force detach, layer round-trip, dan Continue tanpa duplicate chain.

Perintah wajib sebelum merge:

```bash
/usr/bin/Godot --headless --path . --editor --quit
/usr/bin/Godot --headless --path . tests/foundation_smoke.tscn
/usr/bin/Godot --headless --path . tests/content_smoke.tscn
```

Jangan menambah test framework sampai assertion runner sederhana tidak lagi cukup.

## 16. Git dan review

- Branch: `feature/<fitur>` atau `fix/<bug>`.
- Commit kecil dan runnable; jangan campur rename besar dengan behavior baru jika dapat dipisah.
- Jangan commit `.godot/`, build, log, atau imported cache.
- Sebelum merge: rebase/update dari main, jalankan test, periksa debugger, lalu minta satu anggota tim mencoba fitur.
- Reviewer memeriksa ownership state, duplicate logic, data tuning, cleanup, save boundary, dan failure path.
- Sebelum player programming, merge `feature/world-generation` ke `feature/player` tanpa rebase branch shared; pertahankan world/persistence fix terbaru.
- Pada merge tersebut hapus tracked `.godot/`, aktifkan kembali ignore `.godot/`, dan pulihkan `texture_region_size`/`tile_size` graybox 16×16. Jangan menyelesaikan conflict generated cache secara manual.
- Pisahkan commit integration/cleanup, asset organization, dan behavior agar teammate dapat review atau revert satu jenis perubahan.

Programmer item tidak mengedit Inventory, Player, SaveManager, atau ContentCatalog kecuali contract terbukti tidak cukup dan perubahan disetujui lead.

## 17. Definition of done per fitur

Fitur selesai hanya jika:

1. Bekerja dari main game, bukan hanya test scene.
2. Tidak menghasilkan repeated debugger error.
3. Placeholder dan asset final dapat ditukar tanpa mengubah logic.
4. Nilai balance dapat diubah tanpa edit code.
5. Pause, death, scene change, save/load ditangani jika relevan.
6. Failure path tidak kehilangan atau menduplikasi item/state.
7. Satu runnable check tersedia untuk logic non-trivial.
8. Satu orang selain pembuat sudah mencoba acceptance case.

## 18. Hal yang sengaja tidak dibuat

- Behavior tree/editor.
- Global event bus.
- Interface/factory dengan satu implementation.
- General-purpose projectile system untuk behavior yang belum ada.
- Procedural terrain.
- Custom test framework.
- Controller support selama P0 belum lengkap.
- Pixel-perfect weapon collision, skeletal/equipment framework, combo system, physics Rope, dan duplicate camera implementation.
- Rope shop stock dan guaranteed acquisition sampai content flow disetujui.

Tambahkan hanya ketika kebutuhan nyata tidak dapat ditangani contract yang sudah ada.

## 19. Urutan implementation player setelah greenlight

Urutan ini wajib agar perubahan world, asset, dan player tidak saling menimpa:

1. Merge `feature/world-generation` ke `feature/player`; bersihkan `.godot/` dan pulihkan TileSet 16×16 dalam commit integration tersendiri.
2. Pindahkan delivered asset sesuai mapping section 2, biarkan Godot membuat import cache lokal, lalu commit asset organization tersendiri.
3. Perbaiki controller movement/animation, variable jump, coyote, buffer, air steering, camera cursor, dan UI zoom tanpa mengubah item behavior.
4. Ganti `InteractionSensor` player-centred dengan query cursor clamp/reach/obstruction dan pertahankan public `interact(actor)` pada target.
5. Hapus jalur `J`/`SwordHitbox`; hubungkan Multitool snap-thrust melalui `primary_action` dan shared damage contract.
6. Tambahkan field/total weight, encumbrance modifier, shared throw calculation, dotted preview, serta satu debug heavy item.
7. Perluas `SoundEvent`/listener secukupnya, tambah sight/proximity scan, lalu buktikan pada test amphibian sebelum enemy lain.
8. Buat dan playtest Rope item-flow, lalu integrasikan root-only persistence/seam setelah disetujui lead; shop tetap tahap content.
9. Tambahkan debug draw melalui menu debug yang ada dan lengkapi integrated graybox/check terkecil.
10. Jalankan clean import, smoke test, representative 60 FPS playtest, dan satu teammate test sebelum commit final player foundation.

Setiap langkah harus runnable sebelum langkah berikutnya. Jangan mencampur asset move, branch conflict resolution, dan gameplay behavior dalam satu commit.
