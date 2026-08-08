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
```

Letakkan script di samping scene pemiliknya. Jangan membuat folder `utils/`, `managers/`, atau `helpers/` sebagai tempat code tanpa owner. Helper satu fitur tetap bersama fitur tersebut; pindahkan ke `core/` hanya setelah dipakai minimal dua subsystem nyata.

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

## 9. ThrownItem dan Projectile

Jangan menyatukan keduanya:

- `ThrownItem` adalah item nyata, membawa item ID/state, dapat persistent/pickup.
- `Projectile` adalah serangan sementara, tidak masuk inventory, tidak disimpan.

Keduanya menghasilkan `ImpactData`. Receiver menangani `apply_damage`, `apply_force`, `apply_status`, atau agitation tanpa mengetahui class pengirim.

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

Perintah wajib sebelum merge:

```bash
/usr/bin/Godot --headless --path . --editor --quit
/usr/bin/Godot --headless --path . tests/foundation_smoke.tscn
```

Jangan menambah test framework sampai assertion runner sederhana tidak lagi cukup.

## 16. Git dan review

- Branch: `feature/<fitur>` atau `fix/<bug>`.
- Commit kecil dan runnable; jangan campur rename besar dengan behavior baru jika dapat dipisah.
- Jangan commit `.godot/`, build, log, atau imported cache.
- Sebelum merge: rebase/update dari main, jalankan test, periksa debugger, lalu minta satu anggota tim mencoba fitur.
- Reviewer memeriksa ownership state, duplicate logic, data tuning, cleanup, save boundary, dan failure path.

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

Tambahkan hanya ketika kebutuhan nyata tidak dapat ditangani contract yang sudah ada.
