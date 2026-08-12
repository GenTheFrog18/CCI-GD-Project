# Fondasi Teknis Godot — CCI GD Project

**Status:** keputusan fondasi, world generation, dan player dikunci berdasarkan questionnaire 7–12 Agustus 2026.

Dokumen ini adalah sumber kebenaran teknis. Dokumen di `docs/reference/` adalah arsip desain lama; jika bertentangan, dokumen ini menang. Aturan penulisan code ada di `docs/panduan_programming.md`.

## 1. Konfigurasi project yang dikunci

| Bagian | Keputusan |
| --- | --- |
| Engine | Godot 4.7.1, GDScript |
| Renderer | Compatibility |
| Viewport internal | 640×360 |
| Window awal | 1280×720 |
| Texture filtering | Nearest |
| Skala dunia | 32 px per metre |
| Ukuran item art saat ini | 16×16 px; tidak mengubah skala dunia |
| Section | 1280×800 px atau 40×25 m |
| Layer | Dua route 1280 px × tiga section vertikal; total 2560×2400 px |
| Rope | 160 px atau 5 m |
| Target build pertama | Linux |
| Input | Keyboard dan mouse; controller di luar scope jam |

Ukuran map masih boleh di-playtest, tetapi angka di atas menjadi kontrak sementara untuk collision, camera, dan art. Perubahan harus diputuskan lead dan dilakukan serentak; programmer tidak boleh memilih skala sendiri per scene.

Player memakai sprite 32×32 px. Item boleh memakai sprite 16×16 px pada world yang sama. Texture size tidak menentukan collision atau skala dunia. Pertahankan nearest filtering, pivot bottom-centre, dan gunakan integer scale jika sprite perlu diperbesar.

Layer 0 adalah satu authored surface hub. East dan west adalah rute vertikal terpisah pada Layer 1 dan Layer 2. Kedua sisi terhubung hanya pada bagian bawah tiap layer.

## 2. Prinsip arsitektur

```text
Input primary/secondary
        ↓
Player → Inventory → ItemBehavior
                    ├→ world effect
                    ├→ ThrownItem (item nyata)
                    └→ ItemActionResult → inventory commit

Enemy attack → Projectile (serangan sementara)

ThrownItem/Projectile/attack
        ↓
ImpactData → damage + force + status + agitation
        ↓
Actor shared reactions
```

- Gameplay memakai contract bersama, bukan pengecekan nama item/enemy.
- Item behavior boleh mengubah dunia, tetapi tidak boleh mengubah inventory langsung.
- Inventory commit hanya setelah action atau spawn berhasil.
- Gunakan signal lokal untuk one-to-one/parent-child dan group untuk broadcast seperti sound.
- Tidak ada global event bus atau behavior tree.
- Semua nilai balance yang akan berubah berada di Resource/Inspector.
- Stable ID tidak boleh berasal dari nama node.

## 3. Runtime global

Maksimum empat Autoload untuk scope saat ini:

- `GameSession`: seed, uang, whistle tier, delivery, knowledge, New Game, death, dan ending.
- `SaveManager`: meta/living-run save, validasi, atomic write, dan fallback.
- `ContentCatalog`: menemukan Resource, mengurutkannya, memvalidasi type/ID, dan menyediakan lookup.
- `SceneRouter`: menu/gameplay/death/ending transition.

Jangan menambah `AudioManager` sekarang. Gunakan bus `Master`, `Music`, `SFX`, `UI` dan AudioStreamPlayer milik scene.

## 4. Input dan action item

### Control map

| Input | Action |
| --- | --- |
| A/D atau panah | Gerak horizontal |
| Space | Lompat |
| E | Pickup, shop, gate, dialogue, dan interaksi umum |
| Tab | Buka/tutup inventory |
| 1/2 atau mouse wheel | Pilih hotbar |
| Klik kiri | `primary_action` item aktif |
| Klik kanan | `secondary_action` item aktif |
| Esc | Pause/cancel |

Semua action item pada build jam dipicu dengan satu kali press. Tidak ada hold/release contract sampai item final benar-benar membutuhkannya. Primary dan secondary action diblokir selama inventory terbuka. Inventory memperlambat player, tetapi enemy, status, projectile, dan dunia tetap berjalan.

### Primary dan secondary action

- Setiap item mempunyai primary dan secondary behavior sendiri.
- Default secondary behavior ordinary item/artifact adalah throw.
- Item dapat menonaktifkan atau mengganti secondary behavior melalui definition.
- Multitool mengganti throw dengan secondary action yang belum didesain. Untuk sekarang action tersebut disabled dan memberi feedback singkat.
- Supply seperti Bandage/Rope/Pill dapat mengganti secondary behavior setelah playtest tanpa mengubah Inventory atau Player.
- Drop dari inventory adalah context action terpisah.
- Throw dengan cursor sangat dekat menghasilkan lemparan pendek yang berfungsi seperti drop, tetapi tetap melewati throw behavior.
- Mengaktifkan item dan melemparkannya adalah dua action terpisah. Item yang memerlukan aktivasi menyimpan active state pada instance.

Contract behavior:

```gdscript
can_primary(context, state) -> bool
primary(context, state) -> ItemActionResult
can_secondary(context, state) -> bool
secondary(context, state) -> ItemActionResult
on_thrown(thrown_item, context, state) -> void
on_impact(thrown_item, impact) -> ItemActionResult
```

`ItemActionResult` berisi `success`, `consume_count`, `next_state`, dan feedback. `ItemContext` berisi actor, world, cursor position, dan interaction target.

### Interaction berbasis cursor

- `E` memilih kandidat di area 16 px sekitar titik cursor yang sudah di-clamp ke radius 72 px dari player; kedua angka diexport untuk tuning.
- Kandidat diurutkan berdasarkan `interaction_priority` tertinggi, lalu jarak terdekat ke titik query cursor.
- Terrain solid di antara player dan kandidat membatalkan target. Target di balik dinding tidak menampilkan prompt dan tidak dapat diinteraksi.
- Cursor di luar reach tetap mengarahkan query ke batas reach, bukan membuat target otomatis invalid.
- Foundation memakai prompt yang sudah ada. Glow/highlight sprite ditunda sampai treatment art disepakati.

### Camera berbasis cursor

- Camera target memakai vector world-space player→cursor yang di-clamp dengan limit horizontal/vertical terpisah. Default awal tetap sekitar 56 px horizontal dan 28 px vertical; keduanya diexport.
- Native `Camera2D` limit dan smoothing tetap menjaga view di bounds route/layer. Jangan membuat camera framework kedua.
- Saat inventory/pause/UI mouse aktif, camera ease kembali ke base player offset dan zoom sedikit ke player. Zoom dan smoothing diexport.
- Git history adalah backup implementasi lama; tidak ada duplicate script, runtime toggle, atau folder backup.

## 5. Inventory dan kepemilikan item

- Lima backpack slot dan dua hotbar slot adalah tujuh slot terpisah.
- Click-to-swap memindahkan stack; tidak membuat reference/duplikat.
- Pickup menggabungkan stack kompatibel, lalu mengisi hotbar kosong, lalu backpack kosong.
- Slot menyimpan `item_id`, quantity, dan `instance_state`.
- Item hanya stack jika ID dan state kompatibel. Item aktif/stateful dipisah menjadi quantity satu; state default/tenang boleh stack.
- Drop manual tersedia melalui inventory context action.
- Item biasa boleh hilang di jurang/out-of-bounds.
- Important item juga boleh hilang hanya jika ada recovery/replacement yang pasti.
- Semua item yang berasal dari player dan masih berada di dunia harus masuk living-run save, termasuk ordinary rock.
- Setiap `ItemDefinition` nantinya mempunyai integer `weight >= 0`. Inventory menghitung total quantity × weight satu kali; active/held item tetap berada dalam inventory total dan tidak dihitung lagi.
- Carry capacity adalah soft threshold. Tidak ada penalty sampai capacity; dari capacity sampai dua kali capacity, move speed dan jump strength turun linear sampai nol. Falling acceleration naik pada rentang yang sama sampai cap yang diexport.
- Weight hanya mengubah maximum move speed, jump launch strength, dan falling acceleration. Ground/air acceleration, steering, dan knockback tidak berubah.
- UI weight, nilai balance final, dan revisi fall damage ditunda ke tahap item/playtest. Fall-damage code yang ada tidak didesain ulang pada foundation player ini.

### Multitool

Multitool adalah item biasa, bukan equipment slot khusus:

- Diberikan satu pada New Game.
- Dapat dipindah backpack↔hotbar, dikeluarkan, ditinggalkan, hilang, dan dicuri.
- Tidak stack dan tidak dapat dijual.
- Hanya dicuri jika player tidak mempunyai item ordinary lain. Whistle berada setelah Multitool dalam urutan fallback pencurian.
- Kehilangan pertama dalam satu run mendapat satu pengganti gratis di surface.
- Pengganti berikutnya dibeli dari surface shop; harga masih nilai balance.
- Primary action: thrust/tool use ke arah cursor dari held-item pivot. Multitool memakai sprite terpisah; tidak memerlukan attack sprite-sheet player.
- Saat primary ditekan, sprite mengunci arah cursor, snap ke full extension, aktif selama durasi pendek yang diexport, lalu kembali. Player tetap dapat bergerak dengan multiplier lebih rendah dan dapat memakai action di udara tanpa mengubah velocity vertical.
- Shape collision yang di-author mengikuti ukuran visual Multitool dan berotasi bersama sprite; tidak ada pixel-perfect collision atau cursor hitscan.
- Satu thrust menyelesaikan tepat satu target dalam urutan: special Multitool interaction, breakable/harvestable, lalu damage target. Target yang sama tidak dapat diproses dua kali dalam satu thrust.
- Press tambahan selama recovery diabaikan. Damage biasa tidak membatalkan thrust; death, scene exit, atau kehilangan active item membatalkannya dan selalu mematikan hitbox.
- Player tidak mempunyai input `attack` terpisah atau `SwordHitbox` khusus. Semua use masuk melalui active item `primary_action`.
- Secondary action: belum didesain dan disabled untuk sekarang; Multitool tidak menggunakan fallback throw.

### Frog theft

Frog memindahkan satu unit/item instance—tidak clone—dengan prioritas active item, hotbar, lalu backpack. Jika tidak ada ordinary item, Multitool dapat dicuri; jika Multitool juga tidak ada, whistle dapat dicuri. Satu hit/impact membuat frog menjatuhkan carried item tanpa wajib mati.

## 6. ThrownItem dan Projectile

Keduanya sengaja terpisah:

| Jenis | `ThrownItem` | `Projectile` |
| --- | --- | --- |
| Asal | Inventory/world item nyata | Enemy/attack membuat serangan sementara |
| Membawa `item_id`/state | Ya | Tidak wajib |
| Dapat pickup | Sesuai definition | Tidak |
| Persistent | Jika berasal dari player | Tidak |
| Ammo enemy jam build | Tidak digunakan | Tidak terbatas, memakai cooldown |

Keduanya memakai `ImpactData` yang sama:

- `source_actor`
- `source_species_id`
- `base_damage`
- `mass`
- `velocity`
- `damage_multiplier_min/max`
- `force`
- status effects
- agitation data
- terrain response
- penetration/hit limit

Damage dan knockback memakai base damage/mass payload dikali velocity multiplier yang di-clamp. Thrower hanya menentukan initial velocity.

### Weight, power, dan trajectory preview

- Cursor distance tetap menentukan strength tanpa menambah hold/release input.
- Initial throw speed berasal dari base throw power yang diexport lalu dikurangi dengan kurva sederhana `1 / sqrt(max(weight, 1))`; minimum/maximum speed tetap di-clamp.
- Satu integer item `weight` dipakai untuk inventory burden, throw distance, impact mass, dan rigid-body mass pada scope jam. Item-specific base power/impact behavior hanya ditambah bila item nyata memerlukannya.
- Dotted parabolic preview tampil setiap kali item di tangan dapat dilempar, baik instance sudah diaktifkan maupun belum.
- Panjang preview awal sekitar 1,5 tinggi player atau 48 px dan diexport. Preview hanya petunjuk visual dari velocity/gravity; tidak memprediksi collision terrain atau dynamic body.
- Debug menu menyediakan satu temporary heavy item untuk membandingkan hasilnya dengan Throwable Rock. Item tersebut tidak masuk normal loot/economy.
- Throw action mengirim sound event dari player. Impact item boleh mengirim event terpisah dari titik benturan melalui behavior item.

### Collision rules

- Projectile default berhenti pada collision valid pertama.
- Penetration/multi-hit adalah data/behavior khusus; Silver Weight dapat mengenai beberapa enemy dan wajib menyimpan hit history.
- Moving payload tidak bertabrakan satu sama lain pada prototype.
- Terrain response ditentukan per payload: `STOP`, `BOUNCE`, `STICK`, `BREAK`, atau `DISAPPEAR`.
- Enemy projectile tidak dapat diambil player.
- Enemy projectile mengincar posisi player saat telegraph dimulai, tanpa prediction.
- Source actor diabaikan agar tidak terkena projectile sendiri saat spawn.
- Enemy dapat merusak enemy dari species berbeda, tetapi tidak memberi damage pada species yang sama. Gunakan `species_id`, bukan nama scene.
- Force/agitation boleh tetap diterima walaupun damage same-species ditolak jika payload mengaturnya.
- Damage, force, status, dan agitation memakai satu impact pipeline; theft tetap behavior khusus.

## 7. Actor, combat, status, dan sensing

### Combat

- Semua enemy dapat mati ketika health mencapai nol.
- `damageable` dan `killable` tetap terpisah agar object non-enemy dapat menerima impact.
- Tidak ada contact damage global. Damage hanya dari hitbox attack aktif.
- Player mendapat i-frame damage singkat tetapi tetap menerima force.
- Hit tidak membatalkan item action, interaction, climbing, atau Bandage healing.
- Fall damage berdasarkan kecepatan dan mempunyai cap.
- Out-of-bounds mengembalikan player ke spawn Layer 0 dengan health tepat 1.
- `small_enemy` adalah tag eksplisit untuk semua enemy kecuali `big_roamer` dan `boss`.
- Attack direction/hitbox dikunci saat action dimulai. Satu active hitbox menyimpan receiver yang sudah diproses agar overlap beberapa physics frame tidak menggandakan hit.

Shared contract:

```gdscript
apply_damage(damage_info) -> bool
heal(amount, multiplier, health_cap) -> float
apply_force(force: Vector2) -> void
apply_status(effect_id, data) -> bool
```

Death signal hanya dipancarkan sekali. Semua healing melewati satu API agar curse modifier/cap selalu berlaku.

### Movement player

- Full jump unencumbered mempertahankan kira-kira kemampuan sekarang: rise sekitar 44 px dan horizontal travel sekitar 75 px. Semua angka movement tetap exported agar map dapat di-playtest tanpa edit code.
- Melepas jump saat naik memotong upward velocity sehingga tap jump mencapai sekitar 40–50% full height.
- Coyote time dan jump buffer default masing-masing 0,12 detik dan diexport. Buffer tidak membuat double jump.
- Air steering memakai normal target speed dengan air acceleration/deceleration terpisah dan lebih rendah; player boleh membalik arah di udara.
- Animation airborne memilih `jump`/`fall` dari velocity vertical, bukan arah horizontal.

### Sound

- Sound menggunakan radius lurus dan menembus terrain; tidak ada pathfinding/occlusion pada jam build.
- Listener memilih priority tertinggi, lalu event terbaru, lalu jarak terdekat.
- Emitter tidak mengenal listener tertentu.
- Setelah kehilangan target, enemy menuju last-known position, menunggu sesuai definition, lalu kembali ke state normal.
- Radius menentukan apakah event terdengar; priority memilih event yang sudah terdengar. Priority tidak mempunyai global maximum. Listener memakai minimum accepted priority dan tidak menolak suara karena terlalu tinggi.
- Default action priority: walking `1`, jump takeoff `3`, throw `1`, whistle `10`; radius dan item-use sound ditentukan terpisah lewat data.
- Walking event dipancarkan per jarak grounded yang ditempuh, bukan setiap frame. Jump memancarkan event saat takeoff; landing boleh memancarkan event terpisah berdasarkan impact dengan clamp.
- Tiga accepted event dari producer yang sama dalam dua detik default-nya mengubah mode dari investigate menjadi direct sound target. Count/window diexport per enemy.
- Direct sound target memperbarui last-known position hanya saat event baru terdengar; tidak mengikuti producer menembus dinding. Silence/out-of-range timeout dan wait/search duration diexport.
- Sound tetap event-driven dan langsung dikirim. Tidak ada polling sound.

### Sight dan target override

- Producer hanya menghasilkan signal/detectability; listener enemy memfilter sight/sound; script AI enemy tetap memilih investigate/chase/return. Jangan memindahkan seluruh state machine ke component umum.
- Sight memakai cone/area arah hadap sebagai broad phase lalu physics ray query terhadap terrain untuk obstruction. Normal/aggravated angle dan range diexport.
- Aggravated profile memakai cone lebih besar ditambah proximity radius 360°. Proximity tetap membutuhkan jalur tanpa terrain solid.
- Sight/proximity scan default sekitar 0,1 detik dan distagger antar-enemy. Detection tidak berjalan ketika processing enemy/section tidak aktif.
- Setelah line of sight putus, enemy mengejar last-known position dan mencari sampai memory timeout default 10 detik; posisi target tidak diperbarui menembus obstruction.
- Hushcap Area2D memblokir sight query dan memberi overlay semi-transparan kepada player; tidak mempunyai collision fisik.
- Item anti-detection pada scope sekarang tidak menonaktifkan producer. Smoke/deployable sight blocker membuat obstruction; distraction item menghasilkan sound event dengan priority lebih tinggi.
- Direct sight/proximity menang atas sound secara default. Setiap enemy boleh mengaktifkan override agar high-priority sound dapat memutus chase yang masih mempunyai sight.
- Enemy dapat mengatur minimum distraction priority dan ignored sound types. Direct sound target adalah mode, bukan magic maximum priority.
- Target override menyimpan target/last-known position, source, mode, priority, dan timeout yang relevan.

## 8. World dan persistence

- World memakai authored sections; generator hanya memilih variasi dan placer secara deterministik.
- Layer 0 adalah satu authored hub. Layer 1 dan Layer 2 masing-masing mempunyai enam slot: west/east × tiga depth.
- Setiap route section berukuran 1280×800 px, origin kiri atas, dengan entry/exit seam universal di `x = 640`.
- West berada pada `x = 0`, east pada `x = 1280`; depth berada pada `y = 0`, `800`, dan `1600` di assembly layer.
- Generator memilih seluruh 12 variation dan semua hasil placer saat New Run, tetapi hanya menginstansiasi layer aktif.
- Setiap section mempunyai slot ID, variation ID, selection weight, entry/exit/respawn anchors, seam clearance, camera bounds, placer root, dan special tags.
- Moving/dropped item, enemy, serta Rope berada pada runtime root milik layer agar dapat melewati seam. Loot authored memakai `WorldItem`; item yang dijatuhkan player memakai physics `ThrownItem` dengan velocity awal nol.
- Setiap placer mempunyai stable ID, weighted content entries, chance, quantity, dan authored spawn points.
- Seed + stable ID menentukan setiap hasil tanpa RNG global berurutan. Hasil dipersist agar Continue tidak reroll.
- Terrain utama memakai `TileMapLayer` dan tidak destructible. Breakable/hazard/platform khusus adalah scene object.
- Base section hanya berisi `TileMapLayer` kosong dan contract marker. Level designer melukis terrain/collision unik pada setiap variation memakai grid 16 px.
- Entry/exit mempunyai safe zone 96 px. `RespawnAnchor` berada di `(640, 64)` dan digunakan untuk recovery current section dengan 1 HP.
- Semua enam terrain section pada layer aktif tetap terinstansiasi. Hanya section player, tetangga vertikal, dan pasangan crossing yang memproses enemy.
- Enemy mati tidak respawn selama living run.
- Plant, breakable rock, resin tree, dan harvested creature tidak respawn selama living run.
- Tidak ada checkpoint gameplay. Continue memulihkan posisi player sebelumnya.
- `last_safe_position` hanya fallback jika posisi load invalid/out-of-bounds; perpindahan slot mengaturnya ke `RespawnAnchor` section aktif.
- Pause menghentikan SceneTree. Inventory tidak mengubah global time scale.

### Rope: final contract dan prototype pertama

Final Rope tetap harus persistent selama living run, berada pada layer runtime root, dan aman melewati seam. Implementasi player pertama sengaja hanya prototype item-flow dan **belum** memenuhi final persistence contract.

Prototype pertama mencakup:

- Rope dipilih sebagai item; primary menampilkan preview dan memasang langsung pada anchor valid maksimal 72 px dari player.
- Invalid/out-of-range placement memberi feedback dan tidak mengonsumsi item. Placement valid mengonsumsi tepat satu Rope.
- Anchor boleh pada top surface, ceiling, atau side wall yang tidak membuat Rope berada di dalam terrain. Semua anchor menjadi titik atas; Rope selalu menggantung vertical ke bawah.
- Panjang maksimal 160 px dan berhenti sebelum solid terrain pertama. Seluruh segment harus berada dalam active layer bounds.
- Rope adalah `Area2D` vertical tetap, bukan physics rope. Player menyentuh area lalu menekan up/down untuk attach; gravity berhenti dan posisi horizontal ease ke tengah Rope.
- Up/down memanjat. Space detach+jump; left/right saja tidak detach, tetapi menentukan arah saat Space ditekan.
- `E`, primary, dan secondary item tetap dapat dipakai saat climbing walaupun art gabungan belum ada.
- Damage tanpa force tidak detach. Force/knockback apa pun detach; death selalu detach.
- Prototype tidak menyimpan placed Rope atau climbing state, tidak menjamin crossing seam, tidak masuk shop, dan tidak dianggap final integration. Save/load, seam persistence, serta restore di posisi sama dikerjakan setelah prototype disetujui.

### Topologi yang dikunci

- Surface hub memberi akses bebas ke east/west Layer 1.
- Semua Layer 1 slot 03 mempunyai crossing east/west dan entrance menuju kedua sisi Layer 2.
- Semua Layer 2 east slot 02 mempunyai optional shop branch dengan visual/terrain guidance.
- Semua Layer 2 slot 03 membentuk gauntlet dan crossing east/west.
- Semua Layer 2 east slot 03 mempunyai tepat satu entrance Layer 3.
- Quest gatekeeper di shop bersifat optional. Reward powerful relic membantu melewati gauntlet, tetapi bukan hard key.
- Entrance Layer 3 selalu dapat diinteraksi jika player berhasil mencapainya; interaction tersebut mengakhiri build tanpa requirement tambahan.
- Tidak ada playable Layer 3.

### Loading dan debug world

- Generation dipecah menjadi stage dan yield antar-frame. Player belum dibuat sampai validation, assembly, placer spawn, dan restore selesai.
- Loading screen menunjukkan stage dan progress nyata; tidak ada artificial minimum delay.
- Debug Run di main menu membuka custom seed dan World Gen Log. Seed selalu terlihat pada pause menu.
- Debug-only World Gen Log menyimpan duration tiap stage, selection, placer result, warning, fallback, dan error.
- World Gen Log berupa panel scrollable dengan tombol Close; Esc menutup log sebelum menutup pause.
- F3 selalu tersedia tetapi tersembunyi secara default. Panel menampilkan layer/route/slot, unlimited health, bounds/seam draw, teleport, manifest dump, dan validator. Posisi semantic serta koordinat player selalu terlihat di kanan atas.

### Save boundary

Meta save menyimpan version, known item IDs, dan setting lintas run. Living-run save menyimpan:

- seed dan section/placer results
- posisi/health/status player
- inventory/hotbar/item instance state
- semua dropped/thrown item yang berasal dari player
- uang, delivery, whistle tier, dan free-Multitool-replacement flag
- shop stock, gate state, rope, source/enemy state, dan dialogue trigger

Projectile, cloud, active attack frame, dan stun singkat tidak disimpan. Autosave tidak mengambil snapshot item persisten saat masih terbang: item dikembalikan ke last safe owner/state untuk save, sedangkan projectile sementara diabaikan. Implementasi wajib mencegah item ada sekaligus di inventory dan dunia.

## 9. Aturan item yang dikunci

### Rattlepod

- Satu unit hanya dapat digunakan sekali.
- Primary action mengaktifkan Rattlepod selama 5 detik.
- Audio clattering bermain terus selama aktif.
- Setiap satu detik (lima kali total), Rattlepod mengirim sound/targeting event.
- Aktivasi memisahkan satu unit dari stack menjadi active instance. Pulse berasal dari posisi holder selama dibawa dan dari posisi pod setelah dilempar.
- Rattlepod aktif tetap dapat dilempar; ini adalah penggunaan utama. Mengganti hotbar tidak menghentikan timer.
- Jika tidak dilempar, ia tetap berbunyi pada player lalu menghilang saat timer selesai.
- Jika dilempar sebelum aktivasi, ia hanya menjadi object fisik seperti small rock, tidak membuat sound targeting effect, dan menjadi pickup kembali setelah berhenti.
- Pod yang sudah diaktifkan menghilang setelah efek selesai, baik masih dibawa maupun sudah dilempar.
- Rattlepod tidak memberi damage khusus; impact fisik kecil tetap memakai pipeline biasa.
- Radius dan priority diexport untuk playtest.

### Lantern Snail

- World snail pertama mempunyai 2 HP.
- Primary Multitool hit mengurangi 1 HP dan mengubah first-time snail menjadi inventory item.
- Health world awal tidak perlu disimpan sebagai angka pada item; inventory state menandai bahwa snail pernah di-harvest.
- Deploy/use berikutnya membuat world snail dengan 1 HP.
- Multitool hit berikutnya membunuh snail; snail tidak dapat di-harvest kedua kali.
- Inventory/world conversion bukan death drop.
- Agitation dan scream cooldown disimpan; AI transient state di-reset.

### Item lain

- Throwable Rock menjadi pickup setelah velocity rendah selama durasi pendek; keluar bounds menghilangkannya. Tidak ada durability prototype.
- Numbing Pill kedua menambah 5 menit, bukan refresh.
- Silver Weight memakai durability-based sale value dan dapat multi-hit.
- Bandage healing tidak dibatalkan damage.
- Driftseed valid untuk player dan boss gatekeeper; target lain tidak valid sampai desain berubah.
- Supply secondary action belum dikunci dan harus bisa diganti melalui ItemDefinition tanpa mengubah Player/Inventory.

## 10. Economy dan progression

- Shop transaction harus atomic: validasi uang, slot, stock, dan item; baru commit semuanya.
- Shop dapat menampilkan backpack dan hotbar, tetapi menjual active item memerlukan konfirmasi.
- `sellable` adalah field ItemDefinition. Multitool/whistle false; supply/rock false pada build jam; relic mengikuti nilai.
- Delivery menghitung setiap unit dikali `delivery_value` milik ItemDefinition. Tidak semua relic wajib bernilai satu.
- Blue Whistle tier disimpan terpisah dari item fisik. Replacement memberi tier tertinggi yang sudah diperoleh.
- Surface menggunakan nilai jual penuh. Layer 2 shop menggunakan rounded 75% dan tidak menambah delivery surface.

### Layer 2 shop gatekeeper

Flow ending game-jam yang dikunci:

- Gatekeeper berada di Layer 2 shop.
- Ia meminta satu relic quest khusus yang belum didesain.
- Setelah relic dikembalikan, gatekeeper memberikan **dua reward terpisah**: Moon Whistle dan satu powerful relic biasa.
- Moon Whistle adalah progression credential/ending reward; powerful relic adalah inventory item dengan behavior sendiri. Keduanya tidak boleh memakai item ID, slot, atau state yang sama.
- Gatekeeper tidak membuka hard gate. Quest dan kedua reward bersifat optional tetapi memberi jalur paling aman melalui gauntlet.
- Powerful relic ditujukan untuk membantu melewati kumpulan big dan small enemy yang menjaga gate Layer 3.
- Encounter tersebut adalah gauntlet beberapa enemy, bukan traditional single boss pada desain saat ini.
- Desain boleh berubah menjadi big-monster boss kemudian; jangan membangun boss framework sebelum keputusan itu dibuat.
- Build berakhir ketika player menginteraksi dengan entrance Layer 3. Interaction tidak memeriksa reward atau whistle; Layer 3 tidak mempunyai playable section pada jam build.
- Moon Whistle diberikan sebelum gauntlet; mencapai entrance memicu ending screen, bukan pemberian Moon Whistle kedua.

Istilah “boss” pada pembicaraan desain saat ini merujuk kepada gatekeeper/quest authority. Ia belum membutuhkan combat-boss framework.

## 11. UI, art, dan feedback

- Inventory memakai click-to-swap: klik kiri pilih/swap, klik kanan context action, Esc/Tab atau klik ulang membatalkan.
- Dotted parabolic line sepanjang default 48 px menunjukkan arah dan kekuatan throw; visual guide tidak melakukan collision prediction.
- HUD minimum: health, money, dua hotbar, whistle, status, prompt, delivery, dan autosave feedback.
- Dialogue memakai control-lock token dan selalu melepasnya saat selesai, skip, scene change, atau error.
- Player art memakai 32×32 px. Item art 16×16 diperbolehkan pada scene yang sama. Icon inventory dapat memakai source yang sama sementara.
- Resize melalui `Sprite2D.scale` diperbolehkan. Utamakan integer scale seperti `2×`; non-integer scale boleh untuk placeholder tetapi dapat membuat pixel tidak rata.
- Actor/world item memakai pivot bottom-centre. Collision dimiliki programmer, bukan mengikuti ukuran sprite otomatis.
- Animation names: `idle`, `move`, `telegraph`, `attack`, `hit`, `death` sesuai kebutuhan.
- Audio/VFX diberikan melalui exported Resource atau signal; jangan hardcode path tersebar.
- Asset item runtime berada di `assets/art/items/`; asset UI di `assets/art/ui/`; source `.aseprite` disimpan terpisah di `assets/source/`. Nama memakai `snake_case`.
- Asset Rope 16×16 tidak di-resample: `rope_item` adalah coil inventory/world, `rope_segment` diulang/dipotong untuk body, dan `rope_end` menjadi bottom cap. Gunakan nearest filtering dan native scale sebelum playtest membuktikan perlu integer scale lain.

## 12. Content yang masih boleh TBD

- Identitas dan behavior relic quest yang diminta gatekeeper.
- Identitas dan behavior powerful relic reward.
- Komposisi serta balance enemy gauntlet di gate Layer 3.
- Apakah gauntlet kemudian mempunyai satu big-monster boss.

Semua poin di atas adalah content data/behavior. Mereka tidak mengubah flow reward atau batas playable build yang sudah dikunci.

## 13. Definition of done fondasi

- Project import/headless run tanpa parser error.
- Catalog menolak ID kosong/duplikat.
- Inventory lulus stack, overflow, swap, primary, secondary, failed-action rollback, throw, drop, pickup, theft, dan living-item conversion.
- ThrownItem dan Projectile tidak berbagi ownership state dan tidak menduplikasi item.
- Same-species damage filter, damage/force/status pipeline, i-frame, serta death signal bekerja.
- Sound event mengubah listener tanpa emitter mengenal enemy type.
- Seed sama menghasilkan section/placer sama.
- Save roundtrip mempertahankan semua item yang berasal dari player dan fallback invalid position bekerja.
- Pause/dialogue/inventory tidak meninggalkan control lock.
- Shop transaction atomic dan delivery memakai per-item value.
- Gatekeeper reward memberikan Moon Whistle dan powerful relic tepat satu kali; Continue tidak menggandakan reward.
- Entrance Layer 3 memicu ending tanpa membuat playable Layer 3 atau memberikan Moon Whistle kedua.
- Rattlepod dapat diaktifkan, mengirim lima event, dan dilempar saat aktif; lemparan tidak aktif tidak memicu sound effect.
- Snail hanya dapat di-harvest sekali sepanjang instance lifecycle.
- Tap/full jump, coyote time, jump buffer, dan air steering tidak membuat double jump serta tetap melewati graybox unencumbered.
- Multitool hanya mengenai satu priority target saat shape visual aktif; tidak ada hit dari cursor atau selama recovery.
- Interaction cursor memilih priority target di titik clamp, menolak obstruction, dan camera tetap mengikuti bounds saat UI zoom aktif.
- Rock dan debug heavy item mempunyai trajectory berbeda sesuai weight; preview tersedia tanpa hold input.
- Sight berhenti pada obstruction, sound priority/tie/escalation benar, dan unloaded enemy tidak melakukan scan.
- Rope prototype dapat preview, consume satu item, attach/climb/jump-away, memakai item saat climb, dan detach oleh knockback. Persistence/seam bukan acceptance prototype.

Gunakan satu assertion-based smoke test bawaan project. Jangan menambah framework sebelum jumlah test membuktikan kebutuhan.
