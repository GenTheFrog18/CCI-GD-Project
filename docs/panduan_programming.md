# Panduan Programming — Delvers of the Abyss

> **Status:** workflow aktif, diaudit 30 Agustus 2026. Arsitektur berada di [`fondasi_teknis_godot.md`](fondasi_teknis_godot.md); behavior content berada di [`implementation/`](implementation/).

## 1. Urutan kerja

Sebelum mengubah code:

1. Baca GDD untuk intent dan implementation contract untuk behavior aktif.
2. Cari owner/caller dengan `rg`; jangan membuat sistem kedua.
3. Jalankan smoke test paling dekat untuk mengetahui baseline.
4. Tentukan scene/Resource owner dan persistence boundary.
5. Periksa worktree; perubahan orang lain tidak boleh ditimpa.

Saat mengubah code:

1. Perbaiki pada shared owner bila semua caller melewati owner tersebut.
2. Gunakan Resource/Inspector untuk tuning yang memang akan diubah designer.
3. Gunakan `call_deferred()`/`set_deferred()` ketika mengubah physics state dari collision callback.
4. Tambahkan satu runnable assertion untuk logic non-trivial.
5. Jangan membuat abstraction untuk satu implementation.

Selesai berarti main flow masih dapat dibuka, tidak ada debugger error baru, save contract aman, dan dokumentasi behavior ikut berubah bila perlu.

## 2. Struktur dan naming

```text
autoload/  ContentCatalog, GameSession, SaveManager, SceneRouter, AudioManager
core/      shared contracts: combat, interaction, items, movement, sensing, status
data/      Resource definitions and content
game/      gameplay scripts/scenes grouped by owner
ui/        menu, HUD, inventory, dialogue, shop
tests/     smoke scenes
assets/    runtime/source assets
```

- File, variable, function, signal, group, dan stable ID: `snake_case`.
- Class: `PascalCase`. Constant: `UPPER_SNAKE_CASE`.
- Function publik memakai verb dan typed return bila menjadi contract.
- Boolean memakai `is_`, `has_`, `can_`, atau `should_`.
- Signal menyatakan kejadian yang sudah terjadi.
- Script berada di dekat scene owner. Hindari folder generic `utils`, `helpers`, atau `managers`.
- Gunakan `class_name` hanya bila type dipakai lintas file/scene.

## 3. Scene, Resource, dan state

- Root scene mengoordinasikan child miliknya.
- Component menyimpan state lokal: health pada `HealthComponent`, status pada `StatusController`, inventory pada `InventoryModel`.
- Parent menghubungkan signal child; hindari path `../../../`.
- Gunakan exported node/resource reference untuk hubungan authored.
- Resource bersama tidak boleh menyimpan mutable per-instance state.
- Collision tidak mengikuti ukuran sprite otomatis. Author shape melalui Resource/scene.
- Runtime node harus mempunyai parent dan cleanup owner yang jelas.

Stable ID adalah save/content contract. Jangan mengganti ID setelah dipakai save tanpa migration/version bump.

## 4. Direct call, signal, dan group

| Situasi | Pilihan |
| --- | --- |
| Caller tahu receiver dan butuh hasil | Direct call |
| Child melaporkan event | Signal |
| Banyak listener tidak dikenal | SceneTree group |
| Run/save/catalog/scene/audio global | Autoload yang ada |

Sound memakai `SoundBus` + group listener. Debug draw memakai `GameSession.debug_draw_changed`. Jangan menambah global event bus.

## 5. Content Resource

`ContentCatalog` scan folder `data/` dan mendaftarkan:

- `ItemDefinition.item_id`;
- `EnemyDefinition.enemy_id`;
- `EffectDefinition.effect_id`;
- `ShopDefinition.shop_id`;
- `DialogueSequence.sequence_id`.

Definition baru wajib mempunyai ID unik, path valid, dan catalog smoke assertion. Scene/resource tuning adalah authority untuk angka balance; dokumen cukup menjelaskan makna dan invariant.

## 6. Item programming

Item action hanya memakai:

- `ItemDefinition`;
- primary/secondary `ItemBehavior`;
- `ItemContext`;
- `ItemActionResult`;
- prepared/world form;
- shared impact/status/sound contract.

Behavior tidak boleh mengubah array inventory, hardcode path HUD, memeriksa nama enemy scene, atau menyimpan state runtime pada shared Resource.

```text
input
  -> PlayerItemController memilih behavior
  -> behavior validasi context/state
  -> behavior mengembalikan ItemActionResult
  -> controller commit hanya bila success
```

World/prepared node harus berhasil masuk tree sebelum consume. Pickup menambah inventory dahulu, lalu menghapus world node. Failure tidak mengubah quantity/state.

Multitool memakai held-item anchor dan reusable thrust area. Jangan menambah attack input atau player weapon framework terpisah.

## 7. Throw dan projectile

`ThrownItem` adalah item nyata dan persistent. `Projectile` adalah attack payload sementara. Jangan menyatukan keduanya.

- Preview dan throw memakai velocity calculation yang sama.
- `ItemDefinition.world_hitbox`/`world_hitbox_scene` menentukan collision.
- Source actor diabaikan oleh payload sendiri.
- Multi-hit menyimpan instance ID receiver yang sudah diproses.
- Impact mengalir melalui `ImpactData`.
- Physics property/monitoring change dari signal collision wajib deferred bila body sudah berada di physics space.

`on_impact()` bekerja pada unit yang sudah berada di dunia; return value tidak membuat inventory commit kedua.

## 8. Combat, effect, dan enemy

Receiver memakai contract kecil: `apply_damage`, `apply_force`, `apply_status`, `resolve_impact`, `interrupt_action`, dan persistence methods bila dibutuhkan.

Shared enemy behavior berada di `EnemySupport`: health, status, same-species filtering, flash, debug label, electric disable, fall damage, dan save. AI state tetap pada enemy script.

Status baru dibuat sebagai `EffectDefinition`. Pilih satu stack rule, persistence, eligibility, tick, modifiers, dan optional additive cap. Area effect harus memberi provider ID agar hanya kontribusinya sendiri yang dihapus saat exit.

Enemy baru minimal:

1. scene root dan script khusus;
2. `EnemyDefinition` + unique ID;
3. `EnemySupport` child;
4. damage/status/force methods yang mendelegasikan ke shared support;
5. telegraph warning untuk serangan berat;
6. neutral restore state setelah Continue;
7. F3 range/body/health support;
8. content smoke assertion.

Gunakan `GroundTraversal2D` hanya untuk grounded actor yang benar-benar perlu route walk/jump/fall. Surface crawler tetap memakai controller normal/tangent yang sudah ada.

## 9. Sensing

- `SightSensor` menangani cone/range/LOS, bukan keputusan AI.
- `SoundEvent` membawa position, radius, type, priority, dan optional entity source.
- `SoundListener` menerima/ranking event; enemy memutuskan response.
- Target player memakai `get_detection_origin()`, bukan kaki.
- `EnemySupport.detectors_enabled()` harus dihormati selama Hushcap/electric suppression.
- Query overlap hanya boleh dilakukan ketika `Area2D.monitoring` aktif.

## 10. World dan persistence

Section template tidak memiliki state run. Manifest memilih section/placer; dynamic state dimiliki runtime object.

Persistent object wajib:

```gdscript
@export var persistent_id := ""

func capture_state() -> Dictionary:
    return {}

func restore_state(data: Dictionary) -> void:
    pass
```

Tambahkan ke group `persistent_objects`. Jangan menyimpan Node, RID, Callable, Tween, atau Resource instance mutable dalam JSON. Simpan ID, angka, boolean, array, dictionary, transform, dan duration.

Object yang hilang permanen harus memanggil `SaveManager.mark_destroyed()`. Save version berubah bila schema lama tidak dapat dibaca aman.

## 11. Dialogue, shop, dan UI

Dialogue content dibuat dari Resource, bukan hardcoded pada NPC script. NPC memilih sequence/trigger; `DialogueController` menjalankan line, choice, condition, action, reward, flag, tutorial, dan close.

Shop transaction berada pada `ShopService`. UI tidak mengubah money/inventory langsung.

Scene UI harus dapat diedit melalui Godot editor. Gunakan anchors/containers untuk struktur dan exported/node layout untuk elemen yang memang perlu dipindah designer. Semua logical UI tetap di canvas 640×360 dan wajib terbaca pada integer output scale.

UI callback yang menyimpan Node harus memakai `is_instance_valid()` sebelum cast/call, karena target enemy/item dapat bebas pada frame berikutnya.

## 12. Audio, debug, dan performance

- Gameplay SFX melalui `AudioManager` bus `SFX`; button/UI melalui `UI`.
- Loop memakai owner dan dihentikan ketika owner invalid.
- Jangan membuat satu AudioStreamPlayer permanent per one-shot.
- Debug draw harus berada di category dan off secara default.
- Query sensor, label refresh, preview, dan section activation boleh di-throttle bila tidak membutuhkan setiap frame.
- Jangan mengaktifkan seluruh gameplay ranges sekaligus untuk testing normal.
- Profiling lebih dulu sebelum membuat cache/framework baru.

## 13. Test

Minimum test sesuai risiko:

- content/ID/resource: `content_smoke`;
- inventory/combat/item/world/save/UI foundation: `foundation_smoke`;
- navigation: `ground_traversal_smoke`;
- visual subsystem: display/background/lighting smoke;
- transaction: shop smoke;
- audio routing: audio smoke;
- NPC contract: gatekeeper smoke.

Run clean import:

```bash
/usr/bin/Godot --headless --path . --editor --quit
```

Run test scene:

```bash
/usr/bin/Godot --headless --path . --scene res://tests/foundation_smoke.tscn
```

Godot dapat menghasilkan leak warning pada exit test. Assertion, parser error, dan runtime error tetap failure walaupun shell exit code kadang tidak mencerminkannya.

## 14. Git dan review

- Branch aktif untuk checkpoint ini adalah `main`.
- Stage seluruh perubahan yang diminta, tetapi jangan menimpa perubahan unrelated milik contributor.
- Commit memakai Conventional Commits dan menjelaskan intent.
- Jangan amend, rebase, force-push, reset, atau checkout perubahan orang lain tanpa permintaan eksplisit.
- `git diff --check` wajib sebelum commit.

Review memeriksa: ownership, duplicate system, save compatibility, deferred physics mutation, stable IDs, cleanup freed nodes, test coverage, dan dokumentasi behavior.

## 15. Hal yang sengaja tidak dibuat

- global event bus;
- universal enemy behavior tree/base state machine;
- satu class physics untuk world item dan projectile;
- dynamic terrain generation;
- custom camera framework;
- custom localization/mod/network framework sebelum fitur tersebut disetujui.
