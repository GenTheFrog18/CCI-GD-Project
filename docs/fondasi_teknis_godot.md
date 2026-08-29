# Fondasi Teknis Godot — Delvers of the Abyss

> **Status:** kontrak teknis aktif, diaudit terhadap branch `main` pada 30 Agustus 2026.
>
> Dokumen ini menjelaskan arsitektur yang benar-benar dipakai project. Intent player-facing tetap berasal dari [`gdd_en.md`](gdd_en.md). Nilai balance berada pada Resource dan Inspector; dokumen ini hanya mengunci ownership, alur data, dan invariant.

## 1. Batas implementasi saat ini

- Build normal dimulai di Surface, memainkan Layer 1, lalu selesai ketika gate menuju Layer 2 dipakai.
- Layer 2 mempunyai scene, enemy, relic, shop, Curse, dan world-generation foundation, tetapi belum menjadi content yang dijanjikan sebagai playable build saat ini.
- `Layer3Entrance` dan validasi Layer 3 masih ada sebagai code legacy dari build jam. Keduanya bukan komitmen desain aktif.
- Terrain dibuat manual. Randomness hanya memilih variation section dan hasil placer secara deterministic dari seed.
- Project adalah single-player dan tidak mempunyai network, mod API, atau controller support aktif.

Jika code dan dokumen ini berbeda, periksa GDD terlebih dahulu. Perbedaan yang tidak disengaja adalah bug; jangan mengubah dokumen agar bug terlihat sebagai desain.

## 2. Konfigurasi project

| Bagian | Kontrak aktif |
| --- | --- |
| Engine | Godot 4.7.1, GDScript |
| Main scene | `res://ui/main_menu.tscn` |
| Renderer | Compatibility |
| Design viewport | 640×360 |
| Window default | 1280×720 |
| Stretch | `canvas_items`, aspect `keep`, integer scale |
| Pixel art | Nearest filtering; transform dan vertex pixel snapping dimatikan agar camera tidak menyentak |
| Physics scale | 32 px per metre |
| Terrain layer | Physics layer 1, `World` |

Physics layer yang diberi nama adalah `World`, `Player`, `Enemy`, `WorldItem`, `PlayerPayload`, `EnemyPayload`, `Interactable`, `Sensor`, dan `SightObscurer`. Layer 10 dipakai sebagai boundary/blocker khusus pada beberapa encounter.

## 3. Struktur repository dan ownership

```text
autoload/              service global
core/                  contract lintas subsystem
data/definitions/      schema Resource
data/items|enemies|effects|shops|dialogue/
                       content Resource
game/player/           controller dan presentation player
game/items/            behavior dan world form item
game/enemies/          AI per enemy dan shared enemy support
game/world/            layer, section, placer, lighting, gate
game/npcs/             NPC dan interaction owner
ui/                    menu dan HUD
tests/                 smoke scene berbasis assert
assets/                runtime art, audio, font, dialogue source
docs/                  design, technical contract, authoring guide
```

Aturan ownership:

- Root scene mengoordinasikan child scene miliknya.
- `Resource` menyimpan identity, asset reference, dan tuning; node menyimpan state runtime.
- `core/` hanya untuk contract yang sudah dipakai lebih dari satu subsystem.
- Stable ID tidak berasal dari nama node atau nama file.
- Jangan menambah manager, event bus, base AI, atau framework kedua bila contract yang ada cukup.

## 4. Runtime global

Project memakai lima Autoload:

| Autoload | Tanggung jawab |
| --- | --- |
| `ContentCatalog` | Scan dan validasi item, enemy, effect, shop, dan dialogue Resource; lookup berdasarkan stable ID. |
| `GameSession` | State run/meta ringan, money, whistle, manifest, location, display settings, input map, debug flags, runtime ID. |
| `SaveManager` | Meta/run JSON, atomic write, destroyed IDs, persistent object capture/restore, cross-layer transfer. |
| `SceneRouter` | Pergantian main scene dengan guard terhadap transition ganda. |
| `AudioManager` | SFX/UI playback, loop ownership, random attack variant, dan routing bus. |

Autoload tidak memiliki AI, projectile, HUD, world node, atau mutable item instance. `AudioManager` memakai bus `SFX` dan `UI`; master-volume setting diterapkan melalui AudioServer.

## 5. Run, world, dan transition

Alur New Run:

```text
MainMenu
  -> GameSession.start_new_run(seed, debug options)
  -> WorldGenerator.build_manifest()
  -> instantiate Surface
  -> restore persistent objects
  -> spawn Player + FoundationHUD
  -> atomic run save
```

`WorldGenerator` membangun manifest untuk Layer 1 dan Layer 2 sebelum gameplay. Manifest menyimpan `world_revision`, seed, section variation terpilih, hasil placer, dan generation log. Continue memakai manifest tersimpan; layout dan loot tidak di-roll ulang.

`WorldRun` hanya menginstansiasi layer aktif. Transition menangkap state layer lama, membuat destination, memulihkan object, menempatkan player pada spawn aman, lalu menyimpan. Surface adalah authored hub; layer procedural-section memakai `WorldLayer`, `WorldSlot`, dan `WorldSection`.

Terrain seluruh layer aktif tetap loaded. Section player dan tetangga relevan menentukan processing AI dan camera bounds. Dynamic object hidup di `runtime_root`, bukan di section template.

## 6. World generation dan placer

Layer generated saat ini mempunyai enam fixed slot: west/east pada depth 01–03. Setiap slot memilih satu `WorldSection` variation menggunakan seed dan weight.

`DeterministicPlacer` mempunyai:

- `persistent_id`, `spawn_chance`, `minimum_quantity`, `maximum_quantity`;
- weighted `WorldSpawnEntry` berisi `content_id`, scene, dan weight;
- satu atau lebih child `Marker2D` sebagai SpawnPoint;
- optional allocation group, spawn/attack group, facing, patrol bounds, dan loot scatter.

Quantity boleh lebih besar daripada jumlah SpawnPoint. Setiap hasil memilih point dengan replacement, sehingga beberapa hasil boleh muncul dari marker yang sama. Persistent ID memakai `placer:point` dan suffix occurrence untuk menjaga setiap hasil unik.

Allocation group memilih maksimal satu placer pemenang dari selected sections. `required_allocation` memaksa pemenang terpilih untuk resolve aktif; optional group masih tunduk pada chance pemenangnya.

Placer menyuntik property hanya bila node hasil spawn mempunyai property tersebut. Preset scene menentukan tipe content; tidak ada registry placer kedua.

## 7. Persistence

Save terbagi dua:

- `user://meta_save.json`, version 1: setting dan meta progression.
- `user://run_save.json`, version 4: session, manifest, persistent object, destroyed ID, dan extra world state.

Write memakai temporary file lalu rename atomic dengan backup sementara. Save dengan version salah atau JSON invalid ditolak.

Node persistent masuk group `persistent_objects`, menyediakan `persistent_id`, `capture_state()`, dan `restore_state()`. Save juga menyimpan scene path dan layer ID agar object dinamis dapat dibuat kembali. `SaveManager.mark_destroyed()` mencegah object yang sudah diambil, pecah, atau mati muncul lagi.

State durable meliputi inventory, player/status, world item, Rope, enemy health/status/position, carried frog item, flock/flyer state khusus, dan progression flag. Telegraph, target pointer, animation frame, path sementara, dan provider-area effect tidak disimpan.

## 8. Player, input, dan UI lock

Input map dibuat oleh `GameSession` saat startup:

| Input | Action |
| --- | --- |
| A/D atau panah kiri/kanan | Gerak |
| Space | Lompat |
| W/S atau panah atas/bawah | Rope |
| E | Interaksi |
| Tab | Inventory |
| 1/2 atau wheel | Hotbar |
| Klik kiri/kanan | Primary/secondary item |
| Esc | Cancel/pause/close dialogue |
| F3 | Debug |
| F11 | Fullscreen |

`PlayerController` memiliki movement, fall damage, Rope climbing, interaction query, sound emission, combat receiver, status, Curse, inventory controller, camera, hit flash, dan save state. `detection_origin_offset` menempatkan sumber/target sight dan sound di kepala dan dapat diedit pada scene player.

`ControlLocks` menyimpan lock berdasarkan owner/reason. Dialogue default tidak menghentikan gerak, tetapi memblokir inventory; sequence dapat meminta gameplay lock. Inventory memperlambat player namun tidak menghentikan world simulation.

Camera memakai native `Camera2D` smoothing/limits dan cursor offset. UI memakai logical 640×360 root, sementara text tetap dirender pada output native agar terbaca.

## 9. Inventory dan item action

`InventoryModel` memiliki dua hotbar slot dan lima backpack slot. `ItemStack` menyimpan `item_id`, quantity, dan dictionary state. Stack kompatibel harus mempunyai ID, state, dan origin yang sama.

Action flow:

```text
PlayerItemController
  -> pilih primary/secondary ItemBehavior
  -> buat ItemContext
  -> behavior validasi dan membuat ItemActionResult
  -> controller commit quantity/state hanya setelah success
```

`ItemActionResult` membawa success, consume count, next state, optional world/prepared node, feedback, dan sound request. Behavior tidak boleh mengedit array inventory langsung.

Prepared item adalah unit nyata yang sudah dipindahkan dari inventory. Cancel mengembalikan state unit yang sama bila memungkinkan. Item change, inventory/shop, save, death, atau scene exit wajib membersihkan prepared action.

Weight dihitung dari quantity × `ItemDefinition.weight`. Encumbrance memengaruhi movement, jump, gravity, throw, dan UI melalui contract bersama. Nilai final tetap berada pada item Resource dan player scene.

## 10. World item, throw, dan projectile

- `WorldItem` adalah pickup static/frozen.
- `ThrownItem` adalah item inventory nyata berbasis `RigidBody2D`; membawa definition, instance state, source, velocity, hit history, dan persistence.
- `PreparedRelic`/`PreparedLayer2Relic` adalah active world form item.
- `Projectile` dan `ThornNeedle` adalah payload serangan sementara dan tidak masuk inventory/save.

`WorldItemState` membagi serialisasi dan hitbox lookup antara world item dan thrown item tanpa memaksakan inheritance node physics yang salah.

Thrown item menjadi pickup setelah berada di bawah `stop_speed` selama `stop_seconds`. Loot dari breakable memakai static pickup segera dan scatter area authored. Silver Weight memakai intermediate damaged ID saat masih di dunia, lalu berubah ke damaged inventory ID ketika diambil.

Impact hook tidak melakukan commit inventory kedua. Lifecycle kompleks harus selesai pada world node/behavior yang sudah memiliki unit tersebut.

## 11. Combat dan status

`ImpactData` adalah jalur bersama untuk damage, force, status, source attribution, dan hit filtering. Receiver menyediakan method yang dibutuhkan seperti `apply_damage`, `apply_force`, `apply_status`, atau `resolve_impact`.

`HealthComponent` menolak damage invalid, same-species damage, dan hit setelah mati. `DamageInfo.causes_hit_reaction` membedakan direct hit dari status tick. Player flash dua kali untuk direct hit dan sekali untuk tick; enemy flash sekali dengan duration milik `EnemySupport`.

`EnemySupport` membuat health, status, hit flash, debug health/effect label, persistence, detector suppression, electric interruption, dan disabled-flight fall damage. Enemy tetap memiliki state machine sendiri; tidak ada behavior tree bersama.

`StatusController` menyimpan satu atau lebih application per effect. Rule berasal dari `EffectDefinition`:

- `REFRESH`, `STACK`, `REPLACE`, atau `IGNORE`;
- provider ID mengganti kontribusi provider yang sama;
- `additive_duration_cap` menambah remaining duration sampai cap;
- multiplier digabung multiplicative;
- hanya effect `persists` masuk run save.

Status tick melewati physical invulnerability, tidak membuat force, dan memakai `causes_hit_reaction = false`.

## 12. Sensing dan threat feedback

`SightSensor` melakukan range/cone/line-of-sight query terhadap detection origin target. `SoundEvent` menyimpan position, radius, type, priority, dan optional entity source. `SoundBus` broadcast melalui group; `SoundListener` menilai direct/nearby event dan memory.

Hushcap memberi `detector_suppressed`; enemy tidak memperbarui sight/sound selama suppression. Dazzled juga mematikan sight melalui modifier. Enemy-specific AI menentukan apakah sound menjadi investigate point, distraction, atau attack trigger.

Telegraphed enemy memanggil warning player. HUD menampilkan satu warning icon dan pointer 360° per valid source. Pointer dibersihkan bila source bebas, attack selesai, atau node sudah invalid.

## 13. Enemy architecture

`EnemyDefinition` adalah identity/tag/default-stat authority. Scene root memiliki exported movement, range, timing, damage, dan state khusus. `EnemySupport` membaca health/tag dari definition saat ready, sehingga Resource menang atas duplicate value pada support scene.

Gunakan contract bersama untuk damage/status/sensing/save/debug, tetapi pertahankan AI khusus pada script enemy. Ground enemy yang memerlukan lintasan kompleks dapat opt-in ke `GroundTraversal2D`; surface crawler seperti Spider dan Snail memakai surface-normal controller sendiri.

Enemy placer menetapkan persistent ID, spawn position, facing, patrol data, dan coordination group bila property tersedia. Bird nest dan large flyer memakai placer khusus. Sky Hunter memakai flock owner khusus dan bukan ordinary placer child.

Detail player-facing tiap enemy berada di [`enemy_implementation_handoff.md`](enemy_implementation_handoff.md) dan contract per layer di [`implementation/`](implementation/).

## 14. Ground traversal

`GroundTraversalCache2D` dibangun per `WorldSection` dari collision terrain dan dibagi oleh actor pada section itu. `GroundTraversal2D` memilih route walk/jump/fall sesuai movement profile, lalu menggerakkan `CharacterBody2D` melalui route tersebut.

Traversal bersifat opt-in. Enemy boleh fallback ke movement lokal ketika route tidak ada atau terhalang sementara. Dynamic obstacle tidak membangun ulang graph. Debug category `pathfinding` menggambar sample, edge, route, dan target yang relevan.

## 15. Dialogue, shop, dan narrative state

Dialogue memakai `DialogueSequence`, `DialogueStep`, `DialogueLine`, `DialogueChoice`, `DialogueCondition`, dan `DialogueAction`. `DialogueController` adalah owner runtime UI dan progression action; `DialogueInteractable` adalah adapter NPC/world.

Sequence dapat memakai line sederhana, step/choice bercabang, condition item/flag, item exchange, reward, tutorial open, nested sequence, one-shot flag, dan optional gameplay lock. Escape menutup dialogue. NPC menentukan first encounter, proximity, trespass, atau repeat interaction melalui progression flags; HUD tidak menyimpan narrative state.

Shop memakai `ShopDefinition` + `ShopService`; UI hanya menampilkan row dan confirmation. Money berada pada `GameSession`, transaksi memeriksa inventory dan balance sebelum commit.

## 16. Curse

`CurseTracker` mengukur ascent dari deepest reference memakai koordinat world Y. Crossing threshold memberi package sesuai active layer. Rest, safe zone, transition, dan out-of-bounds recovery mengatur reference/grace berdasarkan contract Curse.

Warning muncul pada 70% threshold, bertahan selama gerak naik, lalu hilang setelah delay ketika player berhenti atau setelah Curse diterapkan. Numbing Pill memberi suppression; crossing tetap dikonsumsi dan mengurangi suppression duration.

State tracker dan persistent effects disimpan. Detail tetap berada di [`implementation/ascension_curse.md`](implementation/ascension_curse.md).

## 17. Lighting dan background

`DarknessRegion2D` adalah polygon world-space yang boleh melampaui layer bounds. `DarknessMaskBuilder` merasterisasi region ke texture mask. `WorldLightingController` membuat satu screen overlay, mengirim inverse world-to-screen transform, dan mengelola maksimum light source yang diexport.

`LightSource2D` mendaftarkan posisi/radius/intensity. Sunsphere dan light actor memakai contract yang sama. Darkness tetap menempel pada world; overlay mengikuti viewport hanya sebagai presentation surface.

Layer 1 dan Surface mempunyai controller background camera-space dengan parallax kecil. Section/depth memilih texture; transition mulai sebelum boundary dan cross-fade berdasarkan distance/duration exported.

## 18. Audio dan display

Semua gameplay SFX masuk bus `SFX`; button/UI masuk `UI`; master slider mengubah `Master`. `AudioManager` menurunkan gain source yang memang keras dan membersihkan owned loops ketika owner invalid.

Display settings disimpan di meta save. Windowed resolution hanya memakai preset integer 640×360; fullscreen borderless. Jangan mengaktifkan transform pixel snapping lagi karena menimbulkan motion sickness pada camera movement.

## 19. Debug dan test room

F3 main menu membuka custom-world builder untuk memilih satu variation per enam Layer 1 slot; player tetap mulai di Surface. F3 gameplay memakai collapsible groups untuk effects, health, teleport, world generation, dan gameplay ranges.

Gameplay range draw dibagi category agar debug tidak menurunkan performance sekaligus: `enemy_ranges`, `placer_ranges`, `sight_ranges`, `sound_ranges`, `interaction_ranges`, `combat_hitboxes`, `item_debug`, `pathfinding`, `enemy_labels`, dan `player_debug`. World-bounds draw mempunyai toggle terpisah. Flag disimpan pada `GameSession` dan tetap aktif walau panel F3 ditutup.

`foundation_test_room.tscn` dapat dijalankan langsung, bootstrap placer/world service, dan memberi editor-exposed Curse profile. Test scene production berada di `tests/`.

Command utama:

```bash
/usr/bin/Godot --headless --path . --editor --quit
/usr/bin/Godot --headless --path . --scene res://tests/foundation_smoke.tscn
/usr/bin/Godot --headless --path . --scene res://tests/content_smoke.tscn
```

Smoke tambahan mencakup audio, display, gatekeeper, ground traversal, background, lighting, dan shop. Assertion gagal harus dianggap test failure walaupun process exit behavior Godot berbeda antar scene.

## 20. Known implementation boundaries

- Layer 2 foundation belum berarti Layer 2 content selesai atau masuk normal progression.
- Layer 3 entrance/validator adalah legacy code dan tidak boleh dipakai untuk memperbesar scope tanpa keputusan GDD baru.
- Controller, localization pipeline lengkap, modding, multiplayer, dan procedural terrain belum diimplementasikan.
- `foundation_smoke`, `content_smoke`, dan `ground_traversal_smoke` mempunyai assertion/runtime failure sebelum audit dokumentasi ini. Foundation suite tetap mencetak `FOUNDATION_SMOKE_OK` dan exit 0 walau beberapa assertion gagal, jadi marker/exit code saja tidak cukup. Perbaikan runtime/test berada di task terpisah.
- Audio dan sebagian asset masih temporary sesuai GDD.

## 21. Definition of done teknis

Perubahan gameplay selesai bila:

1. menggunakan owner dan contract yang sudah ada;
2. nilai tuning berada di Resource/Inspector;
3. stable ID dan persistence tetap valid;
4. tidak menambah debugger error berulang;
5. mempunyai satu smoke/assertion untuk logic non-trivial;
6. diuji dari clean import dan main flow;
7. memperbarui contract implementation terkait bila behavior player-facing berubah.
